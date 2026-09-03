#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>
#include <time.h>

// =====================================================
// WIFI
// =====================================================

const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// =====================================================
// FIREBASE
// =====================================================

const char* FIREBASE_URL =
  "https://airquality-f7011-default-rtdb.firebaseio.com";

// =====================================================
// TIME / NTP
// =====================================================

// India Standard Time (UTC +5:30)
const long GMT_OFFSET_SEC = 19800;
const int DAYLIGHT_OFFSET_SEC = 0;

const char* NTP_SERVER_1 = "pool.ntp.org";
const char* NTP_SERVER_2 = "time.nist.gov";
const char* NTP_SERVER_3 = "time.google.com";

// =====================================================
// OLED
// =====================================================

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

#define OLED_SDA 21
#define OLED_SCL 22

Adafruit_SSD1306 display(
  SCREEN_WIDTH,
  SCREEN_HEIGHT,
  &Wire,
  -1
);

// =====================================================
// DHT11
// =====================================================

#define DHT_PIN 4
#define DHT_TYPE DHT11

DHT dht(DHT_PIN, DHT_TYPE);

// =====================================================
// TEMPORARY PM2.5 VALUE
// =====================================================

float pm25 = 18.0;
float pmDirection = 0.3;

// =====================================================
// GET CURRENT TIMESTAMP
// =====================================================

String getTimestamp() {

  struct tm timeinfo;

  if (!getLocalTime(&timeinfo)) {

    Serial.println("Time synchronization failed!");

    return "TIME_NOT_SYNCED";
  }

  char timestamp[25];

  strftime(
    timestamp,
    sizeof(timestamp),
    "%Y-%m-%d %H:%M:%S",
    &timeinfo
  );

  return String(timestamp);
}

// =====================================================
// SETUP
// =====================================================

void setup() {

  Serial.begin(115200);

  // ---------------------------------------------------
  // OLED
  // ---------------------------------------------------

  Wire.begin(OLED_SDA, OLED_SCL);

  if (!display.begin(
      SSD1306_SWITCHCAPVCC,
      0x3C
    )) {

    Serial.println("OLED not found - continuing without OLED");

  } else {

    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);
  }

  // ---------------------------------------------------
  // DHT
  // ---------------------------------------------------

  dht.begin();

  // ---------------------------------------------------
  // WIFI
  // ---------------------------------------------------

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Connecting to WiFi");

  while (WiFi.status() != WL_CONNECTED) {

    delay(500);

    Serial.print(".");
  }

  Serial.println();
  Serial.println("WiFi connected!");

  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  // ---------------------------------------------------
// NTP TIME SYNCHRONIZATION
// ---------------------------------------------------

Serial.println("Synchronizing time...");

configTime(
  GMT_OFFSET_SEC,
  DAYLIGHT_OFFSET_SEC,
  NTP_SERVER_1,
  NTP_SERVER_2,
  NTP_SERVER_3
);

struct tm timeinfo;

if (getLocalTime(&timeinfo, 10000)) {

  Serial.println("Time synchronized!");

  char timeBuffer[25];

  strftime(
    timeBuffer,
    sizeof(timeBuffer),
    "%Y-%m-%d %H:%M:%S",
    &timeinfo
  );

  Serial.print("Current time: ");
  Serial.println(timeBuffer);

} else {

  Serial.println("WARNING: Time synchronization failed!");
}

  // ---------------------------------------------------
  // OLED WIFI MESSAGE
  // ---------------------------------------------------

  display.clearDisplay();

  display.setTextSize(1);
  display.setCursor(20, 20);
  display.println("WiFi Connected");

  display.display();

  delay(1500);
}

// =====================================================
// LOOP
// =====================================================

void loop() {

  // ---------------------------------------------------
  // READ DHT11
  // ---------------------------------------------------

  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();

  if (isnan(temperature) || isnan(humidity)) {

    Serial.println("DHT11 reading failed!");

    delay(2000);

    return;
  }

  // ---------------------------------------------------
  // TEMPORARY PM2.5 VALUE
  // ---------------------------------------------------

  pm25 += pmDirection;

  if (pm25 >= 35.0) {
    pmDirection = -0.3;
  }

  if (pm25 <= 12.0) {
    pmDirection = 0.3;
  }

  // ---------------------------------------------------
  // AIR QUALITY STATUS
  // ---------------------------------------------------

  String status;

  if (pm25 <= 12.0) {

    status = "GOOD";

  } else if (pm25 <= 35.4) {

    status = "MODERATE";

  } else if (pm25 <= 55.4) {

    status = "UNHEALTHY";

  } else {

    status = "POOR";
  }

  // ---------------------------------------------------
  // SERIAL OUTPUT
  // ---------------------------------------------------

  Serial.println();
  Serial.println("--------------------");

  Serial.print("Temperature: ");
  Serial.print(temperature, 1);
  Serial.println(" C");

  Serial.print("Humidity: ");
  Serial.print(humidity, 1);
  Serial.println(" %");

  Serial.print("PM2.5: ");
  Serial.print(pm25, 1);
  Serial.println(" ug/m3");

  Serial.print("Air Quality: ");
  Serial.println(status);

  // ---------------------------------------------------
  // OLED
  // ---------------------------------------------------

  display.clearDisplay();

  display.setTextSize(1);

  display.setCursor(25, 0);
  display.println("AIR QUALITY");

  display.drawLine(
    0, 11,
    127, 11,
    SSD1306_WHITE
  );

  display.setCursor(0, 17);
  display.print("T: ");
  display.print(temperature, 1);
  display.println(" C");

  display.setCursor(0, 29);
  display.print("H: ");
  display.print(humidity, 1);
  display.println(" %");

  display.setCursor(0, 41);
  display.print("PM2.5: ");
  display.print(pm25, 1);

  display.setCursor(0, 53);
  display.print(status);

  display.display();

  // ---------------------------------------------------
  // SEND TO FIREBASE
  // ---------------------------------------------------

  sendToFirebase(
    temperature,
    humidity,
    pm25,
    status
  );

  // ---------------------------------------------------
  // 5 SECOND MEASUREMENT CYCLE
  // ---------------------------------------------------

  delay(5000);
}

// =====================================================
// FIREBASE FUNCTION
// =====================================================

void sendToFirebase(
  float temperature,
  float humidity,
  float pm25,
  String status
) {

  // ---------------------------------------------------
  // CHECK WIFI
  // ---------------------------------------------------

  if (WiFi.status() != WL_CONNECTED) {

    Serial.println("WiFi disconnected!");

    return;
  }

  // ---------------------------------------------------
  // HTTPS CLIENT
  // ---------------------------------------------------

  WiFiClientSecure client;

  // Development only:
  // accept Firebase HTTPS certificate
  client.setInsecure();

  HTTPClient http;

  // ===================================================
  // CREATE JSON DATA
  // ===================================================
String timestamp = getTimestamp();

String json = "{";

json += "\"timestamp\":\"";
json += timestamp;
json += "\"";

json += ",\"temperature\":";
json += String(temperature, 1);

json += ",\"humidity\":";
json += String(humidity, 1);

json += ",\"pm25\":";
json += String(pm25, 1);

json += ",\"status\":\"";
json += status;
json += "\"";

json += "}";

  // ===================================================
  // 1. UPDATE LATEST READING
  // ===================================================

  String latestURL =
    String(FIREBASE_URL) +
    "/sensor.json";

  http.begin(client, latestURL);

  http.addHeader(
    "Content-Type",
    "application/json"
  );

  Serial.println("Updating latest reading...");

  int latestCode =
    http.PUT(json);

  Serial.print("Latest Firebase HTTP Code: ");
  Serial.println(latestCode);

  if (latestCode > 0) {

    Serial.println("Latest reading updated successfully.");

  } else {

    Serial.print("Latest Firebase error: ");
    Serial.println(
      http.errorToString(latestCode)
    );
  }

  http.end();

  // ===================================================
  // 2. SAVE HISTORICAL READING
  // ===================================================

  String historyURL =
    String(FIREBASE_URL) +
    "/readings.json";

  http.begin(client, historyURL);

  http.addHeader(
    "Content-Type",
    "application/json"
  );

  Serial.println("Saving historical reading...");

  int historyCode =
    http.POST(json);

  Serial.print("History Firebase HTTP Code: ");
  Serial.println(historyCode);

  if (historyCode > 0) {

    Serial.println(
      "Historical reading saved successfully."
    );

    Serial.print("Firebase response: ");
    Serial.println(
      http.getString()
    );

  } else {

    Serial.print("History Firebase error: ");
    Serial.println(
      http.errorToString(historyCode)
    );
  }

  http.end();
}