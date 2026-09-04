#include <stdio.h>
#include <stdint.h>

#define POLLING_INTERVAL_MS 5U

static uint32_t polling_response(uint32_t event_time_ms)
{
    uint32_t remainder = event_time_ms % POLLING_INTERVAL_MS;
    return (remainder == 0U) ? 0U : (POLLING_INTERVAL_MS - remainder);
}

static uint32_t interrupt_response(void)
{
    /* Model: event is serviced immediately after interrupt entry. */
    return 0U;
}

static void compare_timing(const uint32_t events[], uint8_t count)
{
    uint32_t poll_total = 0U, int_total = 0U;

    printf("Event(ms) | Polling response(ms) | Interrupt response(ms)\n");
    for (uint8_t i=0U; i<count; ++i) {
        uint32_t p = polling_response(events[i]);
        uint32_t in = interrupt_response();
        poll_total += p; int_total += in;
        printf("%8u | %21u | %22u\n",
               (unsigned)events[i], (unsigned)p, (unsigned)in);
    }

    printf("\nAverage polling response  : %.2f ms\n", (double)poll_total/count);
    printf("Average interrupt response: %.2f ms\n", (double)int_total/count);
}

int main(void)
{
    const uint32_t events[] = {3U,7U,12U,18U,24U,27U};
    printf("Polling vs Interrupt-Based Timing\n");
    printf("Polling interval: %u ms\n\n", POLLING_INTERVAL_MS);
    compare_timing(events, (uint8_t)(sizeof(events)/sizeof(events[0])));
    printf("\nPolling repeatedly checks the condition; interrupts allow the CPU\n");
    printf("to perform other work until the hardware event occurs.\n");
    return 0;
}
