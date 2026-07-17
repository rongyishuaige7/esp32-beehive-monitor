# 第三方组件与再分发说明

本仓只分发 Rongyi 整理后的项目源码、文档、BOM 和接线边界图。PlatformIO、Flutter SDK 与 pub 包由使用者在其本机构建环境中从上游获取；它们继续受各自许可证、NOTICE、商标与服务条款约束。发布二进制或再次分发前，请以当前上游许可证和精确解析版本为准。

| 组件 | 候选构建版本 / 用途 | 来源 / 许可入口 |
| :-- | :-- | :-- |
| PlatformIO Core | 6.1.19，构建入口 | https://github.com/platformio/platformio-core · Apache-2.0 |
| Espressif32 Platform | 6.13.0，ESP32 PlatformIO 平台 | https://github.com/platformio/platform-espressif32 · Apache-2.0 |
| Arduino-ESP32 | ESP32 Arduino、Wi-Fi、WebServer | https://github.com/espressif/arduino-esp32 · LGPL-2.1-or-later |
| DHT sensor library | 1.4.7，DHT11 | https://github.com/adafruit/DHT-sensor-library · MIT |
| Adafruit Unified Sensor | 1.1.15，DHT 依赖接口 | https://github.com/adafruit/Adafruit_Sensor · MIT |
| BH1750 | 1.3.0，光照读取 | https://github.com/claws/BH1750 · MIT |
| Adafruit BMP280 Library | 2.6.8，BMP280 | https://github.com/adafruit/Adafruit_BMP280_Library · MIT |
| ArduinoJson | 6.21.6，JSON 序列化 | https://github.com/bblanchon/ArduinoJson · MIT |
| Flutter SDK | 3.41.2，客户端框架 | https://github.com/flutter/flutter · BSD-3-Clause |
| `http` | 1.6.0，Flutter HTTP 客户端 | https://pub.dev/packages/http · BSD-3-Clause |
| `shared_preferences` | 2.5.5，保存本地测试地址 | https://pub.dev/packages/shared_preferences · BSD-3-Clause |
| `flutter_lints` | 4.0.0，开发期静态检查 | https://pub.dev/packages/flutter_lints · BSD-3-Clause |

本仓不分发第三方依赖源码、APK、固件二进制、真实 Wi-Fi 凭据、私网材料、实物照片、视频、音频、EDA、PCB、Gerber、制造文件、真实运行日志或传感器数据。第三方名称和商标不代表其对本项目的背书。
