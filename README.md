# 基于ESP32的蜂箱多传感器数据采集与局域网展示原型

> 本科阶段的软硬件教学原型。ESP32 读取 DHT11、BH1750、BMP280、模拟声音幅度和 MQ-2 原始 ADC；使用者在本地配置 Wi-Fi 后，Flutter 客户端可在可信局域网请求一条本地 JSON 响应。

[![Validate](https://github.com/rongyishuaige7/esp32-beehive-monitor/actions/workflows/validate.yml/badge.svg)](https://github.com/rongyishuaige7/esp32-beehive-monitor/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/Code-MIT-f97316.svg)](LICENSE)
[![Hardware retest](https://img.shields.io/badge/hardware-not%20retested-6e7781.svg)](docs/PROJECT_STATUS.md)

> [!CAUTION]
> 这是用于 ESP32、传感器采集、局域网 HTTP 与 Flutter 学习的教学原型，不是蜂群健康诊断、疾病识别、养蜂生产决策、气象预报、烟雾/燃气/火灾报警、环境安全、告警送达或无人值守系统。
>
> DHT11、BH1750、BMP280、声音幅度与 MQ-2 原始 ADC 都只是实验性输入。MQ-2 原始 ADC 不是烟雾浓度、可燃气体检测、火灾判断或安全告警；声音幅度不是蜂群行为、健康或异常诊断；气压估算变化不是天气预报。HTTP、App、CI、构建产物和固定阈值标签均不代表设备在线、数据准确、蜂箱安全、蜂群状态、告警送达或有人处理。

## Historical material evidence (2026-07-18 publication)

sanitized historical photo(s), historical EDA derivative(s). See [MEDIA_EVIDENCE](docs/MEDIA_EVIDENCE.md) for dates, sanitization, omissions, and evidence limits.

![Historical beehive-monitor prototype (capture date unknown)](assets/photos/historical-prototype.jpg)

Historical media/EDA do not prove that the current public commit was flashed or re-tested on hardware. **Current hardware re-test not run.**


## 当前状态与证据边界

| 项目 | 当前事实 |
| :-- | :-- |
| 源码来源 | 桌面原始工程为只读来源；公开候选不会反向修改原目录。 |
| 公开净化 | 不包含 Wi-Fi 凭据、私网地址、缓存、IDE 状态、构建物、APK、固件二进制、实物照片、视频、EDA、PCB、Gerber、制造文件或真实运行日志。 |
| 固件构建 | 本机公开门禁与当前候选固件构建将在 `docs/VERIFICATION.md` 记录；GitHub 的固定成功构建与 `main` exact HEAD 对应关系以 [Hardware Lab](https://github.com/rongyishuaige7/hardware-lab) 为准。 |
| Flutter 客户端 | 仅在 `flutter test`、`flutter analyze` 和 Android debug APK 构建通过后列为构建已验证；这不等于 Android/iOS 真机、Wi-Fi 或端到端验证。 |
| 当前真机复测 | 未执行；没有以当前公开 commit 重新烧录、配网、读取传感器或联调 Flutter 客户端的日期化证据。 |
| 媒体与 EDA | 当前未公开实物照片、演示视频、原理图、PCB、Gerber 或制造文件。 |

## 源码功能范围

```text
DHT11 / BH1750 / BMP280 / 模拟声音幅度 / MQ-2 原始 ADC
  → ESP32 中的固定采样与中性阈值标签
  → 可选：可信局域网中的本地 HTTP JSON
  → Flutter 客户端的本地数据展示
```

- 温湿度、光照与气压字段只表示程序在该次读取中得到的传感器数值；不构成蜂群适宜度、动物健康、箱盖状态或环境安全结论。
- 声音字段是 GPIO34 的 ADC 峰峰值；不保存音频，也不表示蜂群嗡鸣、攻击、失王、健康或异常行为。
- `mq2Raw` 是 GPIO35 的未经浓度校准 ADC 数值；不是烟雾、燃气、火灾、空气质量或安全检测。
- `reference`、`attention`、`high_threshold`、`unavailable` 只是源码固定比较规则或当前字段未提供标记；不表示正常、安全、危险、告警、诊断、天气、处置或优先级。
- 气压趋势是短窗口数值换算演示；它不是天气预报、风暴判断或养蜂生产决策依据。

## 硬件与电气边界

| 模块/信号 | ESP32 接口 | 源码可确认事实 | 实物仍需确认 |
| :-- | :-- | :-- | :-- |
| DHT11 | GPIO4 | 使用 DHT 库读取温湿度 | 型号、供电、数据上拉、线长与读数 |
| BH1750 | GPIO21 / GPIO22 | I²C 光照读取 | 地址、上拉、电压、总线质量与读数 |
| BMP280 | GPIO21 / GPIO22，源码地址 `0x76` | I²C 气压读取 | 实物地址、模块版本、电压、安装位置与读数 |
| 模拟声音输入 | GPIO34 | ADC 峰峰值采样 | 模块型号、输出摆幅、偏置、电平调理与标定 |
| MQ-2 或兼容模块 | GPIO35 | 原始 ADC 平均值采样 | 型号、预热、供电、输出范围、电平调理与实物行为 |
| 状态 LED | GPIO2 | 固件以该 GPIO 指示 Wi-Fi 连接尝试结果 | 是否板载、极性、限流、电流与接法 |

完整的 [BOM](hardware/BOM.csv)、[源码推导接线边界图](hardware/wiring-diagram.svg) 和 [硬件说明](HARDWARE.md) 不是原理图、PCB、实物接线、制造文件或真机复测证明。接线前务必断电，确认电压、电流、电平、限流、供电能力、公共地与 I²C 上拉。ESP32 GPIO/ADC 不得超过 3.3 V；MQ-2、LM386 或其他 AO 输出必须按实物模块完成分压或电平调理后才可接入 GPIO34/GPIO35。

## 本地构建与 Wi-Fi 配置

### 1. 固件构建

```bash
git clone https://github.com/rongyishuaige7/esp32-beehive-monitor.git
cd esp32-beehive-monitor/firmware
python3 -m pip install 'platformio==6.1.19'
pio run -e esp32dev
```

该命令只下载上游构建依赖并编译；不会烧录硬件、连接 Wi-Fi 或读取传感器。

### 2. 可选：本地 Wi-Fi 凭据

```bash
cd firmware/src
cp wifi_credentials.example.h wifi_credentials.h
# 仅在本机编辑 wifi_credentials.h，填写自己的 2.4 GHz Wi-Fi 配置
```

`wifi_credentials.h` 被 Git 忽略。不要提交、截图、录屏、粘贴到 Issue 或写入日志。未创建该文件时，固件仍能构建和采样，但不会连接 Wi-Fi 或启动 HTTP 服务。固件不会打印 SSID；如串口输出局域网 IP，请不要将其公开。

### 3. Flutter 客户端

```bash
cd app
flutter pub get
flutter test
flutter analyze
flutter build apk --debug
```

Android debug APK 构建只验证源码可构建；它不是签名发布包、iOS 构建、手机端真机验证或硬件联调。客户端只接受 RFC1918 / link-local IPv4，仅请求固定的明文 HTTP `/api/status`，并拒绝重定向；见[网络边界](#网络与数据边界)。

### 4. 一键公开门禁

```bash
bash scripts/verify.sh
```

脚本会执行公开边界、源码契约、ESP32 PlatformIO、Flutter 测试/分析/Android debug APK 构建，并清理候选目录内的生成物。它不会烧录 ESP32、连接真实 Wi-Fi、调用真实设备或证明任何硬件、网络、传感器或蜂箱结论。

## 本地 HTTP API（可选）

仅当使用者提供本地 `wifi_credentials.h` 且 ESP32 成功加入网络时，固件才会在端口 `80` 启动无认证、无 TLS、无访问控制、无审计、无设备身份与无速率限制的本地 HTTP 接口。

它只能用于隔离、可信、短期的教学局域网，不能暴露到公网、端口转发、公共 Wi-Fi、共享热点或不可信局域网。项目未提供公网部署方案。

| 方法 | 路径 | 当前源码行为 | 不代表 |
| :-- | :-- | :-- | :-- |
| `GET` | `/api/status` | 返回该请求时的原始字段、固定标签与初始化标志 | 设备在线、连续连接、传感器准确、蜂群状态、安全、告警送达或有人处理 |
| 其他 | 任意路径 | `404` JSON；`OPTIONS /api/status` 返回 `405` | API 已认证、网络安全或远程控制能力 |

字段、示例和明确边界见[协议说明](docs/PROTOCOL.md)。HTTP `200` 只表示这一次 handler 返回成功。

## 公开范围与来源

- 公开候选从桌面原工程的当前工作区隔离复制；原始目录没有 Git 历史，继续保持只读。
- 原始来源按 2026-07-17 的**安全 allowlist**清点有 87 个选定文件，manifest SHA-256 为 `1ed7916764ade5d7d24a564a4ed0b814c478ca1cc2b7c8838b401970ef8fa1d3`；该清点明确不纳入原始 `firmware/src/config.h` 或任何可能含凭据/本机状态的文件；公开的 [`docs/source-allowlist.txt`](docs/source-allowlist.txt) 与 [`scripts/source_manifest.py`](scripts/source_manifest.py) 说明安全算法和可复算边界。此记录只用于来源审计，不是公开仓构建依赖。
- 候选拆分了本地 Wi-Fi 凭据，删除了缓存、IDE、构建物、客户 APK 交付说明与强安全/健康/天气叙事，并将 HTTP/API/App 状态收窄为可审计的本地教学语义。
- 仓库不分发真实 Wi-Fi 凭据、私网材料、APK、固件二进制、实物照片、视频、屏幕截图、EDA、PCB、Gerber、制造文件、真实日志或传感器数据。

详细范围见[来源说明](docs/SOURCE_PROVENANCE.md)。

## 验证与真机复测

当前 CI 与本地门禁验证公开文件边界、源码契约和固定构建配置。它们不验证真实 ESP32、DHT11、BH1750、BMP280、MQ-2、声音输入、LED、电平、供电、Wi-Fi、HTTP、Android/iOS、Flutter 或端到端行为。

将状态升级为“当前真机已复测”前，必须按[真机复测清单](docs/VERIFICATION.md)记录日期、完整 Git commit、精确板型、模块、供电、电平/分压、接线和每项通过/失败/未测结果。即使完成复测，本项目也不会成为安全、动物健康、天气或生产决策设备。

## 开源许可与第三方组件

Rongyi 自有的候选源码、文档、BOM 和接线边界图以 [MIT License](LICENSE) 发布。ESP32 Arduino 框架、PlatformIO、Flutter SDK、DHT、BH1750、BMP280、ArduinoJson、`http` 和 `shared_preferences` 均由使用者在构建时从上游获取；其来源与许可证入口见[第三方声明](THIRD_PARTY_NOTICES.md)。

## 安全、数据与不适用场景

完整限制见[安全说明](SECURITY.md)。报告问题时，请勿公开 Wi-Fi 凭据、私网 IP/MAC、位置、网络日志、截图 EXIF/GPS、真实传感器记录、蜂场信息、个人信息或其他敏感材料。
