<div align="center">

# ZemoteS

> ## ⚠️ 实验性 Fork
> **本仓库是 [HumanAILoop/zemote](https://github.com/HumanAILoop/zemote) 的个人分支**：在上游基础上做**安全加固**（强制 TLS、凭据加密存储、更新校验）与**功能增强**（自动化管理、会话洞察面板、故障自诊断）。
> 不保证功能与稳定性；追求稳定请使用上游原版：[HumanAILoop/zemote](https://github.com/HumanAILoop/zemote)**

**Android / Web 上的 ZCode 远程控制客户端** — 独立复刻官方 Web 远程控制协议（protocol reimplementation）

[![Flutter](https://img.shields.io/badge/Flutter-3.5%2B-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5%2B-0175C2.svg?logo=dart)](https://dart.dev)
[![CI](https://github.com/g0spel/zemote-s/actions/workflows/ci.yml/badge.svg)](https://github.com/g0spel/zemote-s/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/g0spel/zemote-s)](https://github.com/g0spel/zemote-s/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-lightgrey.svg)](#平台)

在手机上**同时管理多台桌面设备**：扫码添加设备 → 连接桌面 ZCode → 任务对话、自动化定时任务、会话洞察（待办/文件/后台）、模型供应商与用量管理。

> ⚠️ 本项目为**协议复刻**，与官方客户端无任何代码关联。请遵守 ZCode 服务条款与当地法律法规，仅用于连接你自己的设备。

</div>

---

## 与原上游的关系

- **来源**：fork 自 [HumanAILoop/zemote](https://github.com/HumanAILoop/zemote)（v0.3.5），协议层完全同源——都是对 zcode.z.ai 远程控制协议的独立复刻，两者可与同一桌面端互换使用。
- **定位**：上游保持原味；本分支面向个人使用做安全加固与功能增强，**不自动跟随上游**（协议变更时人工合并，应用内 `[诊断]` 日志会给出证据与线索）。
- **共存**：包名不同（`dev.g0spel.zemotes` vs 上游 `app.zemote`），可与上游版本并排安装。
- **回流**：分支里的安全修复与 bug 修复欢迎上游取用。

## 与上游能力对比

| 能力 | 上游 zemote | ZemoteS |
|---|:---:|:---:|
| 多设备并发 / 任务管理 / Conversation V4 对话 | ✅ | ✅ |
| 模型供应商 / 用量配额 / 服务管理 | ✅ | ✅（状态语义对齐官方客户端） |
| **自动化页**（定时任务列表/执行历史/启停/新建/编辑/删除，闲时队列） | ❌ | ✅ |
| **会话洞察面板**（待办 TodoWrite / 文件 diff / 后台任务与子代理） | ❌ | ✅ |
| 消息时间戳 / 执行中计时 / 失败摘要通知 | ❌ | ✅ |
| 协议日志导出 / 复制 / 诊断行高亮 | ❌ | ✅ |
| 崩溃本地留痕（下次启动可查） | ❌ | ✅ |
| 强制 https/wss（拒绝明文降级） | ❌（接受 http） | ✅ |
| 凭据加密存储（Android Keystore）+ 关闭云备份 | ❌（明文 SharedPreferences） | ✅ |
| 更新 APK SHA-256 校验 + 断点续传 | ❌ | ✅ |
| 防通知 deep-link 伪造（第三方 App 投递） | ❌ | ✅ |
| 多工作区任务列表隔离 | ❌（存在串区缺陷） | ✅ 已修复 |
| 发布产物 | 三架构 fat APK（~77MB） | arm64 单架构 APK（~38MB） |
| 平台 | Android / Web / Windows | **Android / Web** |

## 平台

| 平台 | 状态 |
|------|------|
| Android（arm64） | ✅ 主要目标平台，Release 发布 |
| Web | ✅ 可用（调试 / 快速预览；凭据保护弱于移动端） |
| 其他 | ❌ 已移除（Windows 目录已删） |

## 快速开始

### 安装（Android）

1. 从 [Releases](https://github.com/g0spel/zemote-s/releases) 下载 `app-release.apk`（arm64）安装；
2. 桌面 ZCode → 远程控制 → 生成二维码；
3. 应用内 **添加设备** → 扫码 → 连接。

> 可与上游 `app.zemote` 并排安装。应用内支持自动更新（下载后先做 SHA-256 校验再安装，支持断点续传）。

### 从源码构建

```bash
flutter pub get

# Android release（arm64 单架构，与发布产物一致）
flutter build apk --release --target-platform android-arm64 --dart-define=APP_VERSION=$(awk -F'[ +]' '/^version:/ {print $2}' pubspec.yaml)

# Web
flutter build web --release

# 本地调试运行
flutter run            # Android
flutter run -d chrome  # Web
```

## 更新与签名

- 启动时自动检查 GitHub 最新 Release；Android 端弹窗 → 下载（断点续传）→ **SHA-256 校验** → 系统安装器升级；缺校验值或校验不过一律拒绝安装。
- 发布流程：改 `pubspec.yaml` 版本（CI 自动注入 `APP_VERSION`）→ 提交 → `git tag vX.Y.Z` → 推送；GitHub Actions 自动测试、构建、签名并上传 APK + `.sha256` 校验文件。
- CI 三方 action 全部钉 commit SHA；release keystore 存于 GitHub Secrets。

## 架构

```
┌────────────────────────────────────────────────────────────┐
│ UI (lib/ui)     设备 / 任务 / 对话 / 自动化 / 设置 / 调试器   │
├────────────────────────────────────────────────────────────┤
│ State (lib/state)  AccountStore · AppSession · LogStore    │
│                   · CrashReport（崩溃留痕）                 │
├────────────────────────────────────────────────────────────┤
│ Facade (lib/protocol/zemote_client.dart)                    │
│   relay → 配对 → bootstrap → workspace-bridge → channel RPC │
├────────────────────────────────────────────────────────────┤
│ Protocol (纯 Dart，可单测)                                  │
│   RelayClient · RpcFrameTransport · ChannelClient           │
│   IpcCodec · Conversation(V4) · Proof(HMAC-SHA256)          │
└────────────────────────────────────────────────────────────┘
```

| 层 | 职责 |
|---|---|
| `connection_params.dart` | 远程控制 URL 解析（仅 https/wss）+ relay 地址 |
| `proof.dart` | 配对证明（HMAC-SHA256 / base64url） |
| `relay_client.dart` | relay WebSocket + 心跳 + 重连 + 协议诊断 |
| `rpc_transport.dart` | rpc-frame 分片/重组/CRC32 校验/ack |
| `ipc_codec.dart` | 值编解码 + IPC 帧解析 |
| `channel_client.dart` | channel RPC 调用/事件订阅 |
| `conversation.dart` | Conversation V4 / sessions-index 快照+增量 |
| `zemote_client.dart` | 高层门面：bootstrap / bridge / 断线恢复 |

## 测试与调试

```bash
flutter test            # 单元测试（协议 / 状态机 / 解析器 / 更新检测）
```

**协议活探针**（对真实桌面，只读）：`live_probe_test.dart` / `automation_cycle_test.dart` 通过环境变量 `ZEMOTE_PROBE_URL` 注入远程控制 URL，无凭据时自动跳过——协议变更排查时用它直接观测真实返回结构。

协议失配自诊断：未知帧类型 / 非 JSON 帧 / 未知关闭码 / 快照解析失败都会在**协议日志页**留下红色 `[诊断]` 行并说明疑似原因，支持导出。

## 安全说明

- 远程控制 URL 包含设备凭据（`sid`/`hash`），**切勿提交或分享**；泄露后在桌面端重新生成二维码即可作废。
- 设备凭据经 flutter_secure_storage（Android Keystore）加密存储，`allowBackup=false` 阻止云备份外带。
- 连接仅接受 `https`/`wss`；添加非官方中继主机的设备前会弹窗确认。
- 更新 APK 必须通过 Release 附带的 SHA-256 校验才会进入安装。

## 项目结构

```
lib/
├── main.dart                 # 入口 + 崩溃捕获 + 启动更新检测
├── protocol/                 # ZCode 协议复刻（纯 Dart，可单测）
├── state/                    # 账号 / 连接 / 日志 / 崩溃留痕
├── notifications/            # 前台通知 + 完成提醒 + 通知跳转
├── ui/                       # 设备 / 任务 / 对话 / 自动化 / 设置 / 调试器
└── update/                   # 更新检测 + 校验 + 断点续传下载
test/                         # 单元测试 + 只读协议探针（需环境变量）
android/                      # Android 平台（包名 dev.g0spel.zemotes）
web/                          # Web 平台
```

## 技术栈

- [Flutter](https://flutter.dev) / Dart
- [web_socket_channel](https://pub.dev/packages/web_socket_channel) — relay 长连接
- [crypto](https://pub.dev/packages/crypto) — HMAC-SHA256 配对证明 / SHA-256 更新校验
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) — 凭据加密存储
- [mobile_scanner](https://pub.dev/packages/mobile_scanner) / [zxing2](https://pub.dev/packages/zxing2) — 扫码
- [image_picker](https://pub.dev/packages/image_picker) / [file_picker](https://pub.dev/packages/file_picker) — 附件与导出
- [flutter_markdown_plus](https://pub.dev/packages/flutter_markdown_plus) — Markdown 渲染
- [http](https://pub.dev/packages/http) — 更新检测（GitHub Releases API）

## 贡献

欢迎 Issue 与 PR：`flutter analyze` 无告警、`flutter test` 全绿；涉及真实桌面的改动请注明探针验证方式。

## Changelog

版本变更记录见 [CHANGELOG.md](CHANGELOG.md)。

## License

[MIT](LICENSE)

## 免责声明

本项目为个人学习与互操作目的，对 ZCode 远程控制协议的独立复刻，非官方出品。使用者须自行承担风险与合规责任。
