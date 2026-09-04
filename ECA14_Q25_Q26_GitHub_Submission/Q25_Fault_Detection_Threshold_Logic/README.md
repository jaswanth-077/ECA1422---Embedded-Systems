# Q25 – Fault Detection Using Threshold Logic

## Objective
1. Read a sensor value.
2. Compare it with industrial safety thresholds.
3. Detect high and low threshold faults.
4. Report the fault condition.
5. Keep decision logic modular and portable.
6. Use fixed-width embedded data types.

## Logic
- Temperature > 80 C → HIGH TEMPERATURE FAULT
- Temperature < 10 C → LOW TEMPERATURE FAULT
- Otherwise → NORMAL

## Complexity
- Time: O(n) for n samples.
- Auxiliary space: O(1).

## Compile
`gcc Q25_fault_detection.c -o q25`
`./q25`
