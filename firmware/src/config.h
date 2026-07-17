#ifndef CONFIG_H
#define CONFIG_H

// wifi_credentials.h is deliberately local-only.  Without it, the firmware
// still compiles and performs local sensor sampling, but starts no Wi-Fi or
// HTTP service.
#if __has_include("wifi_credentials.h")
#include "wifi_credentials.h"
#else
#define WIFI_SSID ""
#define WIFI_PASSWORD ""
#endif

// -------- Hardware interfaces inferred from the source --------
#define DHT11_PIN 4
#define I2C_SDA 21
#define I2C_SCL 22
#define BMP280_ADDR 0x76
#define SOUND_PIN 34   // LM386 / analogue microphone module → ADC1
#define MQ2_PIN 35     // MQ-2 analogue output → ADC1
#define STATUS_LED_PIN 2

// -------- Sampling schedule --------
#define SENSOR_UPDATE_MS 2000UL
#define MQ2_PREHEAT_MS 20000UL
#define SOUND_SAMPLES 10

// -------- Demonstration labels, not animal-health or safety limits --------
// These fixed values only label readings in the teaching prototype.  They are
// not calibrated hive limits and must not drive husbandry or safety decisions.
#define TEMP_REFERENCE_LOW 33.0f
#define TEMP_REFERENCE_HIGH 36.0f
#define TEMP_EXTREME_LOW 10.0f
#define TEMP_EXTREME_HIGH 40.0f
#define HUMIDITY_REFERENCE_LOW 50.0f
#define HUMIDITY_REFERENCE_HIGH 75.0f
#define HUMIDITY_EXTREME_LOW 20.0f
#define HUMIDITY_EXTREME_HIGH 90.0f
#define LIGHT_REFERENCE_THRESHOLD_LUX 500.0f
#define SOUND_ACTIVE_THRESHOLD 200

// MQ-2 is reported only as a raw ADC input.  These thresholds are display
// labels, not smoke concentration, combustible-gas detection, fire detection,
// air-quality measurement, or an alarm threshold.
#define MQ2_REFERENCE_THRESHOLD 2000
#define MQ2_HIGH_THRESHOLD 3200

// A short rolling pressure calculation is retained as a numerical trend demo.
// It is not weather prediction and must not be used for weather decisions.
#define PRESSURE_SAMPLE_INTERVAL_MS (30UL * 1000UL)
#define PRESSURE_HISTORY_SIZE 180
#define PRESSURE_TREND_LABEL_THRESHOLD_HPA 3.0f
#define PRESSURE_TREND_HIGH_THRESHOLD_HPA 5.0f
#define PRESSURE_TREND_MIN_SAMPLES 2
#define PRESSURE_TREND_STABLE_WINDOW_MS (5UL * 60UL * 1000UL)

#endif
