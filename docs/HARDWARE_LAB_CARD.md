# Hardware Lab 索引卡片

```yaml
name: 基于ESP32的蜂箱多传感器数据采集与局域网展示原型
platform: ESP32 · Arduino · PlatformIO · Flutter · DHT11 · BH1750 · BMP280 · 模拟 ADC · 本地 HTTP
summary: DHT11、BH1750、BMP280、声音幅度和 MQ-2 原始 ADC 驱动 ESP32 的固定采样与中性阈值标签；使用者本地配置后可由 Flutter 客户端在可信局域网读取 JSON。
status: 源码来源已确认 · 公开净化与完整本地门禁/固件/Flutter 构建通过 · GitHub Actions exact-HEAD 证据待私有仓推送 · 当前端到端真机复测未执行
media_scope: 当前没有公开实物照片、演示视频、原理图、PCB、Gerber 或制造文件；公开 BOM、源码推导接线边界图、协议、来源、状态和验证说明。
known_boundaries:
  - MQ-2 原始 ADC 不是烟雾/燃气/火灾检测，声音幅度不是蜂群健康或行为诊断，气压估算不是天气预报。
  - HTTP、App、CI、构建、Artifact 与固定标签不代表设备在线、安全、告警送达或有人处理。
  - HTTP 无认证和 TLS，只面向隔离可信局域网教学环境。
  - 构建与源码契约不证明 ESP32、DHT11、BH1750、BMP280、ADC、LED、Wi-Fi、HTTP 或 Flutter 端到端行为。
  - Actions Artifact 仅保留 14 天。
```
