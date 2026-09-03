# Raw Firebase data

Source: direct export of the Firebase Realtime Database `/readings` and `/sensor` nodes supplied for the technical submission.

- Historical records in `/readings`: **510**
- Valid explicit timestamps: **424**
- Missing timestamp field: **84**
- `TIME_NOT_SYNCED` records: **2**
- Latest `/sensor` record: `{'humidity': 74.1, 'pm25': 24.3, 'status': 'MODERATE', 'temperature': 30.7, 'timestamp': '2026-09-03 16:25:54'}`

The raw JSON is preserved without numerical modification. Processed CSV files are derived from this raw export.
