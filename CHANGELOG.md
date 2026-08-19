# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [0.7.2] - 2026-08-19

### Fixed
基于对桌面宿主源码（zcode.cjs）的逆向与真实设备探针验证，三个面板全部按官方契约重写：
- **待办**：不再调 `conversationPlansV4`（那是"计划模式"接口，与待办无关，恒为空）。改为镜像桌面宿主的官方推导：取最新一条工具名匹配 `todo read/write / update_plan` 的 toolCall 行，解析其 input/output（含 JSON 字符串）中的 `todos/plan/steps/items`，状态归一化 `pending/in_progress/completed`，全有或全无。真机验证：在含待办的任务中正确提取 5 条待办及状态。
- **文件**：`conversationFileChangesV4` 的正确契约是 `target=turnHeader行的{rowId, entityId}` + 必填 `baseRevision` + `baseLogEpoch`（此前缺后两者、target 传错行类型，被 Zod 与守卫双重拒绝）。真机验证调用成功；diff 渲染支持真实返回的 `items[].patches[].lines` unified diff 结构。长按消息的"查看文件变更"菜单同样修复（按 turnId 解析回合头）。
- **后台**：`backgroundWorks` 状态枚举实为 `running/resultPending/failed/cancelled`（无 completed），分别映射 转圈/待取结果/失败/已取消 图标与后缀；子代理状态改用快照 `subagents.running[]`（title/subagentType/status/summary/startedAt，枚举 running/waiting/blocked）并显示 `endedTotal`，行内 subagent 行仅作旧流降级。
- 新增 `test/live_probe_test.dart` 只读探针（环境变量注入凭据，无凭据自动跳过），作为协议变更时的诊断工具。

## [0.7.1] - 2026-08-19

### Fixed
- 文件面板报 `ChannelRpcError: {}`：`conversationFileChangesV4` 的 target 应传文本行（userInput/assistantText）的 `{rowId, entityId}`（与官方客户端长按菜单一致），此前误传了 turnHeader 行被服务端拒绝。现取会话最后一条文本行。
- RPC 错误信息现在完整渲染 message 与 data（此前空 message 只显示 `{}`）。
- 待办解析增强：支持单计划包裹（`plan/currentPlan/activePlan`）与"计划列表→内嵌 todos"的一层展开；完成态识别增加 `checked/isDone` 字段。

## [0.7.0] - 2026-08-19

### Added
- 任务对话页 token 计量条下方新增三个折叠面板（默认收起，点开互斥展开）：
  - **待办**：`conversationPlansV4` 拉取当前待办/计划，勾选状态 + 内容列表，可手动刷新；
  - **文件**：最近各回合变更摘要（+增 −删 · 文件数），并对最新回合调 `conversationFileChangesV4` 列出文件明细（路径 + 增删），点单个文件弹出 DiffView 渲染 diff（支持 structuredPatch 与 unified-diff 字符串）；
  - **后台**：backgroundWorks 全列表（运行中转圈、已结束显示结束时间）+ 会话内 subagent 行（类型/状态/摘要）。
  面板对未知数据结构做容错：认得出就结构化渲染，认不出降级为等宽 JSON 视图，数据永远可见。

## [0.6.1] - 2026-08-19

### Fixed
- 消息时间戳实际不显示：协议的快照（初始加载与重同步）会整体替换行列表，把实时到达时打上的时间标记一并抹掉。现在快照替换时按 rowId 携带原标记，历史行仍不显示时间。时间标签字号 9→10 提高可见性。

## [0.6.0] - 2026-08-19

### Fixed
- 工作区任务列表不再混入其他工作区任务：全局 `workspace-list-updated` 事件降级为"只更新本页已知任务、绝不引入新 taskId"（新任务一律由按工作区隔离的 sessions-index 推送引入，后者此前反而不被允许）。
- 通知不再重复弹出：应用前台期间完全静默完成通知；后台按任务的 `lastActivityAt` 去重，重连快照重演的旧边沿不再触发。
- 协议日志页卡顿/无响应：日志条目截断至 1500 字符（带标记），监听通知合并为至多每 250ms 一次；流式期间的整页重建频率与单行排版开销大幅下降。

### Added
- "本轮执行中"横幅显示实时计时（优先用协议的 activeMs，缺省用本地秒表每秒跳动；重新打开已运行任务从打开时刻起计）。
- 消息时间戳：发送与实时收到的行在到达时打本地时间戳，气泡角落显示 HH:mm；历史快照行无时间可显示（协议不提供消息级时间戳）。
- 任务失败自解释：完成通知按终态区分"任务完成/任务失败/任务中断"；聊天页"本轮失败"横幅附带该轮首个报错工具调用的摘要（最多 160 字符）。

## [0.5.2] - 2026-08-19

### Added
- 崩溃本地留痕：framework 异常与未捕获异步错误写入应用数据目录（`last_crash.json`，单槽覆盖，超长堆栈截断），下次启动在协议日志记 `[诊断]` 提示；设置页新增"上次崩溃"卡片，可查看时间/类型/版本/堆栈全文、复制、清除。Web 端不落盘。

## [0.5.1] - 2026-08-19

### Fixed
- 打开任务现在定位在最新消息：消息列表改为 reverse 布局（偏移 0 即最新一条），打开时天然处于底部，不再依赖"打开后补一次滚动"的时序（原实现在初始快照与自动加载历史交错时会停在最早消息）。
- 依赖置换：`flutter_markdown` → `flutter_markdown_plus`（上游停止维护的接续版），`flutter_lints` 6。

## [0.5.0] - 2026-08-19

### Added
- 更新下载支持断点续传（Range/206，弱网中断不再整包重下）。
- 协议日志页：复制全部 / 导出为文件；条目重新排版（时间戳与内容分色分行、条目间留白）；`[诊断]` 行红色加粗高亮。
- 故障自诊断：relay 未知帧类型 / 非 JSON 帧 / 未知关闭码 / 配对挑战缺 nonce / 会话逻辑帧解析失败，均记 `[诊断]` 说明并疑似协议变更时提示导出日志；连接失败按原因给出中文解释与建议动作（凭据失效 / 桌面离线 / 网络错误 / 配对超时等），配对失败立即以真实原因中断而非等待超时。
- Dependabot 每月自动依赖 PR（pub + github-actions）。

### Changed
- 发布产物改为 arm64 单架构 APK（约 25MB，原 77MB 三架构 fat 包）。
- 版本号单一来源：CI 从 pubspec.yaml 提取并 `--dart-define=APP_VERSION` 注入，发版只改 pubspec + 打 tag。
- 无法解析的 URL 直接拒绝保存（不再"仍已保存"）；扫码入口同样校验。
- Android Gradle Plugin 8.13.2 → 9.0.1。
- CI 新增 web 编译冒烟（拦住 analyze 无法发现的依赖 API 破坏）。
- README 顶部注明本 fork 为实验项目，日常使用请选上游。

## [0.4.0] - 2026-08-19

fork 首个版本：安全加固（基于对上游 0.3.5 的审计）。包名改为 `dev.g0spel.zemote`，可与上游版本共存安装；minSdk 跟随 Flutter 稳定版要求为 24（放弃 Android 6 及以下）。

### Security
- 连接 URL 仅接受 `https`/`wss`，relay 永远走 `wss://`，杜绝 `ws://` 明文降级（网络中间人可读取/篡改会话）。
- 添加非 `zcode.z.ai` 主机的设备前弹窗确认，防止被调换的二维码把对话内容静默送往第三方服务器。
- 设备凭据改用 flutter_secure_storage（Android Keystore）加密存储，不再明文写入 SharedPreferences；`android:allowBackup="false"` 阻止凭据进入系统云备份。
- CI 三方 action 全部钉 commit SHA；Release 附带 `app-release.apk.sha256`；应用内更新下载后先做 SHA-256 校验，校验不过拒绝安装、缺少校验值只提示手动下载。
- 通知点击改经未导出的 `NotificationTapActivity` 内存交接 payload，其他应用无法再通过 exported 启动器伪造 deep-link。
- 更新 APK 下载到内部 `filesDir/update/`（原为外部应用目录），FileProvider 仅暴露该子目录。
- 更新源指向本 fork（`g0spel/zemote`）的 GitHub Releases；手动 dispatch 只构建不发布。

## [0.3.5] - 2026-08-07

### Fixed
- 会话首次订阅（冷启动运行预热）放宽至 60s，避免打开聊天/恢复时超时误判「连不上」。
- relay 心跳超时触发重连时正确触发 bridge 恢复（此前跳过 `reconnecting` 状态导致配对后 bridge 不恢复）。
- 打开聊天页显式定位到最新消息（此前监听器错过初始快照）。
- 气泡保留原始顺序（思考→文本→工具→文本…），点赞区只在回复最后一个文本段显示一次。

## [0.3.4] - 2026-08-07

### Fixed
- **气泡内容顺序错误**：思考过程/工具调用与总结顺序被颠倒。已改为保留原始顺序（思考 → 文本 → 工具 → 文本…），连续文本合并，点赞区只在回复最后一个文本段显示一次。
- 打开聊天页时定位到最新消息（底部）；向上翻阅历史时流式更新不再拉扯；加载更早消息后若在底部自动回到最新。

## [0.3.3] - 2026-08-07

### Added
- **设备列表导入/导出**：导出全部设备（JSON 文件，含连接 URL，带凭据安全提示）；可从文件导入，自动跳过无效/重复设备。
- **同一条回复合并为单条气泡**：交错 tool/reasoning 时文本合并为一个气泡（一个点赞区）。

### Fixed
- 服务端 `bridge-degraded` 恢复失败不再卡死（并入重试循环）。
- `sendText` 在连接健康时超时不再重复发送（仅断线中自动重试）。
- `ZemoteClient.dispose()` 释放活动桥，修复连接泄漏。
- 断线重连：bridge 恢复持续重试直到成功；relay 重连后卡在 waiting 自动强制重连；聊天页显示「正在自动重连」提示条。
- 聊天配色（浅色主题代码块/推理/工具卡片）改为主题感知。
- AI 询问用户（交互）按官方 schema 修正权限选项与自由输入，新增 `questions` 表单。
- 新建会话首条消息随 `createSession(firstInput)` 发送，发送 ack 失败有明确提示。

## [0.3.2] - 2026-08-07

### Fixed
- **断线后发消息超时**：relay 断开时立即标记 bridge 降级，命令在恢复前排队等待（`waitHealthy`）；发送超时后等待重连并自动重试一次；聊天页新增「正在自动重连」提示条。
- **聊天配色异常（尤其浅色主题代码块）**：markdown 代码块/行内代码/推理与工具卡片背景改为主题感知色，浅色下不再白底白字。
- **同一条回复被拆成多条消息**：会话分组不再因服务端 `turnId` 中途变化而拆散，一条回复合并为单条气泡（一个点赞区）。
- **AI 询问用户（交互）弹窗显示不正确**：按官方 schema 修正权限请求选项、自由输入；新增 `questions` 表单渲染（单选/多选）。

## [0.3.1] - 2026-08-07

### Fixed
- **新建会话首条消息可能发不出去**：普通文本首条消息改为随 `createSession(firstInput)` 一起发送（对齐官方 composer），避免订阅未就绪时命令被丢弃；附件/目标指令路径在发送前等待订阅建立。
- **发送失败不再静默**：`sendText` / `sendGoalCommand` 的 ack 现在会被检查，被拒时提示具体原因。

## [0.3.0] - 2026-08-07

### Added
- **后台任务通知（Android）**：任务运行中时，通知栏静默常驻并实时更新最新进展（前台服务保活）；任务完成静默提醒（低优先级、不弹窗）；点击通知直达对应对话。

## [0.2.1] - 2026-08-06

### Added
- **Skills 支持**：通过 `skills.list` channel 拉取桌面端 Skills，合并进斜杠命令列表（`$` 前缀触发）；新增「选择 Skills」底部弹层，一键填入 `$skillname`。
- **统一 Release 签名**：引入正式 keystore，本地与 CI（GitHub Secrets）使用同一签名，APK 可覆盖安装、支持持续升级。

### Changed
- 输入框：Enter 改为换行，仅通过发送按钮发送；缩短提示文案避免变形。
- 设置页：主题/语言切换按钮改为紧凑小字号，避免变形；新增「检查更新」入口与当前版本展示。
- 状态点颜色改为主题感知，浅色主题下不再不可见。

### Fixed
- 浅色主题下部分文本/图标配色不可读的问题（全面改用主题感知的 `ZInk` 配色）。

## [0.2.0] - 2026-08-05

### Added
- **辅助对话（Side Chat）**：`createSelectionSideSession` 协议支持 + 对话页入口，可开启独立侧对话并行提问。
- **更新检测**：启动自动检查 GitHub 最新发布；Android 端可下载 APK 并调用系统安装器升级（设置页含手动入口）。
- 协议字段扩展：`sendText` / `sendGoalCommand` / `createSession` 新增 `automationId`、`offPeakTaskId`、`botDeliveryTarget`、`runtimeModel`、`mcpServers` 等；sessions-index 新增 `parentSessionId`。
- 对话页展示 `prepareWorkspace` 中的其他配置项（如最大输出长度、搜索增强）。

### Changed
- 设备身份改为真实值（`platform` / `name`），不再伪装为浏览器。
- 版本号升至 `0.2.0+1`。

## [0.1.0] - 2026-08-04

### Added
- 首个发布版本：ZCode 桌面端移动远程控制客户端（协议复刻）。
- 多设备并发连接、扫码/粘贴添加设备。
- 任务列表（任务/置顶/已归档 + 搜索 + 未读标记）。
- Conversation V4 对话：流式回复、推理过程、斜杠命令、模型/模式/思考切换、排队消息、目标指令、附件、diff、回滚、反馈。
- 模型供应商管理、用量/配额/订阅查看。
- 协议调试工具（日志 / RPC / Channel）。
- 浅色/深色主题、字体缩放、中英双语。
