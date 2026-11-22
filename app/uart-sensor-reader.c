#define _DEFAULT_SOURCE
#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>

#define DEFAULT_UART "/dev/ttyS1"
#define BUFFER_SIZE 128

static volatile sig_atomic_t running = 1;

static void stop_handler(int sig)
{
    (void)sig;
    running = 0;
}

/* Configure UART for 115200, 8N1, raw mode. */
static int configure_uart(int fd)
{
    struct termios tty;

    if (tcgetattr(fd, &tty) != 0) {
        perror("tcgetattr");
        return -1;
    }

    cfmakeraw(&tty);

    cfsetispeed(&tty, B115200);
    cfsetospeed(&tty, B115200);

    tty.c_cflag &= ~PARENB;
    tty.c_cflag &= ~CSTOPB;
    tty.c_cflag &= ~CSIZE;

    tty.c_cflag |= CS8;
    tty.c_cflag |= CLOCAL | CREAD;

#ifdef CRTSCTS
    tty.c_cflag &= ~CRTSCTS;
#endif

    tty.c_cc[VMIN] = 0;
    tty.c_cc[VTIME] = 0;

    if (tcsetattr(fd, TCSANOW, &tty) != 0) {
        perror("tcsetattr");
        return -1;
    }

    return 0;
}

/* Parse a complete TEMP_MC=<integer> message. */
static int parse_temperature(
    const char *message,
    int *temperature)
{
    const char *prefix = "TEMP_MC=";
    const size_t prefix_len = strlen(prefix);

    if (strncmp(message, prefix, prefix_len) != 0)
        return -1;

    const char *value = message + prefix_len;

    errno = 0;

    char *end = NULL;
    long result = strtol(value, &end, 10);

    if (errno != 0 || end == value || *end != '\0')
        return -1;

    /* Plausible temperature range for our simulator:
       -40.000°C to +125.000°C */
    if (result < -40000 || result > 125000)
        return -1;

    *temperature = (int)result;

    return 0;
}

static void publish_json(
    unsigned long sequence,
    int temperature)
{
    time_t now = time(NULL);

    printf(
        "{\"seq\":%lu,"
        "\"timestamp\":%lld,"
        "\"temperature_mC\":%d,"
        "\"sensor\":\"uart\"}\n",
        sequence,
        (long long)now,
        temperature
    );

    fflush(stdout);
}

int main(int argc, char **argv)
{
    const char *device = DEFAULT_UART;

    if (argc > 2) {
        fprintf(
            stderr,
            "Usage: %s [uart-device]\n",
            argv[0]
        );
        return EXIT_FAILURE;
    }

    if (argc == 2)
        device = argv[1];

    struct sigaction sa = {0};

    sa.sa_handler = stop_handler;
    sigemptyset(&sa.sa_mask);

    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);

    int fd = open(
        device,
        O_RDWR | O_NOCTTY | O_NONBLOCK
    );

    if (fd < 0) {
        perror("open UART");
        return EXIT_FAILURE;
    }

    if (configure_uart(fd) != 0) {
        close(fd);
        return EXIT_FAILURE;
    }

    fprintf(
        stderr,
        "CustomIoT UART reader started: %s\n",
        device
    );

    char buffer[BUFFER_SIZE];

    size_t position = 0;
    int discarding = 0;

    unsigned long sequence = 0;

    struct pollfd pfd = {
        .fd = fd,
        .events = POLLIN
    };

    while (running) {
        int result = poll(&pfd, 1, 1000);

        if (result < 0) {
            if (errno == EINTR)
                continue;

            perror("poll");
            break;
        }

        if (result == 0)
            continue;

        if (pfd.revents & (POLLERR | POLLNVAL)) {
            fprintf(stderr, "UART device error\n");
            break;
        }

        if (!(pfd.revents & POLLIN))
            continue;

        char input[64];

        ssize_t count = read(
            fd,
            input,
            sizeof(input)
        );

        if (count < 0) {
            if (errno == EINTR ||
                errno == EAGAIN)
                continue;

            perror("read");
            break;
        }

        if (count == 0)
            continue;

        for (ssize_t i = 0; i < count; i++) {
            char ch = input[i];

            if (ch == '\n') {
                if (!discarding && position > 0) {
                    buffer[position] = '\0';

                    int temperature;

                    if (parse_temperature(
                            buffer,
                            &temperature
                        ) == 0) {

                        publish_json(
                            sequence++,
                            temperature
                        );

                    } else {
                        fprintf(
                            stderr,
                            "Invalid sensor message: %s\n",
                            buffer
                        );
                    }
                }

                position = 0;
                discarding = 0;
                continue;
            }

            if (ch == '\r')
                continue;

            if (discarding)
                continue;

            if (position < sizeof(buffer) - 1) {
                buffer[position++] = ch;
            } else {
                fprintf(
                    stderr,
                    "UART message exceeded buffer\n"
                );

                position = 0;
                discarding = 1;
            }
        }
    }

    close(fd);

    fprintf(stderr, "UART reader stopped\n");

    return EXIT_SUCCESS;
}
