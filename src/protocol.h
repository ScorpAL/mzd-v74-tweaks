#ifndef SHELL_PROTOCOL_H
#define SHELL_PROTOCOL_H
#include <stdint.h>
#include <stddef.h>
#include <unistd.h>
#include <errno.h>
#define MAGIC 0x43534d55u
#define MAX_ARGS 64u
#define MAX_ARG_BYTES 8192u
#define MAX_CAPTURE 65536u
/* Private same-host protocol, same ABI/endianness on both processes. */
struct request_header { uint32_t magic, argc; };
struct result_header {
    uint32_t magic;
    int32_t exit_code, signal_number, start_errno;
    uint32_t stdout_length, stderr_length, stdout_truncated, stderr_truncated;
};
static int read_all(int fd, void *buffer, size_t size) {
    char *p = buffer;
    while (size) {
        ssize_t n = read(fd, p, size);
        if (n < 0 && errno == EINTR) continue;
        if (n <= 0) return -1;
        p += n; size -= (size_t)n;
    }
    return 0;
}
static int write_all(int fd, const void *buffer, size_t size) {
    const char *p = buffer;
    while (size) {
        ssize_t n = write(fd, p, size);
        if (n < 0 && errno == EINTR) continue;
        if (n <= 0) return -1;
        p += n; size -= (size_t)n;
    }
    return 0;
}
#endif
