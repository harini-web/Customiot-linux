#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

static volatile sig_atomic_t running = 1;
static volatile sig_atomic_t child_pid = -1;

static void handle_signal(int sig)
{
    (void)sig;
    running = 0;

    if (child_pid > 0)
        kill(-(pid_t)child_pid, SIGTERM);
}

static void wait_for_child(pid_t pid)
{
    int status;

    while (waitpid(pid, &status, 0) == -1) {
        if (errno != EINTR)
            break;
    }
}

int main(void)
{
    struct sigaction sa = {0};

    sa.sa_handler = handle_signal;
    sigemptyset(&sa.sa_mask);

    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);

    printf("CustomIoT gateway supervisor started\n");
    fflush(stdout);

    while (running) {
        pid_t pid = fork();

        if (pid < 0) {
            perror("fork");
            break;
        }

        if (pid == 0) {
            setpgid(0, 0);

            execl(
                "/bin/sh",
                "sh",
                "/usr/local/bin/telemetry-publish.sh",
                (char *)NULL
            );

            perror("execl");
            _exit(127);
        }

        child_pid = pid;

        /* Put the child into its own process group. */
        if (setpgid(pid, pid) == -1 &&
            errno != EACCES &&
            errno != ESRCH) {
            perror("setpgid");
        }

        if (!running)
            kill(-pid, SIGTERM);

        wait_for_child(pid);
        child_pid = -1;

        if (!running)
            break;

        fprintf(
            stderr,
            "Gateway pipeline exited; restarting\n"
        );

        sleep(3);
    }

    printf("CustomIoT gateway supervisor stopped\n");

    return 0;
}
