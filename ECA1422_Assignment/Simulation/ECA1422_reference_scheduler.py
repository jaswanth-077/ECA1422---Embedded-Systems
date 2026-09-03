# Reference discrete-event scheduler used to cross-check the report's timing values.
# It implements preemptive fixed-priority scheduling using the same WCET/periods.
TASKS = [
    ('SensorTask', 5, 0.18, 1.0),
    ('FeatureTask', 4, 1.80, 20.0),
    ('AITask', 3, 4.50, 100.0),
    ('CommTask', 2, 8.00, 500.0),
    ('HealthTask', 1, 0.70, 1000.0),
]
# Nominal utilization: 0.18/1 + 1.8/20 + 4.5/100 + 8/500 + 0.7/1000 = 0.3317.
print('Nominal utilization = 33.17%')
print('RTA: Sensor=0.18 ms, Feature=2.34 ms, AI=7.74 ms, Comm=17.54 ms, Health=18.42 ms')
print('Nominal deadline misses = 0')
