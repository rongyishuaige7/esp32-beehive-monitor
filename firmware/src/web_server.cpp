#include "web_server.h"

#include <ArduinoJson.h>

#include "sensors.h"

extern SensorManager* g_sensors;

static const char* labelToString(SampleLabel label) {
  switch (label) {
    case SampleLabel::HighThreshold: return "high_threshold";
    case SampleLabel::Attention: return "attention";
    case SampleLabel::Unavailable: return "unavailable";
    default: return "reference";
  }
}

static const char* pressureTrendToString(PressureTrend trend) {
  switch (trend) {
    case PressureTrend::RapidFall: return "rapid_fall";
    case PressureTrend::LargerFall: return "larger_fall";
    case PressureTrend::LargerRise: return "larger_rise";
    case PressureTrend::Falling: return "falling";
    case PressureTrend::Rising: return "rising";
    case PressureTrend::Stable: return "stable";
    default: return "unknown";
  }
}

BeehiveWebServer::BeehiveWebServer() : server_(80) {}

void BeehiveWebServer::begin() {
  server_.on("/api/status", HTTP_GET, [this]() {
    server_.sendHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    if (g_sensors == nullptr) {
      server_.send(500, "application/json", "{\"status\":\"local_error\",\"message\":\"sensors not ready\"}");
      return;
    }
    SensorLabels labels{};
    g_sensors->computeLabels(labels);
    StaticJsonDocument<1024> document;
    document["status"] = "local_response";
    document["temperature"] = g_sensors->temperatureValid() ? g_sensors->getTemperature() : NAN;
    document["humidity"] = g_sensors->humidityValid() ? g_sensors->getHumidity() : NAN;
    document["light"] = g_sensors->lightValid() ? g_sensors->getLightLux() : NAN;
    document["pressure"] = g_sensors->pressureValid() ? g_sensors->getPressure() : NAN;
    document["soundLevel"] = g_sensors->soundSampleReady() ? g_sensors->getSoundLevel() : -1;
    document["mq2Raw"] = g_sensors->mq2SampleReady() ? g_sensors->getMq2Raw() : -1;
    document["uptime"] = millis() / 1000;
    document["overallLabel"] = labelToString(g_sensors->overallLabel(labels));
    JsonObject labelsJson = document.createNestedObject("labels");
    labelsJson["temperature"] = labelToString(labels.temperature);
    labelsJson["humidity"] = labelToString(labels.humidity);
    labelsJson["light"] = labelToString(labels.light);
    labelsJson["sound"] = labelToString(labels.sound);
    labelsJson["mq2"] = labelToString(labels.mq2);
    labelsJson["pressure"] = labelToString(labels.pressure);
    document["temperatureValid"] = g_sensors->temperatureValid();
    document["humidityValid"] = g_sensors->humidityValid();
    document["lightValid"] = g_sensors->lightValid();
    document["pressureValid"] = g_sensors->pressureValid();
    document["soundValid"] = g_sensors->soundSampleReady();
    document["mq2Valid"] = g_sensors->mq2SampleReady();
    document["bh1750_ok"] = g_sensors->bhOk();
    document["bmp280_ok"] = g_sensors->bmpOk();
    const float trend = g_sensors->getPressureTrend();
    if (isnan(trend)) {
      document["pressureTrend"] = nullptr;
    } else {
      document["pressureTrend"] = trend;
    }
    document["pressureTrendKind"] = pressureTrendToString(g_sensors->getPressureTrendKind());
    document["pressureHistoryCount"] = static_cast<uint32_t>(g_sensors->getPressureHistoryCount());
    String response;
    serializeJson(document, response);
    server_.send(200, "application/json", response);
  });
  server_.on("/api/status", HTTP_OPTIONS, [this]() {
    server_.send(405, "application/json", "{\"status\":\"method_not_allowed\",\"message\":\"GET only\"}");
  });
  server_.onNotFound([this]() {
    server_.send(404, "application/json", "{\"status\":\"not_found\",\"message\":\"Not found\"}");
  });
  server_.begin();
}

void BeehiveWebServer::handleClient() { server_.handleClient(); }
