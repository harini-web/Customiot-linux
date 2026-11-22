/* Deterministic virtual sensor; publishes JSON to stdout (one sample/second).
 * An init service pipes this output into mosquitto_pub in Module 05.
 * This is a simulated sensor, not a physical UART driver.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
static volatile sig_atomic_t running = 1;
static void stop(int signum) { (void)signum; running = 0; }
int main(int argc, char **argv) {
    long max_samples = 0;
    if (argc == 2) {
        char *end = NULL;
        max_samples = strtol(argv[1], &end, 10);
        if (!end || *end != '\0' || max_samples < 1) {
            fprintf(stderr, "usage: %s [positive-count]\n", argv[0]); return 2;
        }
    } else if (argc > 2) {
        fprintf(stderr, "usage: %s [positive-count]\n", argv[0]); return 2;
    }
    signal(SIGTERM, stop);
    signal(SIGINT, stop);
    for (long seq = 0; running && (max_samples == 0 || seq < max_samples); ++seq) {
        time_t now = time(NULL);
        int temp_mC = 23500 + (int)(seq % 21) * 125;
        printf("{\"seq\":%ld,\"timestamp\":%lld,\"temperature_mC\":%d,\"sensor\":\"simulated\"}\n",
               seq, (long long)now, temp_mC);
        fflush(stdout);
        if (max_samples == 0 || seq + 1 < max_samples) sleep(1);
    }
    return 0;
}
