#include "sensors.h"

SensorManager::SensorManager()
    : dht_(DHT11_PIN, DHT11),
      bh_(),
      bmp_(&Wire),
      temperature_(NAN),
      humidity_(NAN),
      lightLux_(0),
      pressureHpa_(0),
      soundLevel_(0),
      mq2Raw_(0),
      soundActive_(false),
      temperatureValid_(false),
      humidityValid_(false),
      lightValid_(false),
      pressureValid_(false),
      soundSampleReady_(false),
      mq2SampleReady_(false),
      bhOk_(false),
      bmpOk_(false),
      preheatDoneMs_(0),
      pressureHistoryCount_(0),
      pressureHistoryHead_(0),
      nextPressureSampleMs_(0),
      pressureTrendHpa_(NAN),
      pressureTrendKind_(PressureTrend::Unknown) {
  for (size_t i = 0; i < PRESSURE_HISTORY_SIZE; ++i) {
    pressureHistory_[i] = NAN;
  }
}

bool SensorManager::begin() {
  preheatDoneMs_ = millis() + MQ2_PREHEAT_MS;
  nextPressureSampleMs_ = millis();
  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);
  analogSetAttenuation(ADC_11db);
  dht_.begin();
  Wire.begin(I2C_SDA, I2C_SCL);
  bhOk_ = bh_.begin(BH1750::CONTINUOUS_HIGH_RES_MODE);
  if (!bhOk_) Serial.println(F("[BH1750] Initialisation failed."));
  bmpOk_ = bmp_.begin(BMP280_ADDR);
  if (!bmpOk_) {
    Serial.println(F("[BMP280] Initialisation failed."));
  } else {
    bmp_.setSampling(Adafruit_BMP280::MODE_NORMAL, Adafruit_BMP280::SAMPLING_X2,
                     Adafruit_BMP280::SAMPLING_X16, Adafruit_BMP280::FILTER_X16,
                     Adafruit_BMP280::STANDBY_MS_500);
  }
  return true;
}

int SensorManager::averageAnalog(int pin, int samples) const {
  long sum = 0;
  for (int i = 0; i < samples; ++i) {
    sum += analogRead(pin);
    delayMicroseconds(200);
  }
  return static_cast<int>(sum / samples);
}

int SensorManager::peakToPeakAnalog(int pin, int samples) const {
  int minValue = 4095;
  int maxValue = 0;
  for (int i = 0; i < samples; ++i) {
    const int value = analogRead(pin);
    if (value > maxValue) maxValue = value;
    if (value < minValue) minValue = value;
    delayMicroseconds(200);
  }
  return maxValue - minValue;
}

void SensorManager::update() {
  const float t = dht_.readTemperature();
  const float h = dht_.readHumidity();
  temperatureValid_ = !isnan(t);
  humidityValid_ = !isnan(h);
  temperature_ = temperatureValid_ ? t : NAN;
  humidity_ = humidityValid_ ? h : NAN;
  lightValid_ = false;
  if (bhOk_) {
    const float lux = bh_.readLightLevel();
    lightValid_ = lux >= 0;
    lightLux_ = lightValid_ ? lux : NAN;
  } else {
    lightLux_ = NAN;
  }
  pressureValid_ = false;
  if (bmpOk_) {
    const float p = bmp_.readPressure() / 100.0F;
    pressureValid_ = !isnan(p);
    pressureHpa_ = pressureValid_ ? p : NAN;
    sampleAndUpdatePressureTrend();
  } else {
    pressureHpa_ = NAN;
    pressureTrendHpa_ = NAN;
    pressureTrendKind_ = PressureTrend::Unknown;
  }
  if (!pressureValid_) {
    pressureTrendHpa_ = NAN;
    pressureTrendKind_ = PressureTrend::Unknown;
  }
  soundLevel_ = peakToPeakAnalog(SOUND_PIN, SOUND_SAMPLES);
  soundSampleReady_ = true;
  soundActive_ = soundLevel_ >= SOUND_ACTIVE_THRESHOLD;
  mq2Raw_ = averageAnalog(MQ2_PIN, 4);
  mq2SampleReady_ = static_cast<long>(millis() - preheatDoneMs_) >= 0;
}

void SensorManager::computeLabels(SensorLabels& out) const {
  // Labels remain fixed code comparisons, but a field whose current sample is
  // unavailable is never emitted as a positive-looking `reference` label.
  out = {temperatureValid_ ? SampleLabel::Reference : SampleLabel::Unavailable,
         humidityValid_ ? SampleLabel::Reference : SampleLabel::Unavailable,
         lightValid_ ? SampleLabel::Reference : SampleLabel::Unavailable,
         soundSampleReady_ ? SampleLabel::Reference : SampleLabel::Unavailable,
         mq2SampleReady_ ? SampleLabel::Reference : SampleLabel::Unavailable,
         pressureValid_ ? SampleLabel::Reference : SampleLabel::Unavailable};
  if (!isnan(temperature_)) {
    if (temperature_ < TEMP_EXTREME_LOW || temperature_ > TEMP_EXTREME_HIGH) {
      out.temperature = SampleLabel::HighThreshold;
    } else if (temperature_ < TEMP_REFERENCE_LOW || temperature_ > TEMP_REFERENCE_HIGH) {
      out.temperature = SampleLabel::Attention;
    }
  }
  if (!isnan(humidity_)) {
    if (humidity_ < HUMIDITY_EXTREME_LOW || humidity_ > HUMIDITY_EXTREME_HIGH) {
      out.humidity = SampleLabel::HighThreshold;
    } else if (humidity_ < HUMIDITY_REFERENCE_LOW || humidity_ > HUMIDITY_REFERENCE_HIGH) {
      out.humidity = SampleLabel::Attention;
    }
  }
  if (lightValid_ && lightLux_ >= LIGHT_REFERENCE_THRESHOLD_LUX) out.light = SampleLabel::Attention;
  if (mq2SampleReady_ && mq2Raw_ >= MQ2_HIGH_THRESHOLD) {
    out.mq2 = SampleLabel::HighThreshold;
  } else if (mq2SampleReady_ && mq2Raw_ >= MQ2_REFERENCE_THRESHOLD) {
    out.mq2 = SampleLabel::Attention;
  }
  if (!mq2SampleReady_) out.mq2 = SampleLabel::Unavailable;
  if (pressureValid_) {
    if (pressureHpa_ < 950.0f || pressureHpa_ > 1050.0f) out.pressure = SampleLabel::Attention;
    if (pressureTrendKind_ == PressureTrend::RapidFall) {
      out.pressure = SampleLabel::HighThreshold;
    } else if (pressureTrendKind_ == PressureTrend::LargerFall ||
               pressureTrendKind_ == PressureTrend::LargerRise) {
      if (out.pressure != SampleLabel::HighThreshold) out.pressure = SampleLabel::Attention;
    }
  }
  if (soundSampleReady_ && soundActive_) out.sound = SampleLabel::Attention;
}

void SensorManager::sampleAndUpdatePressureTrend() {
  if (!bmpOk_ || isnan(pressureHpa_)) return;
  const unsigned long now = millis();
  if (static_cast<long>(now - nextPressureSampleMs_) >= 0) {
    pressureHistory_[pressureHistoryHead_] = pressureHpa_;
    pressureHistoryHead_ = (pressureHistoryHead_ + 1) % PRESSURE_HISTORY_SIZE;
    if (pressureHistoryCount_ < PRESSURE_HISTORY_SIZE) ++pressureHistoryCount_;
    nextPressureSampleMs_ = now + PRESSURE_SAMPLE_INTERVAL_MS;
  }
  if (pressureHistoryCount_ < PRESSURE_TREND_MIN_SAMPLES) {
    pressureTrendHpa_ = NAN;
    pressureTrendKind_ = PressureTrend::Unknown;
    return;
  }
  const size_t oldestIndex =
      (pressureHistoryHead_ + PRESSURE_HISTORY_SIZE - pressureHistoryCount_) % PRESSURE_HISTORY_SIZE;
  const float oldest = pressureHistory_[oldestIndex];
  if (isnan(oldest)) {
    pressureTrendHpa_ = NAN;
    pressureTrendKind_ = PressureTrend::Unknown;
    return;
  }
  const unsigned long windowMs =
      static_cast<unsigned long>(pressureHistoryCount_ - 1) * PRESSURE_SAMPLE_INTERVAL_MS;
  const float scale = static_cast<float>(3UL * 60UL * 60UL * 1000UL) / static_cast<float>(windowMs);
  pressureTrendHpa_ = (pressureHpa_ - oldest) * scale;
  const bool earlyWindow = windowMs < PRESSURE_TREND_STABLE_WINDOW_MS;
  const float delta = pressureTrendHpa_;
  if (!earlyWindow && delta <= -PRESSURE_TREND_HIGH_THRESHOLD_HPA) {
    pressureTrendKind_ = PressureTrend::RapidFall;
  } else if (!earlyWindow && delta <= -PRESSURE_TREND_LABEL_THRESHOLD_HPA) {
    pressureTrendKind_ = PressureTrend::LargerFall;
  } else if (!earlyWindow && delta >= PRESSURE_TREND_LABEL_THRESHOLD_HPA) {
    pressureTrendKind_ = PressureTrend::LargerRise;
  } else if (delta <= -1.0f) {
    pressureTrendKind_ = PressureTrend::Falling;
  } else if (delta >= 1.0f) {
    pressureTrendKind_ = PressureTrend::Rising;
  } else {
    pressureTrendKind_ = PressureTrend::Stable;
  }
}

SampleLabel SensorManager::overallLabel(const SensorLabels& labels) const {
  if (labels.temperature == SampleLabel::Unavailable || labels.humidity == SampleLabel::Unavailable ||
      labels.light == SampleLabel::Unavailable || labels.sound == SampleLabel::Unavailable ||
      labels.mq2 == SampleLabel::Unavailable || labels.pressure == SampleLabel::Unavailable) {
    return SampleLabel::Unavailable;
  }
  if (labels.temperature == SampleLabel::HighThreshold ||
      labels.humidity == SampleLabel::HighThreshold ||
      labels.mq2 == SampleLabel::HighThreshold ||
      labels.pressure == SampleLabel::HighThreshold) {
    return SampleLabel::HighThreshold;
  }
  if (labels.temperature == SampleLabel::Attention || labels.humidity == SampleLabel::Attention ||
      labels.light == SampleLabel::Attention || labels.sound == SampleLabel::Attention ||
      labels.mq2 == SampleLabel::Attention || labels.pressure == SampleLabel::Attention) {
    return SampleLabel::Attention;
  }
  return SampleLabel::Reference;
}
