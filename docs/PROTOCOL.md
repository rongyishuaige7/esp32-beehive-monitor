# 本地 HTTP 协议与字段边界

> 本文件描述当前公开源码的固定接口，不是已连接设备的实时接口文档。所有网络和硬件行为仍待当前真机复测。

## 网络前提

仅当本地 `firmware/src/wifi_credentials.h` 存在且 ESP32 成功加入用户自己的 2.4 GHz 网络时，端口 `80` 才启动 HTTP。该文件不在仓库中，也不能提交。

HTTP 没有 TLS、认证、会话、授权、设备身份、审计或速率限制。它仅限短期、隔离、可信局域网；不得暴露到公网、端口转发、公共 Wi-Fi、共享热点或不可信网络。

Flutter 客户端只接受 RFC1918 / link-local IPv4 作为目标地址，固定请求 `http://<address>/api/status`，且不跟随 HTTP 重定向。测试地址仅写入应用本地存储；Android 已禁用应用数据备份，iOS 端没有构建/真机验证，故不对系统迁移或备份行为作额外承诺。一次请求成功只表示该次获得可解析的 `local_response` JSON，不表示设备在线、数据实时、传感器准确、蜂群状态、安全、告警送达或有人处理。

## 端点

| 方法 | 路径 | 当前源码行为 |
| :-- | :-- | :-- |
| `GET` | `/api/status` | 返回一次原始采样字段、固定标签、初始化标志、运行时间和短窗口气压趋势字段。 |
| `OPTIONS` | `/api/status` | 返回 `405` JSON；本仓不提供浏览器跨域接口。 |
| 任意 | 其他路径 | 返回 `404` JSON。 |

## `GET /api/status` 字段

| 字段 | 类型 | 当前源码含义 | 不代表 |
| :-- | :-- | :-- | :-- |
| `status` | string | 成功路径固定为 `local_response` | 设备在线、健康、认证或持续可用 |
| `temperature` | number/null | DHT11 当前读取值；本次失败时为 `null` | 蜂群适宜度、动物健康或环境安全 |
| `humidity` | number/null | DHT11 当前读取值；本次失败时为 `null` | 防霉、疾病、生产或安全建议 |
| `light` | number/null | BH1750 当前读取值；初始化或本次读取失败时为 `null` | 箱盖状态、箱体破损或蜂箱安全 |
| `pressure` | number/null | BMP280 当前读取值；初始化或本次读取失败时为 `null` | 天气预报、风暴或生产决策 |
| `soundLevel` | integer | GPIO34 ADC 峰峰值；本次未提供时为 `-1`，以 `soundValid` 为准 | 蜂群声音、行为、健康或异常诊断 |
| `mq2Raw` | integer | GPIO35 MQ-2 原始 ADC 平均值；预热或本次未提供时为 `-1`，以 `mq2Valid` 为准 | 烟雾浓度、可燃气体、火灾或安全告警 |
| `uptime` | integer | MCU 启动后秒数 | 长期稳定、设备在线或网络可达 |
| `labels` | object | 固定代码阈值生成的 `reference` / `attention` / `high_threshold`；本次读数未提供时为 `unavailable` | 正常、安全、危险、告警、诊断或处置 |
| `overallLabel` | string | 固定代码聚合标签；任一受限字段未提供时为 `unavailable` | 系统安全、风险等级或有人处理 |
| `temperatureValid` / `humidityValid` / `lightValid` / `pressureValid` / `soundValid` / `mq2Valid` | boolean | 对应字段在本次采样中是否取得有效数值；MQ-2 预热期间为 `false` | 当前传感器在线、连续可用、读数准确或接线正确 |
| `bh1750_ok` | boolean | 启动时 BH1750 初始化调用的返回值 | 当前传感器在线、读数有效或接线正确 |
| `bmp280_ok` | boolean | 启动时 BMP280 初始化调用的返回值 | 当前传感器在线、读数有效或接线正确 |
| `pressureTrend` | number/null | 短窗口样本换算出的数值趋势 | 气象预测、强风暴或天气判断 |
| `pressureTrendKind` | string | `unknown` / `stable` / `rising` / `falling` / `larger_rise` / `larger_fall` / `rapid_fall` | 天气预报或安全等级 |
| `pressureHistoryCount` | integer | 当前内存中用于趋势计算的样本数量 | 传感器长期稳定或历史数据完整 |

失败时可能返回：

```json
{"status":"local_error","message":"sensors not ready"}
```

未知路径：

```text
HTTP 404
{"status":"not_found","message":"Not found"}
```

## 数据与日志禁止项

不要公开 Wi-Fi SSID、密码、实际局域网 IP/MAC、位置、蜂场资料、真实传感器数据、网络抓包、串口日志、App 缓存、截图 EXIF/GPS 或视频中可识别的个人/地点信息。
