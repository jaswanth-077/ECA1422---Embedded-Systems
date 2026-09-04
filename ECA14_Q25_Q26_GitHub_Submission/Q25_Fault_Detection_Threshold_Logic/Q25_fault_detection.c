#include <stdio.h>
#include <stdint.h>

#define HIGH_LIMIT 80U
#define LOW_LIMIT 10U

typedef enum { FAULT_NONE, FAULT_HIGH_TEMPERATURE, FAULT_LOW_TEMPERATURE } FaultType;

static FaultType check_fault(uint16_t temperature)
{
    if (temperature > HIGH_LIMIT) return FAULT_HIGH_TEMPERATURE;
    if (temperature < LOW_LIMIT) return FAULT_LOW_TEMPERATURE;
    return FAULT_NONE;
}

static const char *fault_text(FaultType fault)
{
    switch (fault) {
        case FAULT_HIGH_TEMPERATURE: return "HIGH TEMPERATURE FAULT";
        case FAULT_LOW_TEMPERATURE:  return "LOW TEMPERATURE FAULT";
        default: return "NORMAL";
    }
}

static void process_samples(const uint16_t samples[], uint8_t count)
{
    for (uint8_t i = 0U; i < count; ++i) {
        FaultType fault = check_fault(samples[i]);
        printf("Sample %u | Temperature: %u C | Status: %s\n",
               (unsigned)(i + 1U), (unsigned)samples[i], fault_text(fault));
    }
}

int main(void)
{
    const uint16_t samples[] = {45U,62U,79U,81U,75U,9U,32U,88U,70U,10U};
    printf("Industrial Fault Detection System\n");
    printf("High threshold: %u C\nLow threshold : %u C\n\n", HIGH_LIMIT, LOW_LIMIT);
    process_samples(samples, (uint8_t)(sizeof(samples)/sizeof(samples[0])));
    return 0;
}
