<!-- =============================================================================
HYDRA-UMC-DSI - Native touch UI for the CM5 DSI screen
Copyright (C) JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
GPL-3.0-or-later - see LICENSE
============================================================================= -->

<p align="center">
  <img src="images/HYDRA_UMC_BANNER.svg" alt="HYDRA-UMC-DSI banner" width="100%">
</p>

# 🖥️ HYDRA-UMC-DSI

<p align="center"><a href="README.md">🇺🇸 English</a> | <a href="README_spa.md">🇪🇸 Español</a> | <a href="README_fra.md">🇫🇷 Français</a> | <a href="README_ita.md">🇮🇹 Italiano</a> | <a href="README_deu.md">🇩🇪 Deutsch</a> | 🇨🇳 <b>简体中文</b> | <a href="README_jpn.md">🇯🇵 日本語</a> | <a href="README_por.md">🇵🇹 Português</a></p>

### 面向 Compute Module 5 DSI 屏幕的原生触控界面

<p align="center">
  <img src="https://img.shields.io/badge/License-GPL%203.0--or--later-blue.svg" alt="GPL 3.0 or later">
  <img src="https://img.shields.io/badge/Framework-Flutter%203.x-02569B.svg" alt="Framework">
  <img src="https://img.shields.io/badge/Language-Dart-0175C2.svg" alt="Language">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20CM5-E34F26.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Tests-208%20passing-2ea44f.svg" alt="Tests">
  <img src="https://img.shields.io/badge/Version-0.2.8-0f6cbd.svg" alt="Version">
  <img src="https://img.shields.io/badge/Maturity-functional-0F6CBD.svg" alt="Maturity">
</p>

---

一个原生的 Flutter 触控界面（Dart，真实的 Linux 桌面目标），面向 HYDRA-UMC 自身在 Compute Module 5 上的 5"/7" DSI 触摸屏——两种物理面板尺寸共享完全相同的 1280x720 像素分辨率，因此本应用采用一种固定的、非自适应的布局，而不是针对两种尺寸做响应式适配。它使用与 [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)、[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) 和 [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) 完全相同的 [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-SERVER/blob/main/docs/REMOTE_API.md) 契约——发现、登录、原子化的逐机器人指令，以及针对运行中的 [HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER) 服务器的实时 WebSocket 同步,直接在主板本身上运行,而非通过浏览器标签页。完整设计参见 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md),包括为何选择 Flutter（而非 Kivy）以及为何 3D 界面不是一个 WebView。

**本应用是同一块主板上并存的两个控制界面之一**——CM5 同时驱动一个 HDMI 输出,供运行浏览器界面的完整外接显示器使用。这个 DSI 应用与该路径互为补充,在主板本身提供一个直接的、常开的触控控制台;它并不取代浏览器界面。

---

**诚实核查 - 今天真正能运行的部分：** 网络层(`lib/network/hydra_api_client.dart`、`hydra_websocket.dart`、`discovery.dart`、`auth_prefs.dart`)和状态层(`lib/state/robot_view_model.dart`、`hydra_error.dart`)都是真实的并经过测试(`test/*.dart` 中 208 个测试全部通过，其中包括针对一个真实本地服务器、而非模拟对象的真实 WebSocket 连接/重连/认证拒绝往返测试),且 `flutter analyze` 没有报告任何问题。目录中的全部 6 个界面都是真实接线好的 UI，而非占位符。真正尚未构建的部分：**3D View** 界面只是一个小型的原生等距 X/Y/Z 指示器，并非真正的 3D 渲染器 - 它并未嵌入 STUDIO 的真实 Three.js 场景(因为不存在 Linux 版本的 `webview_flutter` 实现)。真实但尚未在目标硬件上验证的部分：`flutter build linux --release` 已经运行过，并生成了一个确认可以启动的二进制文件，但仅在 Ubuntu 24.04 WSL2(x86_64)环境下验证过 - 从未在 CM5 真实的 aarch64 Raspberry Pi OS 上运行过；`kiosk/hydra-umc-dsi.service` 自启动单元也从未在任何真实 Linux 机器上运行过。具体已交付的内容请见下方的 "Known Follow-ups" 和 `CHANGELOG.md`。

> **安全与安防现状:**本生态系统不是经认证的安全系统。目前尚无硬件 E-STOP 通路,没有由固件强制执行的限位或联锁,也没有经过验证的运动指令;固件映像使用 CRC-32 和 Ed25519 签名校验,发布构建会拒绝已公开的开发密钥(中继之后的工具头和扩展板仍运行 URTC 的引导程序,它们使用共享密钥的 HMAC-SHA256 而不是签名);TLS 与双向 TLS 均为可选项,默认关闭;自制电路板尚未组装或测试。在依赖此处任何说法来保障人身安全之前,请先阅读[安全基线](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/SECURITY_BASELINE.md)和[威胁模型](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/THREAT_MODEL.md)。

---

## 📋 速览

| | |
|---|---|
| 版本 | `0.2.8` |
| 成熟度 | 可用 |
| 测试 | 208 (`flutter test`) |
| 技术栈 | Flutter 3.x / Dart |
| 目标 | HYDRA-UMC 工作单元的 Raspberry Pi CM5 |
| 真实硬件 | 尚未：此版本没有在真实硬件上运行的记录 |

**跳转：** [概述](#-概述) · [架构](#-架构) · [快速开始](#-快速开始) · [测试](#-测试) · [仓库结构](#-仓库结构) · [相关项目](#-相关项目)

## 🚦 项目状态

每一行是本仓库的一个部分，灯号表示它今天做到了哪一步。内容依据仓库能够展示的证据（测试、构建、运行），而不是计划。

🟢 已完成并验证 · 🟡 可用，有已知限制 · 🟠 部分完成或尚未验证 · 🔴 未完成或不可用

| 领域 | 状态 | 在这里的含义 |
|---|---|---|
| 软件 | 🟡 | 主要用途可用；上面的诚实性检查列出了仍然缺少的内容 |
| 测试 | 🟢 | 208 项自动测试，每次变更都会运行 |
| 真实硬件 | 🔴 | 尚未：此版本没有在真实硬件上运行的记录 |
| 文档 | 🟢 | 八种语言的 README，每次变更都会与清单核对 |

## 🎯 概述

- **登录**（`lib/ui/login_screen.dart`、`lib/state/robot_view_model.dart`）—— 服务器 IP/端口字段预填了合理的局域网默认值,用户名/密码字段面向触控设计,默认留空（不预填任何硬编码凭据——一旦每台服务器在真实生产环境首次启动时不再自动创建该默认账户,最初的 `admin`/`admin` 预填就被移除了）,`POST /api/login` 针对操作员实际输入的账户;可从浏览器界面的 Config > Users 中创建额外的低权限“操作员”账户。会话令牌保存在平台的安全存储中（Linux 上为 libsecret，需要正在运行的密钥环服务；没有它的面板上，会话只持续到应用重新启动，之后会再次要求登录）。一个“扫描本地网络”对话框（`lib/network/discovery.dart`）无需预先知道 IP 即可找到服务器——这在这里尤其有用,因为本应用运行所在的 CM5,往往正是它应该连接的那个控制器本身。
- **网络发现**（`lib/network/discovery.dart`）—— 两条路径从同一个“扫描本地网络”对话框并行运行:真实的 mDNS/Bonjour（`discoverMdns()`，通过 `multicast_dns` 包查询 `server.ts` 自身发布的 `_hydra._tcp`）,以及针对本设备自身真实本地子网的并发暴力扫描 `GET /api/hydra-info`（`scanSubnets()`）,按 host:port 去重——从 HYDRA-UMC-IOS-CONTROL 移植而来,后者是本生态系统中第一个加入真实 mDNS 发现的客户端。
- **原子化指令同步**（`lib/state/robot_view_model.dart` 自身的 `_sendAtomicCommand()`）—— 每一次写入（播放/暂停/停止/点动/阀门/泵/速度/视觉）都使用真实的 `POST /api/robot/:id/command` 端点,具备正确的合并机器人（`combinedWith`）传播机制,并在请求失败时回滚到变更前的快照——这对于距离真实机器人仅几英尺远的点动手柄/紧急停止尤为重要。
- **实时 WebSocket 同步**（`lib/network/hydra_websocket.dart`）—— 以 `hydra.bearer` 子协议发送令牌（不放入地址），同时处理 `"settings"` 和 `"delta"` 两种广播类型,断线后自动重连。
- **水平触控导航**（`lib/ui/main_screen.dart`）—— 在固定的 1280px 宽度上,一条常驻的顶部栏包含 6 个大图标+标签选项卡（仪表盘/控制/摄像头/3D 视图/指标/设置）,精神上更接近 KlipperScreen,而非手机式的底部导航栏——匹配项目所有者所要求的目录,并针对宽幅触控面板而非纵向手机布局进行了重新组织。
- **仪表盘**（`lib/ui/dashboard_screen.dart`）—— 每机器人卡片,通过 `Provider` 实时响应,LED 惯例（绿色脉冲=活动,红色常亮=非活动）,合并机器人显示,以及模块芯片（CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK）——与本生态系统中其他每一个客户端相同的视觉语言。
- **手动控制**（`lib/ui/control_screen.dart`、`lib/ui/widgets/joystick_pad.dart`）—— 并排布局（点动面板在左,遥测/速度/IO 在右）,针对 1280x720 画面而设计,而非单列滚动布局,全局 **STOP**（`lib/ui/widgets/stop_all.dart`）固定显示在每个标签页的顶部栏、控制标签页和屏幕清洁覆盖层中：只需轻触一次，无需长按也无需确认，即可停止所有机器人（`POST /api/stop-all`），按机器人逐个显示结果（有机器人失败或停止未保存时给出警告，被其他账户预约的机器人会被标出），网络错误时重试一次，遇到 429 或较旧的服务器时改用逐个机器人停止，并保留“STOP 未确认”横幅，直到之后的某次 STOP 得到应答（圆形的单机器人停止按钮保留长按保护）,速度/加速度滑块,阀门/泵开关。
- **预留与安全限值**（`lib/ui/widgets/access_panel.dart`、`lib/models/access.dart`、`lib/network/hydra_api_client.dart`、`lib/state/robot_view_model.dart`）- Control 屏幕显示谁持有所选机器人（无人、本手机、同一账户的另一台设备，或其他账户），提供**预留**和**释放**，并列出服务器上的所有预留（`GET /api/claims`）。设备为每次安装保存一个控制器 ID，并在每次预留、释放、点动解锁和指令中发送（请求体和 `X-Controller-Id` 头），因此预留属于账户和这台设备，而不是整个账户。服务器的拒绝会被区分：被其他账户预留、被你的账户在另一台设备或窗口预留、需要控制器 ID、点动未解锁。机器人型号的限值从 `GET /api/safety-limits` 读取：超过限值的点动步长不会发送，并显示服务器的警告。当管理员要求时，必须先按**解锁点动**（带倒计时），摇杆才会移动机器人；解锁会自动结束，也会在按下 STOP 或释放时结束。预留是可选的：没人预留的机器人照常控制。 仅**管理员**会在他人持有的机器人上看到 **接管控制** 按钮；点击后先要求确认，然后以 `force: true` 预约该机器人（服务器只接受管理员的此请求，并会再次检查角色）。 写入是有条件的:每次写入都带有此应用最后看到的机器人修订号(`If-Match`,`lib/models/contract_v2.dart`),如果期间有其他人修改了机器人,服务器返回 412,不会应用任何内容,机器人会被重新读取并给出提示(标准模式检查预约、工作台和一次性命令;严格模式检查除 STOP 外的全部命令;关闭则不检查;该选项位于预约列表中;STOP 永远不检查)。XY 工作台的点动是一条原子的 `table` 命令(较旧的服务器会收到它能理解的点动),服务器通过 WebSocket 推送预约,因此在推送到达期间 Control 屏幕不再轮询,管理员可以读取审计记录(`lib/ui/widgets/audit_dialog.dart`),其 SHA-256 链由服务器和电脑各校验一次,并可将各行以 `.jsonl` 复制。
- **PLAY 之前先确认** - 默认开启,可在设置中关闭:开始轨迹之前,应用会显示机器人、已记录的点、速度以及预留者(被他人预留的机器人会提示服务器将拒绝该命令)。已在播放的机器人不会再次询问。该选择会被保存。
- **摄像头**（`lib/ui/camera_screen.dart`、`lib/ui/widgets/mjpeg_view.dart`）—— 与 HYDRA-UMC-IOS-CONTROL 相同的手写、无依赖 MJPEG 流解析器（没有 WebView,没有平台特定代码——在 Linux 桌面上原样即可运行）,一个明确的“摄像头已禁用”状态,以及一个可直接从服务器打开/关闭机器人视觉系统的开关。
- **3D 视图**（`lib/ui/three_d_screen.dart`）—— **并非**像 iOS/Android 应用那样嵌入 STUDIO 真实 Three.js 场景的 WebView——`webview_flutter` 在 Linux 桌面上根本没有实现,而完整的浏览器引擎对这块低功耗嵌入式面板而言是过重的运行时负担。取而代之的是:一个小型的原生等距 X/Y/Z 位置指示器（`CustomPainter`,不涉及 3D 引擎）,并附有一条屏幕提示,指向本主板自身通过 HDMI 连接的显示器上的真实 3D 场景。完整推理见 `docs/ARCHITECTURE.md` 第 4 节。
- **系统指标**（`lib/ui/metrics_screen.dart`）—— 拥有自己专属的选项卡（不像 iOS/Android 那样折叠进仪表盘中）,包含来自 `GET /api/system/metrics` 的 CPU/内存/温度/运行时间图块,以及来自 `GET /api/hydra-info` 的主机名/控制器数量/机器人数量/应用版本。
- **设置**（`lib/ui/settings_screen.dart`）—— 连接信息、服务器身份、退出登录,以及本应用自身的版本（见下文[版本管理](#版本管理)）。
- **看板自启动**（`kiosk/hydra-umc-dsi.service`、`kiosk/install_kiosk.sh`）—— 一个 systemd 单元,通过 `cage` 在 `tty1` 上全屏启动本应用,`Restart=always`。详见下文”在真实 CM5 上运行”。同一时间只使用一块本地屏幕：只有当设置 `HYDRA_LOCAL_SCREEN` 为 `dsi` 时安装程序才会安装本应用（`sudo kiosk/install_kiosk.sh --screen dsi` 会将其保存到 `/etc/hydra-umc/local-screen.conf`）；默认值为 `hdmi`，即 HYDRA-UMC-OS 的 HDMI 看板，`none` 则不把 `tty1` 交给任何一方，因此两个看板不会同时占用 `tty1`。尚未在真实的 CM5 上运行。
- **8 语言界面**（`lib/l10n/`，标准的 `flutter gen-l10n` 流程）—— 英语、西班牙语、法语、德语、意大利语、日语、中文和葡萄牙语，与本生态系统的其他客户端保持一致。`设置 > 语言` 中的持久化设置默认跟随系统语言；`RobotViewModel.lastError` 现在是带类型的 `HydraError`，而不是预先格式化好的英文文本，因此业务逻辑层的错误提示也能正确本地化，而不只是界面上的静态文本。

**状态:雏形 + 全部 6 个目录界面均已实现并连接到真实的 REMOTE_API.md 契约。** `flutter analyze` 干净通过,`flutter build windows` 与 `flutter build linux`(通过 WSL2)都能生成可运行的二进制文件,`flutter test` 通过——具体哪些已经验证、哪些还没有,包括这次 WSL2 验证与真实 CM5 硬件之间仍存在的差距,详见下文“构建”。

**一次只用一个本地屏幕、谁在连接以及服务器的访问选项。** 只有当设置 `HYDRA_LOCAL_SCREEN` 为 `dsi` 时，展示终端安装程序才会安装该应用（`sudo kiosk/install_kiosk.sh --screen dsi` 会把它保存到 `/etc/hydra-umc/local-screen.conf`）；默认值是 HYDRA-UMC-OS 的 HDMI 展示终端 `hdmi`，`none` 则不把控制台交给任何一方，因此两个展示终端不会同时抢占 `tty1`（`tools/verify_kiosk_screen.py` 用桩程序测试；未在 CM5 上运行）。访问面板中的“连接”按钮会打开一个简单列表，列出服务器见过的应用以及最近的登录、被拒绝的登录、登出和已结束的会话（管理员能看到全部条目，其他账号只能看到自己的；没有密码或令牌，只有服务器保存地址时才会显示地址）。对管理员，第二个按钮会打开九个从服务器配置读取的开关（无需登录的健康检查路由、全局停止的通告、保留客户端地址、无需票据的摄像头画面、WebSocket 地址中的令牌、遮蔽日志中的机密、语音确认的签名、通过环境交给进程的 IP 摄像头密码、新安装的 TLS）；每个开关都显示其值的来源，只发送发生变化的部分，凡是降低保护的更改都会先询问。文字提供八种语言。

## 🧩 在 HYDRA-UMC 中的角色

**HYDRA-UMC-DSI** 是 CM5 自带的触摸屏：一个面向 5"/7" DSI 面板的原生 Flutter 应用，通过 REST 和 WebSocket 与 `HYDRA-UMC-SERVER` 通信，与 `HYDRA-UMC-STUDIO` 的浏览器界面并存。它没有自己的机器人逻辑；允许什么由服务器决定。

## 🏛️ 架构

<p align="center">
  <img src="images/architecture.svg" alt="HYDRA-UMC-DSI architecture" width="100%">
</p>

## 🚀 快速开始

需要支持 Linux 桌面的稳定版 Flutter SDK（3.x）。

```bash
flutter pub get
./run_dev.sh      # desktop simulation, no hardware (run_dev.bat on Windows)
./build_linux.sh  # on a Linux machine or the CM5: the real target
```

## 🧪 测试

运行 `flutter test` 会执行 208 个自动测试。 不需要硬件，也不需要这台机器以外的任何东西。

CI 运行 `HYDRA_UMC_CI=1 python tools/ci_validate.py`，检查清单、文档、八个 README 和图片。

## 🏗️ 构建与发布

需要 [Flutter SDK](https://docs.flutter.dev/get-started/install)（stable 渠道）。本仓库基于 Flutter 3.47.0 构建/验证。本仓库中只配置了 `linux/` 和 `windows/` 两个平台（没有 `android/`、`ios/`、`web/` 或 `macos/` 文件夹）——Linux 是真正的目标平台（CM5 自身的操作系统）;Windows 的存在纯粹是为了让本应用自身的逻辑能够在没有 Linux 工具链的机器上构建、运行和测试。

### 构建脚本

```bash
./build.sh          # Git Bash / WSL，或使用 build.bat 用于 cmd/PowerShell —— flutter pub get + flutter build windows（开发机验证）
./build_linux.sh    # 必须在真实的 Linux 机器上运行（或 CM5 本身）—— flutter pub get + flutter build linux（真正的部署目标）
./run_dev.sh         # Git Bash / WSL，或使用 run_dev.bat 用于 cmd/PowerShell —— 桌面模拟模式（flutter run），无需硬件
```

全部 3 个构建脚本（`build.sh`/`build.bat`/`build_linux.sh`）都不会更改应用的版本号——见下文[版本管理](#版本管理)。`run_dev.sh`/`run_dev.bat` 不会——在该策略下,开发循环中的 `flutter run` 不算“真正的构建”。

### 手动构建

```bash
flutter pub get
flutter analyze                  # 静态分析——无需编译器
flutter test                     # 组件测试
dart run tool/bump_version.dart  # 递增版本号，与 build.sh/build.bat/build_linux.sh 所做的相同
flutter build windows            # 开发机冒烟测试——生成 build/windows/x64/runner/Release/hydra_umc_dsi.exe
flutter build linux              # 真正的目标平台——必须在真实的 Linux 机器上运行，生成 build/linux/*/release/bundle/
flutter run -d windows           # 或在真实 Linux 机器上使用 -d linux，用于实时桌面模拟开发循环
```

**关于 Linux 验证的诚实说明：** `flutter build linux --release` 现在已经真正针对这份代码运行过了,来自一个真实的 Ubuntu 24.04 WSL2 环境,配备真实的 Linux 桌面工具链(`cmake`、`ninja-build`、`libgtk-3-dev`、`clang`)——干净构建成功,生成了一个真实的 `build/linux/x64/release/bundle/hydra_umc_dsi`,并确认它确实能够启动(在真实的 X11 显示环境下运行并保持存活,而不只是退出码为 0),而不再只是用 `flutter build windows` 作为冒烟测试替代方案。这次验证**没有**覆盖的部分:WSL2 的用户空间是 x86_64,并非 CM5 真实的 aarch64 树莓派操作系统,而且 `kiosk/hydra-umc-dsi.service` 的自启动流程仍然从未在任何真实 Linux 主机上运行过。具体哪些已验证、哪些未验证的确切清单,见 `docs/ARCHITECTURE.md` 第 7 节,剩余工作见下方的"已知后续事项"。

### 版本管理

本仓库遵循生态系统统一的策略：构建绝不会更改版本号。显式的 `bump` 命令（`python tools/hydra_project_tool.py bump`）会运行 `bump_manifest_version.py`，提升 `pubspec.yaml` 中的版本（`+` 之后的构建号是纯粹的单调计数器，每次 bump +1，不进位），并保持清单同步。它还会重新生成 `lib/app_version.dart`（生成的文件，不是手工编辑的），应用在运行时读取它，以在 **Settings** 界面显示自身版本。完整版本历史见 [CHANGELOG.md](CHANGELOG.md)。

## 📂 仓库结构

<p align="center">
  <img src="images/repository-structure.svg" alt="Repository structure of HYDRA-UMC-DSI" width="100%">
</p>

<details>
<summary>目录树的文本版本</summary>

```text
HYDRA-UMC-DSI/
├── lib/                                                              源代码
│   ├── main.dart                                                     应用入口点，ChangeNotifierProvider + 登录门禁，固定深色主题
│   ├── app_version.dart                                              生成文件——由 bump_manifest_version.py 重新生成，请勿手动编辑
│   ├── models/                                                       数据模型和纯规则
│   ├── network/                                                      REST 客户端、WebSocket 和发现
│   ├── state/                                                        每个界面监听的状态
│   ├── services/                                                     应用服务（背光）
│   ├── l10n/                                                         八种语言的本地化
│   ├── util/                                                         没有独立界面的辅助模块
│   └── ui/                                                           界面和控件
├── kiosk/                                                            展台单元及其安装脚本
├── linux/                                                            GTK 桌面运行器——真正的目标平台，固定 1280x720 窗口
├── windows/                                                          Windows 桌面运行器——仅供开发机验证
├── tools/                                                            项目工具和 CI 检查
├── test/                                                             widget_test、format_uptime_test、localization_test、robot_view_model_test、robot_view_model_silent_refresh_test、auth_prefs_test、hydra_websocket_test、hostile_answers_test、hydra_error_test, play_confirmation_test, stop_long_press_test
├── .github/                                                          CI 工作流和 Issue 模板
├── images/                                                           横幅和 README 的图片
├── build.bat / build.sh                                              flutter pub get + 版本递增 + flutter build windows（开发机验证）
├── build_linux.sh                                                    flutter pub get + flutter build linux（真正的 CM5 目标——在真实 Linux 上运行）
├── run_dev.bat / run_dev.sh                                          flutter run —— 桌面模拟模式
├── CHANGELOG.md                                                      每个版本的变更
├── docs/ARCHITECTURE.md                                              项目架构
├── bump_manifest_version.py                                          将 hydra-umc.project.json 的版本与原生版本同步(--sync)
├── pubspec.yaml / pubspec.lock / l10n.yaml / analysis_options.yaml   Flutter 包的定义及其锁定版本、l10n 生成器设置和 lint 规则
├── build-test.sh                                                     不修改内容的构建检查
├── hydra-umc.project.json                                            清单：版本、成熟度、系列
└── test.sh                                                           运行测试
```

</details>

## 🗺️ 路线图与已知限制

**当前已知限制**

这些是本应用代码中真实存在、已验证的缺口——不是含糊的 TODO,每一项都能追溯到上文代码或文档中的具体位置:

- **远程访问开关尚未独立** —— `REMOTE_API.md` 第 1 节的 `X-Hydra-Client` 值目前只识别 `suite`、`android` 和 `ios`;本应用发送的是 `dsi`,一个不被识别的值,目前从不被拦截,因此其发现请求会无条件通过。修复此问题需要在 HYDRA-UMC-STUDIO 自身的 `SystemSettings.remoteAccess` 类型及其 Config > Remote Access 标签页中添加第 4 个开关——这是对另一个仓库服务器代码的修改,不在本仓库范围内。见 `docs/ARCHITECTURE.md` 第 3 节。
- **3D 视图没有真正的原生 3D 渲染器** —— `ui/three_d_screen.dart` 目前绘制的是一个小型等距 X/Y/Z 位置指示器,而不是嵌入 STUDIO 真正的 Three.js 场景(`webview_flutter` 没有任何 Linux 实现——完整原因见 `docs/ARCHITECTURE.md` 第 4 节)。为此屏幕实现真正的原生 3D 渲染器是未来的工作,尚未开始。
- **仍缺少在真实 CM5 硬件上的实际运行** —— `flutter build linux` 本身现在已经过验证(真实的 Ubuntu 24.04 WSL2 工具链,二进制文件确认能够真正启动——见 `docs/ARCHITECTURE.md` 第 7 节),但 `build_linux.sh` 的完整流程以及自启动单元 `kiosk/hydra-umc-dsi.service` 仍然从未真正针对 CM5 本身或任何其他真实(非 WSL2)Linux 机器运行过。第一次在那里运行它们的人应将其视为该平台目标真正的首次硬件部署,而不是走个形式——见上文的"在真实 CM5 上运行"。

## 🌍 语言

本 README 和仓库文档提供八种语言：英语、西班牙语、德语、法语、意大利语、日语、中文和葡萄牙语（葡萄牙）。它们同时编写，并由 CI 检查八个文件拥有相同的章节和相同的链接。

## 🔗 相关项目

本项目是同一作者(JuanenRac / Electro Hobby 3D)打造的 HYDRA-UMC 机器人生态系统的一部分。值得了解,因为某个请求实际上可能是关于这些项目之一,而非本仓库本身。

**父项目**
- **[HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)** —— 每个控制客户端真正通信的真实无头后端(REST/WebSocket);本面板通过真实的 `REMOTE_API.md` 契约(发现、登录、原子指令、WebSocket 同步)连接的服务器。

**兄弟项目** —— 同样与 HYDRA-UMC-SERVER 自身 API 通信,各自作为独立客户端
- **[HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** —— 具有实时多机器人 3D 可视化的网页控制面板。
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** —— 面向多台服务器的桌面(PySide6)集群指挥中心,打包为独立可执行文件;与本面板使用完全相同的 `REMOTE_API.md` 契约。
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** —— 具有生物识别登录和配对 Wear OS 伴侣应用的原生 Android 控制应用;与本面板使用完全相同的 `REMOTE_API.md` 契约。
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** —— 具有实时 WebSocket 同步的 iOS/iPadOS 控制应用(Flutter);与本面板使用完全相同的 `REMOTE_API.md` 契约,本面板自身真实的 mDNS 发现正是从它移植而来。
- **[HYDRA-UMC-BRIDGE-AMR](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-AMR)** —— 通过 VDA 5050 MQTT 发布者为 AGV/AMR 车队提供的协调边界(仅针对仿真车队测试)。
- **[HYDRA-UMC-BRIDGE-CNC](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-CNC)** —— 具备 GRBL 状态/控制字节访问能力的高层 CNC 单元协调器(仅针对模拟器测试)。
- **[HYDRA-UMC-BRIDGE-DROIDS](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-DROIDS)** —— 面向足式/人形机器人的协调边界,带有 Boston Dynamics Spot 指令发送器(仅针对模拟器测试)。
- **[HYDRA-UMC-BRIDGE-LASER](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-LASER)** —— 读取 3 路钥匙/外壳/联锁 GPIO 信号的激光单元协调器(仅针对模拟芯片测试;无法使激光器上膛或发射)。
- **[HYDRA-UMC-BRIDGE-OPENPNP](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-OPENPNP)** —— 面向 OpenPnP 贴片机板级流程的安全高层协调器。
- **[HYDRA-UMC-BRIDGE-PRINTER3D](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-PRINTER3D)** —— 面向 Moonraker/Klipper 3D 打印机的安全协调边界,具备真实的受控作业指令。
- **[HYDRA-UMC-BRIDGE-ROS2](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-ROS2)** —— 带有惰性导入 rclpy ROS 2 传输层的协调器(尚未在 ROS 2 环境中运行)。
- **[HYDRA-UMC-BRIDGE-UAV](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-UAV)** —— 面向搭载摄像头的无人机的协调边界,带有 MAVLink 指令发送器(仅针对模拟器测试)。

**直接相关**
- **[HYDRA-UMC-WATCH](https://github.com/JuanenRac/HYDRA-UMC-WATCH)** —— 带有触觉提醒模式与配对手机语音中继的 WearOS 伴侣应用(尚未在实体手表上运行);除了主板自身屏幕外,还能将警告传递到操作员手腕上的可穿戴安全警报设备,补充本触控面板。
- **[HYDRA-UMC-COGNITIVE-NODE](https://github.com/JuanenRac/HYDRA-UMC-COGNITIVE-NODE)** —— 面向 Hailo-10 认知流水线(LLM/VLA/语音编排)的集成中枢;直接在本触控面板上增加语音控制。
- **[HYDRA-UMC-VOICE-UI](https://github.com/JuanenRac/HYDRA-UMC-VOICE-UI)** —— 具备受限、需确认的 Watch 中继的真实语音前端(VAD + 意图解析);直接在本触控面板上增加语音控制。
- **[HYDRA-UMC-LOCAL-TECHNICIAN](https://github.com/JuanenRac/HYDRA-UMC-LOCAL-TECHNICIAN)** — 面向生态系统自身的本地、按策略门控的 AI 维护技师——观察、诊断并提出修复建议;两个最高风险等级目前特意尚未实现。

**生态系统中的其他项目**

*核心硬件与平台*
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** —— 机器人手臂主板设计——CM5 主机 + 双核 STM32H745,目标是通过 CAN-OTA/SPI-OTA 协调最多 8 条工具臂(固件处于早期阶段,尚无已组装的电路板)。
- **[HYDRA-UMC-OS](https://github.com/JuanenRac/HYDRA-UMC-OS)** —— 面向 CM5 的可复现 Raspberry Pi OS 产品层——只读代理、经过验证的配置/配置文件、WiFi 首次配网。
- **[HYDRA-UMC-SDK](https://github.com/JuanenRac/HYDRA-UMC-SDK)** —— 每个桥接都据此校验自身指令的共享 JSON-Schema 契约与软件作业门限边界(并非经认证的安全功能)。
- **[HYDRA-UMC-CONNECTOR-HUB](https://github.com/JuanenRac/HYDRA-UMC-CONNECTOR-HUB)** — 面向外部机器连接器的声明式适配器清单注册与校验工具；把 SDK 自身的契约理念扩展到外部机器，而不取代工业网关类项目。

*核心后端与客户端*
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** —— 将完成的模型推送到 STUDIO 自身目录的桌面版图形化 URDF 创建/编辑工具。
- **[HYDRA-UMC-EDITOR-STL](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-STL)** — 桌面 STL 模型编辑器，在 HYDRA-UMC-EDITOR-URDF 编辑的同一模型目录中变换/替换/移除/添加真实部件。

*URTC 工具平台*
- **[URTC](https://github.com/JuanenRac/URTC)** —— 面向实体 Universal Robot Tool Controller 板卡的固件,通过 CAN 总线支持 25 种以上工具配置。
- **[URTC-FLASHER](https://github.com/JuanenRac/URTC-FLASHER)** —— 面向 URTC 板卡的桌面图形烧录工具,支持 CAN-OTA 以及全芯片 SWD/JTAG。
- **[URTC-TESTER](https://github.com/JuanenRac/URTC-TESTER)** —— 面向 URTC 板卡的桌面实时 CAN 总线诊断工具,每种工具配置对应一个面板。
- **[URTC-WEB-STUDIO](https://github.com/JuanenRac/URTC-WEB-STUDIO)** —— 通过 Web Serial API 实现的浏览器版 URTC-TESTER 替代方案,无需本地安装。
- **[URTC-GATEWAY](https://github.com/JuanenRac/URTC-GATEWAY)** —— URTC CAN 总线前的网关：允许的标识符列表、速率限制和会话密钥；软件已在计算机上测试，尚未在真实总线上测试。

*视觉 AI 节点(Hailo-8)*
- **[HYDRA-UMC-VISION-NODE](https://github.com/JuanenRac/HYDRA-UMC-VISION-NODE)** —— 面向 Hailo-8 视觉流水线的集成中枢,具备逐阶段的真实硬件就绪检测。
- **[HYDRA-UMC-DETECTION-HEF](https://github.com/JuanenRac/HYDRA-UMC-DETECTION-HEF)** —— 具备 Hailo 架构/校验和安全加载验证的真实编译模型注册表。
- **[HYDRA-UMC-VISION-STREAMER](https://github.com/JuanenRac/HYDRA-UMC-VISION-STREAMER)** —— 具备真实 HailoRT 集成边界的真实 GStreamer 流水线 + MediaMTX 配置生成器。
- **[HYDRA-UMC-VISUAL-SERVOING-API](https://github.com/JuanenRac/HYDRA-UMC-VISUAL-SERVOING-API)** —— 以区域状态为授权条件的 Position-Based Visual Servoing 修正律;尚无摄像头位姿估计。
- **[HYDRA-UMC-SAFETY-ZONES](https://github.com/JuanenRac/HYDRA-UMC-SAFETY-ZONES)** —— 从文件读取物体位置的 v0 区域入侵、校准新鲜度与 E-STOP 请求逻辑;没有检测器为其供数,也尚未连接任何物理 E-STOP。

*认知 AI 节点(Hailo-10)*
- **[HYDRA-UMC-VLA-ENGINE](https://github.com/JuanenRac/HYDRA-UMC-VLA-ENGINE)** —— 面向 Vision-Language-Action 模型的真实动作 token 编解码与轨迹生成。
- **[HYDRA-UMC-SEMANTIC-PLANNER](https://github.com/JuanenRac/HYDRA-UMC-SEMANTIC-PLANNER)** —— 基于真实规则的任务分解,以及针对 MCU 错误码的语义化错误恢复。
- **[HYDRA-UMC-DOCS-QA](https://github.com/JuanenRac/HYDRA-UMC-DOCS-QA)** —— 面向本生态系统自身 Markdown 文档的真实纯标准库 TF-IDF 文档检索。

*编排与集群*
- **[HYDRA-UMC-ORCHESTRATOR](https://github.com/JuanenRac/HYDRA-UMC-ORCHESTRATOR)** —— 具备真实 gRPC/Protobuf 健康报告契约与任务状态机的集成中枢。
- **[HYDRA-UMC-JOB-DISPATCHER](https://github.com/JuanenRac/HYDRA-UMC-JOB-DISPATCHER)** —— 基于真实 HTTP API 的真实优先级任务队列,支持去重。
- **[HYDRA-UMC-NODE-HEALING](https://github.com/JuanenRac/HYDRA-UMC-NODE-HEALING)** —— 具备重试/退避与身份不匹配检测的真实基于 gRPC 的车队健康看门狗。
- **[HYDRA-UMC-PATH-PLANNER-3D](https://github.com/JuanenRac/HYDRA-UMC-PATH-PLANNER-3D)** —— 具备真实障碍物/工作空间碰撞校验的真实基于 RRT 的三维路径规划器。
- **[HYDRA-UMC-SWARM-SYNC](https://github.com/JuanenRac/HYDRA-UMC-SWARM-SYNC)** —— 经过多单元收敛属性测试的真实 CRDT LWW-Element-Map 状态同步。

*数字孪生与仿真*
- **[HYDRA-UMC-TWIN](https://github.com/JuanenRac/HYDRA-UMC-TWIN)** —— 面向数字孪生引擎的集成中枢,具备真实的版本兼容性同步契约。
- **[HYDRA-UMC-HIL-BRIDGE](https://github.com/JuanenRac/HYDRA-UMC-HIL-BRIDGE)** —— 在仿真与真实硬件之间带有软件碰撞联锁的硬件在环路由器(未在真实硬件上测试)。
- **[HYDRA-UMC-PHYSICS-REPLICA](https://github.com/JuanenRac/HYDRA-UMC-PHYSICS-REPLICA)** —— 面向真实 URDF 子集的真实正向运动学与关节限位校验。
- **[HYDRA-UMC-SYNTHETIC-DATA-GEN](https://github.com/JuanenRac/HYDRA-UMC-SYNTHETIC-DATA-GEN)** —— 具备 YOLO/COCO 标注导出功能的真实程序化 2D 场景生成器。

*数据与分析*
- **[HYDRA-UMC-DATALAKE](https://github.com/JuanenRac/HYDRA-UMC-DATALAKE)** —— 具备真实数据摄入/查询 HTTP API 的真实 sqlite3 时序数据存储。
- **[HYDRA-UMC-ANOMALY-DETECTOR](https://github.com/JuanenRac/HYDRA-UMC-ANOMALY-DETECTOR)** —— 具备漂移监测能力的真实 FFT + 统计基线异常检测器。
- **[HYDRA-UMC-PRODUCTION-REPORTS](https://github.com/JuanenRac/HYDRA-UMC-PRODUCTION-REPORTS)** —— 基于 DATALAKE 历史数据的真实 OEE/可用率计算,支持可复现的 CSV 导出。
- **[HYDRA-UMC-TELEMETRY-COLLECTOR](https://github.com/JuanenRac/HYDRA-UMC-TELEMETRY-COLLECTOR)** —— 面向 DATALAKE 的真实 CAN/WebSocket 数据摄入管道,支持序列去重。

*工业网关*
- **[HYDRA-UMC-GATEWAY-INDUSTRIAL](https://github.com/JuanenRac/HYDRA-UMC-GATEWAY-INDUSTRIAL)** —— 中继至工业协议的集成中枢,具备真实的指令白名单/背压控制层。
- **[HYDRA-UMC-OPCUA-SERVER](https://github.com/JuanenRac/HYDRA-UMC-OPCUA-SERVER)** —— 经真实二进制协议客户端会话验证的真实 OPC-UA 地址空间。
- **[HYDRA-UMC-MQTT-BROKER](https://github.com/JuanenRac/HYDRA-UMC-MQTT-BROKER)** —— 具备可选按客户端认证与主题 ACL 的真实 MQTT 代理。
- **[HYDRA-UMC-MTCONNECT-ADAPTER](https://github.com/JuanenRac/HYDRA-UMC-MTCONNECT-ADAPTER)** —— 具备降级模式输出的真实 MTConnect `/probe` 与 `/current` XML 端点。

*辅助工具与生态系统运维*
- **[HYDRA-UMC-DASHBOARD-AI](https://github.com/JuanenRac/HYDRA-UMC-DASHBOARD-AI)** —— 基于 DATALAKE/ANOMALY-DETECTOR 的智能摘要与异常高亮面板,具备诚实的统计回退机制。
- **[HYDRA-UMC-TOOL-CLI](https://github.com/JuanenRac/HYDRA-UMC-TOOL-CLI)** —— 具备真实、稳定退出码契约的车队 CLI,是 HYDRA-UMC-SERVER 自身 API 的真实在线客户端。
- **[URTC-SMART-RACK](https://github.com/JuanenRac/URTC-SMART-RACK)** —— 面向板卡安装机架的固件,具备真实的工具 ID 解码与 Smart Idle 预热逻辑。
- **[URTC-VISION-TOOL](https://github.com/JuanenRac/URTC-VISION-TOOL)** —— 面向热成像/RGB 检测工具头的固件及真实 Python 视觉伴侣程序。
- **[HYDRA-UMC-UPDATER](https://github.com/JuanenRac/HYDRA-UMC-UPDATER)** —— 发现、克隆并更新本生态系统中每个仓库的管理类桌面工具。
- **[HYDRA-UMC-OS-REBUILDER](https://github.com/JuanenRac/HYDRA-UMC-OS-REBUILDER)** —— 构建即刻可烧录、预装生态系统最新版本的 CM5 镜像的 Windows/Linux 桌面工具,具备类似 Raspberry Pi Imager 风格的首次启动 Wi-Fi/用户/SSH 配置。
- **[HYDRA-UMC-OPS-AGENT](https://github.com/JuanenRac/HYDRA-UMC-OPS-AGENT)** — 维护事件协调器：一个低权限的边缘角色采集经过脱敏的库存/健康快照，一个控制面角色以只读方式渲染它，并请求某个 AI 提供方给出诊断建议——从不应用补丁，也从不部署任何内容。
- **[HYDRA-UMC-DEV-SERVER](https://github.com/JuanenRac/HYDRA-UMC-DEV-SERVER)** — 可复现的开发主机（Raspberry Pi 5 / CM5），保存整个生态系统的源代码，并在持久队列下运行有界的构建/测试任务；这是专用的开发角色，明确区别于运行中的 CM5。

## 📚 文档

更多阅读：

* [生态系统的安全基线](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/SECURITY_BASELINE.md)
* [生态系统的威胁模型](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/THREAT_MODEL.md)
* [本仓库的更新日志](CHANGELOG.md)
* [本仓库的许可证](LICENSE.md)

## 🤝 参与贡献与社区

* 提交 pull request 之前，请运行 `HYDRA_UMC_CI=1 py -3 tools/ci_validate.py`（或 `HYDRA_UMC_CI=1 python3 tools/ci_validate.py`）：它必须输出 `CI_VALIDATION=PASS`。此检查不要运行 `build.sh` 或 `build.bat`；构建不是检查。
* 八个 README 由 HYDRA-UMC-DOCS 中的同一个源生成；请勿手工编辑。修改源文件，再用 `tools/make_readmes.py` 重新生成。
* 不要在 README 中声称尚未运行过的内容：属实时请写“仅模拟”或“尚未在硬件上试过”。
* 请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)、[行为准则](CODE_OF_CONDUCT.md)、[SECURITY.md](SECURITY.md) 和 [SUPPORT.md](SUPPORT.md)。

## 👤 作者

**JuanenRac (Electro Hobby 3D)** · electrohobby3d@gmail.com

## 📜 许可证

GPL-3.0-or-later - [LICENSE](LICENSE).
