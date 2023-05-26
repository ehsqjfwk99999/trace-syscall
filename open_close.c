#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define SYSTEM_CALL(sysFuncCall)                                               \
  ({                                                                           \
    int _fd;                                                                   \
    do {                                                                       \
      _fd = sysFuncCall;                                                       \
      if (_fd == -1) {                                                         \
        fprintf(stderr, "%s:%d: error: %s.\n", __FILE__, __LINE__,             \
                strerror(errno));                                              \
      }                                                                        \
    } while (0);                                                               \
    _fd;                                                                       \
  })

#define MARK(__msg) write(marker_fd, __msg, strlen(__msg))

int main() {
  int file_fd;
  int marker_fd;

  marker_fd =
      SYSTEM_CALL(open("/sys/kernel/debug/tracing/trace_marker", O_RDWR));
  if (marker_fd == -1)
    goto marker_err;

  MARK("##### [+++] open\n");
  file_fd = SYSTEM_CALL(open("test.txt", O_RDONLY));
  if (file_fd == -1)
    goto open_err;
  MARK("##### [---] open\n");

  MARK("##### [+++] close\n");
  close(file_fd);
  MARK("##### [---] close\n");

open_err:
  close(marker_fd);
marker_err:

  return 0;
}
