# Implementation Summary

## Hardware
ESP32 DevKit V1 + DHT11 + SSD1306 OLED.

## Pin map
| Device | Signal | ESP32 |
|---|---|---|
| DHT11 | DATA | GPIO 4 |
| SSD1306 | SDA | GPIO 21 |
| SSD1306 | SCL | GPIO 22 |
| SSD1306 | I²C address | 0x3C |

## Firmware
The loop reads DHT11 temperature/humidity, updates a PM2.5 software simulation, classifies a qualitative status, updates the OLED, then sends a JSON payload to Firebase.

## Firebase
- `/sensor`: latest record
- `/readings`: historical records

## Current data export
- 510 historical records
- PM2.5 min/mean/max: 11.7/24.595/35.1 µg/m³
- PM2.5 population SD: 6.385 µg/m³
- Status: 508 MODERATE, 2 GOOD

## Engineering deviations
The intended PM2.5 simulation bounds were documented as 12.0–35.0 µg/m³, but the current ±0.3 stepping logic produces observed boundary values of 11.7 and 35.1 µg/m³. This is a one-step boundary-crossing issue caused by updating before the bound reversal. It is documented rather than hidden.

## Security limitation
The development firmware uses `client.setInsecure()` for TLS. Production deployment should use certificate validation and hardened Firebase rules.
