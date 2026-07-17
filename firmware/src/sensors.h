#ifndef SENSORS_H
#define SENSORS_H

#include <Arduino.h>
#include <Wire.h>
#include <DHT.h>
#include <BH1750.h>
#include <Adafruit_BMP280.h>

#include "config.h"

// These are fixed code labels for a teaching prototype, not safety states.
enum class SampleLabel : uint8_t { Reference = 0, Attention = 1, HighThreshold = 2, Unavailable = 3 };

// Numerical trend labels, not a forecast.
enum class PressureTrend : uint8_t {
  Unknown = 0,
  Stable = 1,
  Rising = 2,
  Falling = 3,
  LargerRise = 4,
  LargerFall = 5,
  RapidFall = 6,
};

struct SensorLabels {
  SampleLabel temperature;
  SampleLabel humidity;
  SampleLabel light;
  SampleLabel sound;
  SampleLabel mq2;
  SampleLabel pressure;
};

class SensorManager {
 public:
  SensorManager();
  bool begin();
  void update();

  float getTemperature() const { return temperature_; }
  float getHumidity() const { return humidity_; }
  float getLightLux() const { return lightLux_; }
  float getPressure() const { return pressureHpa_; }
  int getSoundLevel() const { return soundLevel_; }
  int getMq2Raw() const { return mq2Raw_; }
  bool isSoundActive() const { return soundActive_; }
  bool temperatureValid() const { return temperatureValid_; }
  bool humidityValid() const { return humidityValid_; }
  bool lightValid() const { return lightValid_; }
  bool pressureValid() const { return pressureValid_; }
  bool soundSampleReady() const { return soundSampleReady_; }
  bool mq2SampleReady() const { return mq2SampleReady_; }
  bool bhOk() const { return bhOk_; }
  bool bmpOk() const { return bmpOk_; }
  float getPressureTrend() const { return pressureTrendHpa_; }
  PressureTrend getPressureTrendKind() const { return pressureTrendKind_; }
  size_t getPressureHistoryCount() const { return pressureHistoryCount_; }

  void computeLabels(SensorLabels& out) const;
  SampleLabel overallLabel(const SensorLabels& labels) const;

 private:
  int averageAnalog(int pin, int samples) const;
  int peakToPeakAnalog(int pin, int samples) const;
  void sampleAndUpdatePressureTrend();

  DHT dht_;
  BH1750 bh_;
  Adafruit_BMP280 bmp_;
  float temperature_;
  float humidity_;
  float lightLux_;
  float pressureHpa_;
  int soundLevel_;
  int mq2Raw_;
  bool soundActive_;
  bool temperatureValid_;
  bool humidityValid_;
  bool lightValid_;
  bool pressureValid_;
  bool soundSampleReady_;
  bool mq2SampleReady_;
  bool bhOk_;
  bool bmpOk_;
  unsigned long preheatDoneMs_;
  float pressureHistory_[PRESSURE_HISTORY_SIZE];
  size_t pressureHistoryCount_;
  size_t pressureHistoryHead_;
  unsigned long nextPressureSampleMs_;
  float pressureTrendHpa_;
  PressureTrend pressureTrendKind_;
};

#endif
