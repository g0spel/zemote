<div align="center">

# ZemoteS

> ## ⚠️ 实验性 Fork
> **本仓库是 [HumanAILoop/zemote](https://github.com/HumanAILoop/zemote) 的个人分支**，不保证功能与稳定性；追求稳定请使用上游原版。

**Android / Web 上的 ZCode 远程控制客户端** — 独立复刻官方 Web 远程控制协议(protocol reimplementation)

[![Flutter](https://img.shields.io/badge/Flutter-3.5%2B-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5%2B-0175C2.svg?logo=dart)](https://dart.dev)
[![CI](https://github.com/g0spel/zemote-s/actions/workflows/ci.yml/badge.svg)](https://github.com/g0spel/zemote-s/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/g0spel/zemote-s)](https://github.com/g0spel/zemote-s/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-lightgrey.svg)](#平台)

</div>

---

## 与上游的差异

本分支 fork 自 [HumanAILoop/zemote](https://github.com/HumanAILoop/zemote) v0.3.5,协议层完全同源——两者都是对 zcode.z.ai 远程控制协议的独立复刻,可与同一桌面端互换使用。fork 后的取向不同:上游保持原味;本分支面向个人使用做**安全加固**(强制 TLS、凭据加密存储、更新校验)、**可靠性打磨**(断线自愈、锁屏恢复无感化、崩溃留痕)与**功能增强**(自动化管理、会话洞察面板、用量语义对齐、诊断体系),**不自动跟随上游**——协议变更时人工合并。包名不同(`dev.g0spel.zemotes` vs 上游 `app.zemote`),可与上游版本并排安装;分支里的安全修复与 bug 修复欢迎上游取用。

> ⚠️ 本项目为**协议复刻**,与官方客户端无任何代码关联。请遵守 ZCode 服务条款与当地法律法规,仅用于连接你自己的设备。

## 功能特性

### 多设备管理

- **扫码即连**:扫描桌面 ZCode「远程控制」生成的二维码,或粘贴 URL 添加设备;URL 解析校验后保存,无效地址直接拒绝。
- **多设备并发**:同时管理多台桌面,设备间一键切换;每台设备独立保持连接状态。
- **导入 / 导出**:设备列表可导出为 JSON 备份、从文件恢复,自动跳过无效与重复项。
- **连接状态一眼可见**:已连接 / 连接中 / 重连中 / 异常分色展示;连接失败按原因给出可行动的中文解释(凭据失效 / 桌面离线 / 网络错误 / 配对超时等)。

### 任务列表

- 任务 / 置顶 / 已归档三态管理,支持搜索与未读标记;任务列表由 `zcode-task` 信道与 sessions-index 推送**双源合并**,工作区之间严格隔离(不串区)。
- 任务运行中显示实时计时;完成通知按终态区分「任务完成 / 失败 / 中断」。
- 任务详情页可查看完整快照(标题、状态、回合统计)。

### Conversation V4 对话

- **流式回复**:逐 token 渲染;思考过程、工具调用按真实顺序穿插展示(思考 → 文本 → 工具 → 文本),思考内容**默认展开**、可收起。
- **消息即时回显**:发送被接受立即出现气泡(「发送中…」角标),服务端确认后自动去重;发送失败明确提示原因,不静默。
- **消息时间戳**:实时到达的行显示 HH:mm;打开任务天然定位在最新消息,向上翻阅历史时流式更新不拉扯。
- **完整输入能力**:排队消息(held queue,自动/手动放行)、目标指令(Goal)、图片与文件附件(分片上传、进度显示)、斜杠命令 + 桌面端 Skills(`$` 前缀触发,带选择弹层)。
- **模型与模式**:模型 / 模式 / 思考等级运行中切换;辅助对话(Side Chat)可并行开侧问;会话配置(最大输出、搜索增强等)随 `prepareWorkspace` 展示。
- **交互应答**:AI 向你提问时按官方 schema 渲染权限确认、单选 / 多选表单与自由输入。
- **反馈与回滚**:对回复点赞 / 点踩;「查看文件变更」直达该回合 diff;文件回滚(rewind)支持预览与执行。

### 会话洞察面板

对话页 token 用量条下方的三个折叠面板,数据不齐全时降级为原始 JSON 视图——**数据永远可见**:

- **待办**:镜像桌面宿主的官方推导——从最新 TodoWrite / 计划类工具调用提取待办清单与完成状态。
- **文件**:每回合 +增 −删 · 文件数摘要;**每个回合完成后自动预加载最新 diff**(无需手动刷新),点开单文件渲染 unified diff;协议层内置 stale 自愈重试,流式竞态与协议漂移不再导致查询失败。
- **后台**:后台任务(bash / 子代理)实时状态(运行中 / 待取结果 / 失败 / 已取消)+ **运行中的子代理**(标题、类型、状态、摘要)+ **已结束的子代理列表**(任务摘要 + 已完成 / 失败 / 已取消徽标 + 结束时间)。

### 自动化(定时任务)

- 对接 ZCode 定时任务:`zcode-agent` 通道全循环支持——列表、新建 / 编辑(标题 + Cron + 提示词,内置每周回顾 / 晨会动态 / 风险扫描官方模板)、启停开关、重命名、删除(带确认)。
- 详情页:完整提示词、模型 / 模式、执行历史(时间、触发方式、结果;成功记录可跳转对应会话)。
- 闲时任务队列(`off-peak-task`)只读展示。

### 模型供应商与用量

- **供应商管理**:状态语义对齐官方客户端——已启用 / 已停用(附中文原因:登录失效 / 无订阅资格)/ 未配置;供应商可展开查看模型明细(ID、上下文窗口、最大输出、推理档位)。
- **用量配额**:剩余 MCP 额度(剩余 / 总量 + 进度条)、五小时窗口与每周配额(剩余 ≤20% 变黄、≤10% 变红,附重置时间)、订阅到期与续费时间(按本地时区显示)。

### 服务管理

- 插件 / 技能 / 命令三块只读总览:启用状态彩色徽标、技能全列表(名称 + 描述 + 原始数据)、自定义命令(名称 + 提示词);MCP 区块如实注明远程协议未提供读取接口,请到桌面端管理。

### 通知

- 任务运行中:Android 前台服务常驻通知,实时更新最新进展(节流合并);完成 / 失败 / 中断静默提醒(低优先级,不弹窗)。
- 点击通知直达对应对话;前台期间完全静默,后台按任务活动去重,重连重演的旧边沿不再重复打扰。
- 通知跳转经未导出的 Activity 内存交接,第三方 App 无法伪造 deep-link 注入。

### 连接可靠性

- **三级断线自愈**:relay 出站队列(未配对暂存)→ 桥降级标记 + 命令排队等待恢复(`waitHealthy`)+ 15 次换栈重试(页面无感)→ V4 订阅自动重握手。
- **心跳先探测后断开**:30 秒无应答先补发一次查询,下个周期仍无应答才重连,吸收切后台 / 系统休眠的假性超时;waiting 状态心跳降频。
- **锁屏恢复无感化**:relay 跟踪最后入站帧,回前台探测发现超 25 秒零入站(链路必死)立即重连——解锁后 1~3 秒恢复收发;短暂重连横幅延迟 5 秒显示,全程零打扰,真正的错误立即提示。
- **崩溃留痕**:framework 异常与未捕获异步错误写入本地(单槽覆盖),下次启动在诊断日志提示,设置页可查看完整堆栈、复制、清除。
- 会话冷启动订阅放宽至 60 秒预热,避免误判「连不上」;`sendText` 等命令的 ack 被检查,被拒时提示具体原因,超时仅断线时自动重试一次,不重复投递。

### 安全

- **传输**:仅接受 `https` / `wss`,relay 永远走 `wss://`,杜绝明文降级;添加非官方中继主机的设备前弹窗确认。
- **凭据**:设备凭据经 flutter_secure_storage(Android Keystore)加密存储;`allowBackup=false` 阻止进入系统云备份。
- **更新**:Release 附带 SHA-256 校验文件,应用内更新**先校验再安装**,缺校验值或校验不过一律拒绝;下载走内部目录,FileProvider 仅暴露该子目录;CI 三方 action 全部钉 commit SHA。
- 远程控制 URL 含设备凭据(`sid` / `hash`),泄露后在桌面端重新生成二维码即可作废。

### 诊断与调试

- **诊断日志页**:独立的 `[诊断]` 条目视图——协议失配(未知帧类型 / 非 JSON 帧 / 未知关闭码)、快照解析失败、stale 自愈等故障均以人类可读的中文说明留痕,红色高亮,提示疑似原因与建议动作。
- **协议日志页**:完整 relay / IPC / V4 帧日志(可开关详细帧记录),条目截断与通知合并保证不卡 UI;支持复制全部、导出文件。
- **RPC 调试器**:发送原始 relay payload,按 requestId 匹配响应。
- **信道浏览器**:任意 IPC 信道任意方法调用,协议逆向与排查利器。
- **实机探针**:`live_probe_test` 等只读探针(环境变量注入凭据,无凭据自动跳过),协议变更时直接观测真实返回结构。

### 个性化

- 浅色 / 深色主题(全量主题感知配色)、字体缩放、代码字号调节;中英双语界面。

## 平台

| 平台 | 状态 |
|------|------|
| Android(arm64) | ✅ 主要目标平台,Release 发布 |
| Web | ✅ 可用(调试 / 快速预览;凭据保护弱于移动端) |
| 其他 | ❌ 已移除 |

## 快速开始

### 安装(Android)

1. 从 [Releases](https://github.com/g0spel/zemote-s/releases) 下载 `app-release.apk`(arm64)安装;
2. 桌面 ZCode → 远程控制 → 生成二维码;
3. 应用内 **添加设备** → 扫码 → 连接。

> 可与上游 `app.zemote` 并排安装。应用内支持自动更新(下载后先做 SHA-256 校验再安装,支持断点续传)。

### 从源码构建

```bash
flutter pub get

# Android release(arm64 单架构,与发布产物一致)
flutter build apk --release --target-platform android-arm64 --dart-define=APP_VERSION=$(awk -F'[ +]' '/^version:/ {print $2}' pubspec.yaml)

# Web
flutter build web --release

# 本地调试运行
flutter run            # Android
flutter run -d chrome  # Web
```

## 更新与签名

- 启动时自动检查 GitHub 最新 Release;Android 端弹窗 → 下载(断点续传)→ **SHA-256 校验** → 系统安装器升级。
- 发布流程:改 `pubspec.yaml` 版本(CI 自动注入 `APP_VERSION`)→ 提交 → `git tag vX.Y.Z` → 推送;GitHub Actions 自动测试、构建、签名并上传 APK + `.sha256`。

## 架构

```
┌────────────────────────────────────────────────────────────┐
│ UI (lib/ui)     设备 / 任务 / 对话 / 自动化 / 设置 / 调试器   │
├────────────────────────────────────────────────────────────┤
│ State (lib/state)  AccountStore · AppSession · LogStore    │
│                   · CrashReport(崩溃留痕)                  │
├────────────────────────────────────────────────────────────┤
│ Facade (lib/protocol/zemote_client.dart)                    │
│   relay → 配对 → bootstrap → workspace-bridge → channel RPC │
├────────────────────────────────────────────────────────────┤
│ Protocol (纯 Dart,可单测)                                  │
│   RelayClient · RpcFrameTransport · ChannelClient           │
│   IpcCodec · Conversation(V4) · Proof(HMAC-SHA256)          │
└────────────────────────────────────────────────────────────┘
```

| 层 | 职责 |
|---|---|
| `connection_params.dart` | 远程控制 URL 解析(仅 https/wss)+ relay 地址 |
| `proof.dart` | 配对证明(HMAC-SHA256 / base64url) |
| `relay_client.dart` | relay WebSocket + 心跳 + 重连 + 协议诊断 |
| `rpc_transport.dart` | rpc-frame 分片/重组/CRC32 校验/ack |
| `ipc_codec.dart` | 值编解码 + IPC 帧解析 |
| `channel_client.dart` | channel RPC 调用/事件订阅 |
| `conversation.dart` | Conversation V4 / sessions-index 快照+增量 |
| `zemote_client.dart` | 高层门面:bootstrap / bridge / 断线恢复 |

## 测试与调试

```bash
flutter test            # 单元测试(协议 / 状态机 / 解析器 / 更新检测)
```

协议活探针(对真实桌面,只读):`live_probe_test.dart` / `automation_cycle_test.dart` 通过环境变量 `ZEMOTE_PROBE_URL` 注入远程控制 URL,无凭据时自动跳过——协议变更排查时直接观测真实返回结构。

## 项目结构

```
lib/
├── main.dart                 # 入口 + 崩溃捕获 + 启动更新检测
├── protocol/                 # ZCode 协议复刻(纯 Dart,可单测)
├── state/                    # 账号 / 连接 / 日志 / 崩溃留痕
├── notifications/            # 前台通知 + 完成提醒 + 通知跳转
├── ui/                       # 设备 / 任务 / 对话 / 自动化 / 设置 / 调试器
└── update/                   # 更新检测 + 校验 + 断点续传下载
test/                         # 单元测试 + 只读协议探针(需环境变量)
android/                      # Android 平台(包名 dev.g0spel.zemotes)
web/                          # Web 平台
```

## 技术栈

- [Flutter](https://flutter.dev) / Dart(零状态管理库,`ChangeNotifier` + InheritedWidget)
- [web_socket_channel](https://pub.dev/packages/web_socket_channel) — relay 长连接
- [crypto](https://pub.dev/packages/crypto) — HMAC-SHA256 配对证明 / SHA-256 更新校验
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) — 凭据加密存储
- [mobile_scanner](https://pub.dev/packages/mobile_scanner) / [zxing2](https://pub.dev/packages/zxing2) — 扫码
- [image_picker](https://pub.dev/packages/image_picker) / [file_picker](https://pub.dev/packages/file_picker) — 附件与导出
- [flutter_markdown_plus](https://pub.dev/packages/flutter_markdown_plus) — Markdown 渲染
- [http](https://pub.dev/packages/http) — 更新检测(GitHub Releases API)

## 贡献

欢迎 Issue 与 PR:`flutter analyze` 无告警、`flutter test` 全绿;涉及真实桌面的改动请注明探针验证方式。

## Changelog

版本变更记录见 [CHANGELOG.md](CHANGELOG.md)。

## License

[MIT](LICENSE)

## 免责声明

本项目为个人学习与互操作目的,对 ZCode 远程控制协议的独立复刻,非官方出品。使用者须自行承担风险与合规责任。
