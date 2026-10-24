#define _POSIX_C_SOURCE 200809L
#include "protocol.h"
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <poll.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static volatile sig_atomic_t stopping;
static void stop(int sig) { (void)sig; stopping = 1; }
static int make_pipe(int p[2]) {
    if (pipe(p)) return -1;
    if (fcntl(p[0], F_SETFD, FD_CLOEXEC) < 0 || fcntl(p[1], F_SETFD, FD_CLOEXEC) < 0) {
        close(p[0]); close(p[1]); return -1;
    }
    return 0;
}
static void execute(int client, int server, char **argv) {
    int out[2], err[2], started[2];
    struct result_header r = { .magic = MAGIC, .exit_code = -1 };
    char *stdout_data = malloc(MAX_CAPTURE), *stderr_data = malloc(MAX_CAPTURE);
    if (!stdout_data || !stderr_data) goto memory;
    if (make_pipe(out)) goto memory;
    if (make_pipe(err)) { close(out[0]); close(out[1]); goto memory; }
    if (make_pipe(started)) { close(out[0]); close(out[1]); close(err[0]); close(err[1]); goto memory; }
    pid_t pid = fork();
    if (pid < 0) {
        r.start_errno = errno;
        close(out[0]); close(out[1]); close(err[0]); close(err[1]); close(started[0]); close(started[1]);
        (void)write_all(client, &r, sizeof r);
        goto memory;
    }
    if (pid == 0) {
        int failure;
        close(server); close(client);
        close(out[0]); close(err[0]); close(started[0]);
        int input = open("/dev/null", O_RDONLY);
        if (input < 0 || dup2(input, STDIN_FILENO) < 0 ||
            dup2(out[1], STDOUT_FILENO) < 0 || dup2(err[1], STDERR_FILENO) < 0) {
            failure = errno; (void)write_all(started[1], &failure, sizeof failure); _exit(127);
        }
        close(input); close(out[1]); close(err[1]);
        execv(argv[0], argv);
        failure = errno;
        (void)write_all(started[1], &failure, sizeof failure);
        _exit(127);
    }
    close(out[1]); close(err[1]); close(started[1]);
    int failure = 0;
    ssize_t got;
    do { got = read(started[0], &failure, sizeof failure); } while (got < 0 && errno == EINTR);
    close(started[0]);
    if (got == sizeof failure) r.start_errno = failure;
    /* Drain both streams concurrently, including data beyond the buffer limit. */
    struct pollfd pipes[2] = { {out[0], POLLIN, 0}, {err[0], POLLIN, 0} };
    int opened = 2, status = 0;
    while (opened) {
        int ready = poll(pipes, 2, -1);
        if (ready < 0 && errno == EINTR) continue;
        if (ready < 0) break;
        for (int i = 0; i < 2; ++i) {
            if (pipes[i].fd < 0 || !pipes[i].revents) continue;
            char data[4096];
            ssize_t n = read(pipes[i].fd, data, sizeof data);
            if (n < 0 && errno == EINTR) continue;
            if (n <= 0) { close(pipes[i].fd); pipes[i].fd = -1; --opened; continue; }
            uint32_t *length = i ? &r.stderr_length : &r.stdout_length;
            char *target = i ? stderr_data : stdout_data;
            size_t remaining = MAX_CAPTURE - *length;
            size_t keep = (size_t)n < remaining ? (size_t)n : remaining;
            memcpy(target + *length, data, keep); *length += (uint32_t)keep;
            if (keep < (size_t)n) { if (i) r.stderr_truncated = 1; else r.stdout_truncated = 1; }
        }
    }
    for (int i = 0; i < 2; ++i) if (pipes[i].fd >= 0) close(pipes[i].fd);
    pid_t waited;
    do { waited = waitpid(pid, &status, 0); } while (waited < 0 && errno == EINTR);
    if (waited < 0) r.start_errno = errno;
    else if (WIFEXITED(status)) r.exit_code = WEXITSTATUS(status);
    else if (WIFSIGNALED(status)) r.signal_number = WTERMSIG(status);
    fprintf(stderr, "process completed: exit=%d signal=%d start_errno=%d\n",
            r.exit_code, r.signal_number, r.start_errno);
    if (!write_all(client, &r, sizeof r) && !write_all(client, stdout_data, r.stdout_length))
        (void)write_all(client, stderr_data, r.stderr_length);
memory:
    free(stdout_data); free(stderr_data);
}
static void handle(int client, int server) {
    struct request_header h;
    char *argv[MAX_ARGS + 1] = {0};
    size_t total = 0;
    struct timeval timeout = {10, 0};
    (void)setsockopt(client, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof timeout);
    if (read_all(client, &h, sizeof h) || h.magic != MAGIC || h.argc < 1 || h.argc > MAX_ARGS) return;
    for (uint32_t i = 0; i < h.argc; ++i) {
        uint32_t size;
        if (read_all(client, &size, sizeof size) || size > MAX_ARG_BYTES ||
            total + size > MAX_ARG_BYTES * 4u) goto done;
        total += size;
        argv[i] = calloc((size_t)size + 1, 1);
        if (!argv[i] || read_all(client, argv[i], size) || memchr(argv[i], 0, size)) goto done;
    }
    if (argv[0][0] != '/') goto done;
    execute(client, server, argv);
done:
    for (uint32_t i = 0; i < MAX_ARGS; ++i) free(argv[i]);
}
int main(int argc, char **argv) {
    if (argc != 2) { fprintf(stderr, "Usage: shell-bridge /private/path/exec.sock\n"); return 1; }
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof addr); addr.sun_family = AF_UNIX;
    if (strlen(argv[1]) >= sizeof addr.sun_path) { fprintf(stderr, "Socket path too long\n"); return 1; }
    strcpy(addr.sun_path, argv[1]);
    umask(077);
    struct sigaction action;
    memset(&action, 0, sizeof action); action.sa_handler = stop;
    sigaction(SIGTERM, &action, NULL); sigaction(SIGINT, &action, NULL);
    signal(SIGPIPE, SIG_IGN);
    int server = socket(AF_UNIX, SOCK_STREAM, 0);
    if (server < 0 || fcntl(server, F_SETFD, FD_CLOEXEC) < 0 ||
        bind(server, (struct sockaddr *)&addr, sizeof addr) < 0 || listen(server, 4) < 0) {
        perror("bridge socket"); if (server >= 0) close(server); return 1;
    }
    fprintf(stderr, "shell-bridge ready (Unix socket, no network listener)\n");
    while (!stopping) {
        int client = accept(server, NULL, NULL);
        if (client < 0) { if (errno == EINTR) continue; perror("accept"); break; }
        (void)fcntl(client, F_SETFD, FD_CLOEXEC);
        handle(client, server);
        close(client);
    }
    close(server); unlink(argv[1]);
    return 0;
}
