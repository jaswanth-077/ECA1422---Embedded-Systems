# Source-code sanitization note

The submitted ESP32 firmware is a credential-sanitized copy of the implemented `EXP8.ino`.

Changes made only for safe submission:
- Wi-Fi SSID replaced with `YOUR_WIFI_SSID`
- Wi-Fi password replaced with `YOUR_WIFI_PASSWORD`

No functional logic was intentionally changed.

Security note:
- The firmware currently uses `WiFiClientSecure::setInsecure()` for development Firebase HTTPS communication. This is documented as a development limitation and should be replaced with certificate validation before production deployment.
