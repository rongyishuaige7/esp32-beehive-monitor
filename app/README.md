# Flutter 局域网展示客户端

此目录是“基于ESP32的蜂箱多传感器数据采集与局域网展示原型”的 Flutter 客户端源码。

它只向使用者输入的、受限为 RFC1918 / link-local IPv4 的地址请求固定的 `GET /api/status` 路径，且拒绝 HTTP 重定向；地址仅保存到应用本地 `shared_preferences`；Android 已禁用应用数据备份，界面提供“清除本机测试地址”入口，可随时删除该本地记录。iOS 端当前没有构建/真机验证，本仓不对系统迁移或备份行为作额外承诺。应用没有账号、云端、分析、位置、相机、麦克风或主动上传功能。

客户端和固件均使用无认证、无 TLS 的本地 HTTP，必须只在隔离、可信的教学局域网使用。一次成功响应只表示当次响应可解析，不表示设备在线、持续连接、传感器有效、蜂群状态或安全结论。

```bash
flutter pub get --enforce-lockfile
flutter test
flutter analyze
flutter build apk --debug
```

Android debug APK 仅用于本地开发构建检查；本仓不提供签名发布 APK、iOS 构建证明或真机联调证明。完整协议、状态和安全边界见仓库根目录的 `docs/` 与 `SECURITY.md`。
