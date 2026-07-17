# 源码来源与权威副本裁决

> 状态日期：2026-07-17

## 只读来源

```text
/home/rongyi/桌面/beehive-monitor
```

该目录不是 Git 工作树；本轮没有发现可作为历史基线的 Git commit 或历史 ZIP。它在本次整理中始终保持只读，公开候选不会反向覆盖、清理或删除原目录。

## 安全来源清点

为避免把任何凭据文件纳入可验证证据，来源 manifest 使用**显式安全 allowlist**，仅清点本次公开候选可追溯的源码与跨平台构建文件。它明确不读取、不哈希、不纳入原始 `firmware/src/config.h`、任何 `wifi_credentials.h`、`local.properties`、生成状态、IDE 文件、交付说明、私网材料或其他可能含本机/凭据内容的文件。

按该安全 allowlist，2026-07-17 的来源有 87 个选定文件，manifest SHA-256 为：

```text
1ed7916764ade5d7d24a564a4ed0b814c478ca1cc2b7c8838b401970ef8fa1d3
```

算法按 UTF-8 相对路径、NUL 分隔符、原文件字节和 NUL 分隔符的排序序列计算 SHA-256。公开的 [`source-allowlist.txt`](source-allowlist.txt) 与 [`scripts/source_manifest.py`](../scripts/source_manifest.py) 可在拥有原始只读来源权限的环境中复算；脚本会拒绝凭据/本机文件进入 allowlist。它只用于来源审计，不是公开仓的构建依赖，也不等于历史版本、照片、EDA 或真机证据。

## 裁决

- 桌面原始目录：本轮的只读源码来源；
- 公开候选：`/home/rongyi/桌面/Hardware Lab-公开仓库/esp32-beehive-monitor`；
- 公开候选：使用全新 Git 历史，不能把原始网络凭据、缓存、本机配置或未知历史带入公开提交；
- 权威范围：公开候选完成门禁、构建、CI 和线上回读后，其精确 `main` commit 才是本仓公开版本的权威记录。

## 可审计公开整理

在不修改来源的前提下，候选：

1. 使用白名单复制固件与 Flutter 源码，排除缓存、IDE 状态、Android `local.properties`、iOS 生成文件、构建物、APK/AAB 和本机路径；
2. 把来源中的真实 Wi-Fi 配置替换为 `wifi_credentials.example.h` 与 Git 忽略的本地 `wifi_credentials.h`，无本地凭据时仍能构建但不联网；
3. 避免在默认串口输出中回显 SSID；任何局域网 IP 仍不得提交、截图或贴入公开材料；
4. 将原有蜂群健康、天气、烟雾/燃气/火灾和“危险/告警”强语义收敛为原始传感器数值与固定演示阈值标签；
5. 删除浏览器不需要的通配 CORS / OPTIONS 路径，并把 HTTP 限定为本地可信局域网教学接口；
6. 补充中文 README、BOM、源码推导接线边界图、协议、状态、验证、安全、许可证、第三方声明、秘密扫描、结构门禁、源码契约与 CI。

这些属于公开前的可审计净化、构建加固和文档整理；它们不代表 ESP32、传感器、Wi-Fi、HTTP、Android/iOS 或 Flutter 客户端已经真机复测。
