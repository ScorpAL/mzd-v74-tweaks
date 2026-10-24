#define _POSIX_C_SOURCE 200809L
#include "protocol.h"
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <fcntl.h>

/* Optional browser transport; all execution remains in the existing service. */
static volatile sig_atomic_t stopping;
static void stop(int n) { (void)n; stopping = 1; }
static void respond(FILE *out, int code, const char *mime, const char *body) {
    fprintf(out, "HTTP/1.1 %d Result\r\nContent-Type: %s\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n%s", code, mime, body);
}
static void json_string(FILE *out, const char *s, size_t n) {
    fputc('"', out);
    for (size_t i = 0; i < n; ++i) {
        unsigned char c = (unsigned char)s[i];
        if (c == '"' || c == '\\') { fputc('\\', out); fputc(c, out); }
        else if (c < 32 || c >= 127) fprintf(out, "\\u%04x", c);
        else fputc(c, out);
    }
    fputc('"', out);
}
static int hex(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    return -1;
}
static int decode(char *s) {
    char *p = s, *out = s;
    while (*p) {
        if (*p == '%') {
            if (!p[1] || !p[2] || hex(p[1]) < 0 || hex(p[2]) < 0) return -1;
            int c = hex(p[1]) * 16 + hex(p[2]);
            if (!c) return -1;
            *out++ = (char)c; p += 3;
        } else { *out++ = *p == '+' ? ' ' : *p; ++p; }
    }
    *out = 0;
    return 0;
}
static void exec_request(FILE *out, const char *socket_path, char *body) {
    char *args[MAX_ARGS + 1] = {0}, *save = NULL;
    uint32_t count = 0;
    for (char *p = strtok_r(body, "&", &save); p; p = strtok_r(NULL, "&", &save)) {
        if (count >= MAX_ARGS || strncmp(p, count ? "arg=" : "program=", count ? 4 : 8)) {
            respond(out, 400, "application/json", "{\"error\":\"Invalid arguments\"}"); return;
        }
        args[count] = p + (count ? 4 : 8);
        if (decode(args[count]) || strlen(args[count]) > MAX_ARG_BYTES) {
            respond(out, 400, "application/json", "{\"error\":\"Invalid encoding\"}"); return;
        }
        ++count;
    }
    if (!count || args[0][0] != '/') { respond(out, 400, "application/json", "{\"error\":\"Absolute program required\"}"); return; }
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof addr); addr.sun_family = AF_UNIX;
    if (strlen(socket_path) >= sizeof addr.sun_path) return;
    strcpy(addr.sun_path, socket_path);
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return;
    if (connect(fd, (struct sockaddr *)&addr, sizeof addr)) {
        close(fd); respond(out, 503, "application/json", "{\"error\":\"Bridge unavailable\"}"); return;
    }
    struct request_header req = { MAGIC, count };
    int bad = write_all(fd, &req, sizeof req);
    for (uint32_t i = 0; !bad && i < count; ++i) {
        uint32_t size = (uint32_t)strlen(args[i]);
        bad = write_all(fd, &size, sizeof size) || write_all(fd, args[i], size);
    }
    struct result_header r;
    if (bad || read_all(fd, &r, sizeof r) || r.magic != MAGIC || r.stdout_length > MAX_CAPTURE || r.stderr_length > MAX_CAPTURE) {
        close(fd); respond(out, 502, "application/json", "{\"error\":\"Unknown process outcome\"}"); return;
    }
    char *a = malloc((size_t)r.stdout_length + 1), *b = malloc((size_t)r.stderr_length + 1);
    if (!a || !b) { free(a); free(b); close(fd); return; }
    bad = read_all(fd, a, r.stdout_length) || read_all(fd, b, r.stderr_length);
    close(fd);
    if (bad) respond(out, 502, "application/json", "{\"error\":\"Incomplete result\"}");
    else {
        fprintf(out, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n{\"started\":%s,\"exitCode\":", r.start_errno ? "false" : "true");
        if (r.exit_code < 0) fputs("null", out); else fprintf(out, "%d", r.exit_code);
        fputs(",\"signal\":", out);
        if (r.signal_number) fprintf(out, "%d", r.signal_number); else fputs("null", out);
        fputs(",\"stdout\":", out); json_string(out, a, r.stdout_length);
        fputs(",\"stderr\":", out); json_string(out, b, r.stderr_length);
        fputs(",\"startError\":", out); json_string(out, r.start_errno ? strerror(r.start_errno) : "", r.start_errno ? strlen(strerror(r.start_errno)) : 0);
        fprintf(out, ",\"stdoutTruncated\":%s,\"stderrTruncated\":%s}", r.stdout_truncated ? "true" : "false", r.stderr_truncated ? "true" : "false");
    }
    free(a); free(b);
}
int main(int argc, char **argv) {
    if (argc != 4) { fprintf(stderr, "Usage: browser-adapter exec.sock index.html ready-file\n"); return 1; }
    signal(SIGPIPE, SIG_IGN);
    struct sigaction sa; memset(&sa, 0, sizeof sa); sa.sa_handler = stop;
    sigaction(SIGTERM, &sa, NULL); sigaction(SIGINT, &sa, NULL);
    unsigned char random[24]; char token[49];
    int rng = open("/dev/urandom", O_RDONLY);
    if (rng < 0 || read_all(rng, random, sizeof random)) return 1;
    close(rng);
    for (size_t i = 0; i < sizeof random; ++i) sprintf(token + i * 2, "%02x", random[i]);
    struct sockaddr_in addr; memset(&addr, 0, sizeof addr);
    addr.sin_family = AF_INET; addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    int server = socket(AF_INET, SOCK_STREAM, 0);
    if (server < 0 || bind(server, (struct sockaddr *)&addr, sizeof addr) || listen(server, 4)) { perror("HTTP socket"); return 1; }
    (void)fcntl(server, F_SETFD, FD_CLOEXEC);
    socklen_t size = sizeof addr;
    if (getsockname(server, (struct sockaddr *)&addr, &size)) return 1;
    char origin[80], host[80];
    snprintf(host, sizeof host, "127.0.0.1:%u", ntohs(addr.sin_port));
    snprintf(origin, sizeof origin, "http://127.0.0.1:%u", ntohs(addr.sin_port));
    FILE *ready = fopen(argv[3], "w");
    if (!ready) return 1;
    fprintf(ready, "%u\n%s\n", ntohs(addr.sin_port), token); fclose(ready);
    while (!stopping) {
        int client = accept(server, NULL, NULL);
        if (client < 0) { if (errno == EINTR) continue; break; }
        struct timeval timeout = {10, 0};
        setsockopt(client, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof timeout);
        FILE *in = fdopen(dup(client), "r"), *out = fdopen(client, "w");
        if (!in || !out) { if (in) fclose(in); if (out) fclose(out); else close(client); continue; }
        char line[2048], method[12] = "", path[120] = "";
        size_t length = 0, headers = 0; int auth = 0, valid_host = 0, valid_origin = 1, ended = 0;
        if (!fgets(line, sizeof line, in) || sscanf(line, "%11s %119s", method, path) != 2) goto done;
        /* Diagnostics without logging the session token or request arguments. */
        fprintf(stderr, "request %s %s\n", method, path); fflush(stderr);
        while (fgets(line, sizeof line, in)) {
            headers += strlen(line); if (headers > 16384) break;
            if (!strcmp(line, "\r\n")) { ended = 1; break; }
            line[strcspn(line, "\r\n")] = 0;
            if (!strncasecmp(line, "Content-Length: ", 16)) length = (size_t)strtoul(line + 16, NULL, 10);
            if (!strncasecmp(line, "X-Poc-Token: ", 13)) auth = !strcmp(line + 13, token);
            if (!strncasecmp(line, "Host: ", 6)) valid_host = !strcmp(line + 6, host);
            if (!strncasecmp(line, "Origin: ", 8)) valid_origin = !strcmp(line + 8, origin);
        }
        if (!ended || !valid_host || !valid_origin) { respond(out, 403, "text/plain", "Forbidden"); goto done; }
        if (!strcmp(method, "GET") && !strcmp(path, "/")) {
            FILE *page = fopen(argv[2], "rb");
            if (!page) { respond(out, 500, "text/plain", "Missing page"); goto done; }
            fputs("HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n", out);
            char data[4096]; size_t n;
            while ((n = fread(data, 1, sizeof data, page))) fwrite(data, 1, n, out);
            fclose(page);
            fprintf(stderr, "page served\n"); fflush(stderr);
        } else if (!strcmp(method, "POST") && auth && length <= 32768) {
            char *body = calloc(length + 1, 1);
            if (!body || fread(body, 1, length, in) != length) { free(body); goto done; }
            if (!strcmp(path, "/exec")) exec_request(out, argv[1], body);
            else if (!strcmp(path, "/exit")) { respond(out, 200, "application/json", "{\"ok\":true}"); stopping = 1; }
            else respond(out, 404, "text/plain", "Not found");
            free(body);
        } else respond(out, 403, "text/plain", "Forbidden");
done:
        fclose(in); fclose(out);
    }
    close(server); unlink(argv[3]); return 0;
}
