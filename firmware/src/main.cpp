#include <Arduino.h>
#include <WiFi.h>
#include <cstring>

#include "config.h"
#include "sensors.h"
#include "web_server.h"

SensorManager g_sensorManager;
SensorManager* g_sensors = &g_sensorManager;
BeehiveWebServer g_web;

static unsigned long lastSensorUpdate = 0;
static unsigned long lastWifiAttempt = 0;
static bool httpStarted = false;

static bool wifiConfigured() { return strlen(WIFI_SSID) > 0; }

static void connectWifi() {
  if (!wifiConfigured()) {
    Serial.println(F("[WiFi] No local credentials: sensor sampling only; HTTP disabled."));
    return;
  }

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.println(F("[WiFi] Attempting configured local network connection."));
  int retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries < 40) {
    delay(500);
    Serial.print('.');
    ++retries;
  }
  Serial.println();
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print(F("[WiFi] Connected; local IP: "));
    Serial.println(WiFi.localIP());
    digitalWrite(STATUS_LED_PIN, HIGH);
  } else {
    Serial.println(F("[WiFi] Connection failed; HTTP remains disabled."));
    digitalWrite(STATUS_LED_PIN, LOW);
  }
}

static void startHttpIfConnected() {
  if (!httpStarted && WiFi.status() == WL_CONNECTED) {
    g_web.begin();
    httpStarted = true;
    Serial.println(F("[HTTP] Local teaching API started on port 80."));
  }
}

void setup() {
  Serial.begin(115200);
  delay(300);
  Serial.println(F("\n=== ESP32 Beehive Sensor Prototype ==="));

  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);
  if (!g_sensorManager.begin()) {
    Serial.println(F("[Sensors] Initialisation returned an error."));
  }
  g_sensors->update();
  lastSensorUpdate = millis();
  connectWifi();
  startHttpIfConnected();
}

void loop() {
  if (httpStarted) {
    g_web.handleClient();
  }

  const unsigned long now = millis();
  if (now - lastSensorUpdate >= SENSOR_UPDATE_MS) {
    lastSensorUpdate = now;
    g_sensors->update();
    SensorLabels labels{};
    g_sensors->computeLabels(labels);
    Serial.printf(
        "T:%.1f H:%.1f Lux:%.1f P:%.1f Sound:%d MQ2raw:%d | label:%d\n",
        g_sensors->getTemperature(), g_sensors->getHumidity(),
        g_sensors->getLightLux(), g_sensors->getPressure(),
        g_sensors->getSoundLevel(), g_sensors->getMq2Raw(),
        static_cast<int>(g_sensors->overallLabel(labels)));
  }

  if (wifiConfigured() && WiFi.status() != WL_CONNECTED) {
    digitalWrite(STATUS_LED_PIN, LOW);
    if (now - lastWifiAttempt > 15000UL) {
      lastWifiAttempt = now;
      Serial.println(F("[WiFi] Reconnecting to configured local network."));
      WiFi.disconnect();
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    }
  } else if (WiFi.status() == WL_CONNECTED) {
    digitalWrite(STATUS_LED_PIN, HIGH);
    startHttpIfConnected();
  }
  delay(2);
}
