# 验证说明

> 状态日期：2026-07-17

## 一键本地门禁

```bash
bash scripts/verify.sh
```

脚本按如下顺序执行：

1. 敏感信息、私钥、真实 Wi-Fi、私网地址、生成物、APK、缓存和未审核二进制扫描；
2. 必需文件、仓库结构、BOM、SVG、状态文案、PlatformIO 固定版本、API/网络边界检查；
3. 不依赖硬件的 Python 源码契约测试；
4. ESP32 PlatformIO 干净构建；
5. `app/` 的 `flutter pub get --enforce-lockfile`、Dart 格式门禁、`flutter test`、`flutter analyze` 与 `flutter build apk --debug`；
6. 清理候选目录内的 Flutter、Gradle 与 PlatformIO 生成物，再进行末次扫描。

它不会烧录 ESP32、连接真实 Wi-Fi、输入真实凭据、调用真实 HTTP、读取真实传感器或判断蜂群、蜂箱、天气、烟雾/燃气、安全或动物健康。

## 已验证环境与结果

2026-07-17 已在**尚未初始化 Git 的隔离公开候选**上完成一次完整本地门禁。该结果还没有可绑定的 commit；首个本地 commit 与 GitHub exact-HEAD Actions 结果会另行补充，不能提前写成线上 CI 或真机验证。

```text
PlatformIO Core: 6.1.19
Flutter: 3.41.2
Dart: 3.11.0
Public-candidate complete local gate: PASS
Python source contracts: 9/9 PASS
ESP32 PlatformIO (esp32dev): PASS
RAM: 26,992 / 327,680 bytes (8.2%)
Flash: 438,361 / 1,310,720 bytes (33.4%)
Flutter tests: PASS (5 tests)
Flutter analyze: PASS (no issues)
Android debug APK build: PASS
Generated-state cleanup and final secret/repository scan: PASS
```

该本地构建不等于签名发布包、Android/iOS 真机、ESP32 真机、Wi-Fi、HTTP、传感器或端到端联调。GitHub Actions 的 exact-HEAD 证据仍待在私有仓推送后取得。

## 当前真机复测清单

后续复测必须记录日期、完整 Git commit、精确 ESP32 板型、Flash、USB 芯片、模块/供电事实及每项通过、失败或未测：

- [ ] 确认 ESP32 开发板、Flash、USB 芯片与稳定低压供电；
- [ ] 确认 DHT11、BH1750、BMP280、声音输入、MQ-2 与 LED 的实际型号、供电、共地和接线；
- [ ] 确认 GPIO34/GPIO35 实际输入电压不超过 3.3 V，并记录分压/电平调理方案；
- [ ] 验证 BH1750/BMP280 的 I²C 地址、上拉、初始化失败与读取失败路径；
- [ ] 无本地凭据时确认不联网、不启动 HTTP、采样循环仍可运行；
- [ ] 使用测试 Wi-Fi 完成 STA，记录实际 IP 但不要公开网络拓扑；
- [ ] 验证 `/api/status`、`OPTIONS` 的 `405`、未知路径的 `404`、断网与重连路径；
- [ ] 用 Android / iOS 真机或明确平台运行 Flutter App，核对地址约束、超时、陈旧/错误状态和一次响应语义；
- [ ] 连续受控运行 30–60 分钟，记录重启、内存、Wi-Fi、API 超时和传感器失效路径；
- [ ] 如补照片、视频或日志，去除 EXIF/GPS、SSID、密码、私网拓扑、MAC、位置、蜂场资料、账号和可识别个人信息。

只有完成日期化、commit 绑定的复测，才能把“当前真机复测未执行”升级为精确、可审计的结论；仍不得把该教学原型扩大为安全、动物健康、天气或生产决策设备。
