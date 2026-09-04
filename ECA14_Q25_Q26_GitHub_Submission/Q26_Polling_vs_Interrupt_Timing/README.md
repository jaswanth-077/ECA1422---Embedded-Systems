# Q26 – Polling vs Interrupt-Based Timing

## Objective
1. Demonstrate polling-based timing.
2. Demonstrate event-driven interrupt timing.
3. Compare response delay.
4. Explain CPU usage differences.
5. Discuss real-time suitability.
6. Show why hardware interrupts are useful for asynchronous events.

## Method
Polling checks the event at a fixed interval. Therefore detection can be delayed by up to one polling interval. The interrupt model services the event when the hardware interrupt occurs.

## Complexity
- Time: O(n) for n simulated events.
- Auxiliary space: O(1).

## Compile
`gcc Q26_polling_vs_interrupt.c -o q26`
`./q26`

## Note
This is a portable timing model for the coding challenge. On an MCU, replace the model with a hardware timer/counter and an actual ISR.
