<p align="center">
  <img src="images/HYDRA_UMC_BANNER.svg" alt="HYDRA-UMC-DSI banner" width="100%">
</p>
# 🖥️ HYDRA-UMC DSI

<p align="center">
  <a href="README.md">🇺🇸 English</a> |
  <a href="README_spa.md">🇪🇸 Español</a> |
  <a href="README_fra.md">🇫🇷 Français</a> |
  <a href="README_ita.md">🇮🇹 Italiano</a> |
  <a href="README_deu.md">🇩🇪 Deutsch</a> |
  🇨🇳 <b>简体中文</b> |
  <a href="README_jpn.md">🇯🇵 日本語</a>
</p>


<p align="left">
  <img src="https://img.shields.io/badge/License-GPL%203.0-blue.svg" alt="GPL 3.0">
  <img src="https://img.shields.io/badge/Framework-Flutter%203.x-02569B.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Language-Dart-0175C2.svg" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20CM5-E34F26.svg" alt="Platform">
</p>


一个原生的 Flutter 触控界面（Dart，真实的 Linux 桌面目标），面向 HYDRA-UMC 自身在 Compute Module 5 上的 5"/7" DSI 触摸屏——两种物理面板尺寸共享完全相同的 1280x720 像素分辨率，因此本应用采用一种固定的、非自适应的布局，而不是针对两种尺寸做响应式适配。它使用与 [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)、[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) 和 [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) 完全相同的 [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-STUDIO/blob/main/docs/REMOTE_API.md) 契约——发现、登录、原子化的逐机器人指令，以及针对运行中的 [HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO) 服务器的实时 WebSocket 同步,直接在主板本身上运行,而非通过浏览器标签页。完整设计参见 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md),包括为何选择 Flutter（而非 Kivy）以及为何 3D 界面不是一个 WebView。

**本应用是同一块主板上并存的两个控制界面之一**——CM5 同时驱动一个 HDMI 输出,供运行浏览器界面的完整外接显示器使用。这个 DSI 应用与该路径互为补充,在主板本身提供一个直接的、常开的触控控制台;它并不取代浏览器界面。

## 🏗️ 已实现的功能

- **登录**（`lib/ui/login_screen.dart`、`lib/state/robot_view_model.dart`）—— 面向触控设计的服务器 IP/端口 + 用户名/密码字段,`POST /api/login` 面向 `admin`/`admin`（已预填——本生态系统中每台服务器在自身首次启动时预置的默认账户;可从浏览器界面的 Config > Users 中创建额外的低权限“操作员”账户）,会话令牌通过 `shared_preferences` 在多次启动之间持久化——这对于一个应当在 CM5 断电重启后依然保持登录状态、而不仅仅是应用重新启动后保持登录的看板面板来说非常重要。一个“扫描本地网络”对话框（`lib/network/discovery.dart`）无需预先知道 IP 即可找到服务器——这在这里尤其有用,因为本应用运行所在的 CM5,往往正是它应该连接的那个控制器本身。
- **网络发现**（`lib/network/discovery.dart`）—— 两条路径从同一个“扫描本地网络”对话框并行运行:真实的 mDNS/Bonjour（`discoverMdns()`，通过 `multicast_dns` 包查询 `server.ts` 自身发布的 `_hydra._tcp`）,以及针对本设备自身真实本地子网的并发暴力扫描 `GET /api/hydra-info`（`scanSubnets()`）,按 host:port 去重——从 HYDRA-UMC-IOS-CONTROL 移植而来,后者是本生态系统中第一个加入真实 mDNS 发现的客户端。
- **原子化指令同步**（`lib/state/robot_view_model.dart` 自身的 `_sendAtomicCommand()`）—— 每一次写入（启用/禁用/播放/暂停/停止/点动/阀门/泵/速度/视觉）都使用真实的 `POST /api/robot/:id/command` 端点,具备正确的合并机器人（`combinedWith`）传播机制,并在请求失败时回滚到变更前的快照——这对于距离真实机器人仅几英尺远的点动手柄/紧急停止尤为重要。
- **实时 WebSocket 同步**（`lib/network/hydra_websocket.dart`）—— 始终附带 `?token=`,同时处理 `"settings"` 和 `"delta"` 两种广播类型,断线后自动重连。
- **水平触控导航**（`lib/ui/main_screen.dart`）—— 在固定的 1280px 宽度上,一条常驻的顶部栏包含 6 个大图标+标签选项卡（仪表盘/控制/摄像头/3D 视图/指标/设置）,精神上更接近 KlipperScreen,而非手机式的底部导航栏——匹配项目所有者所要求的目录,并针对宽幅触控面板而非纵向手机布局进行了重新组织。
- **仪表盘**（`lib/ui/dashboard_screen.dart`）—— 每机器人卡片,通过 `Provider` 实时响应,LED 惯例（绿色脉冲=活动,红色常亮=非活动）,合并机器人显示,以及模块芯片（CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK）——与本生态系统中其他每一个客户端相同的视觉语言。
- **手动控制**（`lib/ui/control_screen.dart`、`lib/ui/widgets/joystick_pad.dart`）—— 并排布局（点动面板在左,遥测/速度/IO 在右）,针对 1280x720 画面而设计,而非单列滚动布局,紧急停止/停止具备真实的长按保护（快速轻触不会产生任何效果,只有触感反馈+视觉提示,只有真正的长按才会发送指令）,速度/加速度滑块,阀门/泵开关。
- **摄像头**（`lib/ui/camera_screen.dart`、`lib/ui/widgets/mjpeg_view.dart`）—— 与 HYDRA-UMC-IOS-CONTROL 相同的手写、无依赖 MJPEG 流解析器（没有 WebView,没有平台特定代码——在 Linux 桌面上原样即可运行）,一个明确的“摄像头已禁用”状态,以及一个可直接从服务器打开/关闭机器人视觉系统的开关。
- **3D 视图**（`lib/ui/three_d_screen.dart`）—— **并非**像 iOS/Android 应用那样嵌入 STUDIO 真实 Three.js 场景的 WebView——`webview_flutter` 在 Linux 桌面上根本没有实现,而完整的浏览器引擎对这块低功耗嵌入式面板而言是过重的运行时负担。取而代之的是:一个小型的原生等距 X/Y/Z 位置指示器（`CustomPainter`,不涉及 3D 引擎）,并附有一条屏幕提示,指向本主板自身通过 HDMI 连接的显示器上的真实 3D 场景。完整推理见 `docs/ARCHITECTURE.md` 第 4 节。
- **系统指标**（`lib/ui/metrics_screen.dart`）—— 拥有自己专属的选项卡（不像 iOS/Android 那样折叠进仪表盘中）,包含来自 `GET /api/system/metrics` 的 CPU/内存/温度/运行时间图块,以及来自 `GET /api/hydra-info` 的主机名/控制器数量/机器人数量/应用版本。
- **设置**（`lib/ui/settings_screen.dart`）—— 连接信息、服务器身份、退出登录,以及本应用自身的版本（见下文[版本管理](#-版本管理)）。
- **看板自启动**（`kiosk/hydra-umc-dsi.service`、`kiosk/install_kiosk.sh`）—— 一个 systemd 单元,通过 `cage` 在 `tty1` 上全屏启动本应用,`Restart=always`。详见下文”在真实 CM5 上运行”。
- **7 语言界面**（`lib/l10n/`，标准的 `flutter gen-l10n` 流程）—— 英语、西班牙语、法语、德语、意大利语、日语和中文，与本生态系统的其他客户端保持一致。`设置 > 语言` 中的持久化设置默认跟随系统语言；`RobotViewModel.lastError` 现在是带类型的 `HydraError`，而不是预先格式化好的英文文本，因此业务逻辑层的错误提示也能正确本地化，而不只是界面上的静态文本。

**状态:雏形 + 全部 6 个目录界面均已实现并连接到真实的 REMOTE_API.md 契约。** `flutter analyze` 干净通过,`flutter build windows` 生成一个可运行的二进制文件,`flutter test` 通过——具体哪些在这个 Windows 工作环境中能够验证、哪些不能,详见下文“构建”,因为真正的目标平台是 Linux。

## 🚀 构建

需要 [Flutter SDK](https://docs.flutter.dev/get-started/install)（stable 渠道）。本仓库基于 Flutter 3.47.0 构建/验证。本仓库中只配置了 `linux/` 和 `windows/` 两个平台（没有 `android/`、`ios/`、`web/` 或 `macos/` 文件夹）——Linux 是真正的目标平台（CM5 自身的操作系统）;Windows 的存在纯粹是为了让本应用自身的逻辑能够在没有 Linux 工具链的机器上构建、运行和测试。

### 构建脚本

```bash
./build.sh          # Git Bash / WSL，或使用 build.bat 用于 cmd/PowerShell —— flutter pub get + 版本递增 + flutter build windows（开发机验证）
./build_linux.sh    # 必须在真实的 Linux 机器上运行（或 CM5 本身）—— flutter pub get + 版本递增 + flutter build linux（真正的部署目标）
./run_dev.sh         # Git Bash / WSL，或使用 run_dev.bat 用于 cmd/PowerShell —— 桌面模拟模式（flutter run），无需硬件
```

全部 3 个构建脚本（`build.sh`/`build.bat`/`build_linux.sh`）都会先递增应用的版本号——见下文[版本管理](#-版本管理)。`run_dev.sh`/`run_dev.bat` 不会——在该策略下,开发循环中的 `flutter run` 不算“真正的构建”。

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

**关于 Linux 验证的诚实说明：** 本仓库是在一台没有可用 Linux 构建工具链的 Windows 机器上编写的（通过 `wsl --status` 确认——未安装任何 WSL 发行版）。从这个工作环境中,`flutter build linux` 从未真正针对这份代码运行过;`flutter build windows` 被用作任务明确允许的冒烟测试替代方案。具体哪些已验证、哪些未验证的确切清单,见 `docs/ARCHITECTURE.md` 第 7 节,后续工作见 `mejoras_futuras.txt`。

## 🔢 版本管理

本仓库遵循一项全生态系统统一的策略（与 [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) 共享,并在那里并行实现）:版本号在**每次真正的构建**时自动递增,无需手动编辑 `pubspec.yaml` 的 `version:` 行。`build.sh`/`build.bat`/`build_linux.sh` 会在调用 `flutter build` 之前运行 `tool/bump_version.dart`,应用以下规则:

- **Patch,里程表方式（十进制）：** 每次构建 +1;一旦超过 9 就重置为 0,并将 minor 加 1——例如 `0.0.9` -> `0.1.0`。Major 从不被自动修改。
- **构建号**（`+` 之后的部分）：一个纯粹的单调计数器,每次构建 +1,不进位。

同一个脚本会重新生成 `lib/app_version.dart`（这是生成的文件,不是手工编辑的——一个普通的 `const` 文件,而非像 `package_info_plus` 那样引入新的运行时依赖）,应用在运行时读取它,以在 **Settings** 界面显示自身版本。完整版本历史见 [CHANGELOG.md](CHANGELOG.md)。

### 在真实 CM5 上运行

在 `build_linux.sh` 生成 `build/linux/*/release/bundle/` 之后,将整个 `bundle/` 目录复制到 CM5 的 `/opt/hydra-umc-dsi/bundle/`（它依赖二进制文件旁边的 `.so` 文件,而不仅仅是可执行文件本身）,然后运行 `sudo kiosk/install_kiosk.sh` 来安装并启用 `kiosk/hydra-umc-dsi.service`——一个 systemd 单元,通过 [`cage`](https://github.com/cage-kiosk/cage)（一个极简的 Wayland 看板合成器,只运行一个全屏客户端）在 `tty1` 上全屏启动本应用,并设置 `Restart=always`,这样崩溃时会重新启动应用,而不是留下一块黑屏。之所以选择它而非 [`flutter-pi`](https://github.com/ardera/flutter-pi)（一个面向 Raspberry Pi 的第三方裸机 Flutter 引擎嵌入器,完全不依赖任何窗口系统运行）,具体原因是它能够原样复用 `build_linux.sh` 自身真实的 `flutter build linux` 输出——而 flutter-pi 是直接针对 Flutter 引擎构建的,因此需要自己独立的构建步骤,而不能直接套用本仓库已经产生的构建结果。**诚实说明：** 已编写并审查,但从未真正在真实 CM5 或任何其他 Linux 主机上运行过——与 `flutter build linux` 本身相同的未验证状态（见 `docs/ARCHITECTURE.md` 第 7 节）。具体需要针对 CM5 实际运行的树莓派操作系统镜像核实哪些假设（root 服务用户、`tty1` 所有权）,见 `kiosk/hydra-umc-dsi.service` 自身的头部注释。

## 📂 仓库结构

```text
HYDRA-UMC-DSI/
├── build.bat, build.sh              # flutter pub get + 版本递增 + flutter build windows（开发机验证）
├── build_linux.sh                   # flutter pub get + 版本递增 + flutter build linux（真正的 CM5 目标——在真实 Linux 上运行）
├── run_dev.bat, run_dev.sh          # flutter run —— 桌面模拟模式
├── CHANGELOG.md                      # 版本历史（见上文版本管理）
├── kiosk/
│   ├── hydra-umc-dsi.service        # systemd 单元——通过 cage 全屏自启动
│   └── install_kiosk.sh             # 安装并启用上述单元（在真实 CM5 上运行）
├── tool/
│   └── bump_version.dart            # build.bat/build.sh/build_linux.sh 在每次构建前运行的版本递增脚本（见上文版本管理）
├── lib/
│   ├── main.dart                    # 应用入口点，ChangeNotifierProvider + 登录门禁，固定深色主题
│   ├── app_version.dart             # 生成文件——由 tool/bump_version.dart 重新生成，请勿手动编辑
│   ├── models/
│   │   ├── server_info.dart         # 发现/连接条目——与其他 3 个客户端中的 ServerInfo 镜像一致
│   │   └── hydra_state.dart         # RobotView/ControllerView/HydraState——原始 settings.json 树的薄型可变视图
│   ├── network/
│   │   ├── hydra_api_client.dart    # REST：登录、设置、原子化机器人指令、系统指标——X-Hydra-Client: dsi
│   │   ├── hydra_websocket.dart     # /ws 实时同步客户端
│   │   ├── discovery.dart           # 本设备自身真实本地子网的并发扫描
│   │   └── auth_prefs.dart          # 持久化的连接信息 + 令牌（shared_preferences）
│   ├── state/
│   │   ├── robot_view_model.dart    # 每个界面都监听的单一 ChangeNotifier
│   │   └── hydra_error.dart         # 面向 RobotViewModel 的类型化错误接口（自身无 BuildContext）
│   ├── services/
│   │   └── backlight.dart           # 根据时间自适应调节背光
│   ├── l10n/                        # 真实生成的本地化文件（7 种语言）——见仓库根目录的 l10n.yaml
│   │   ├── app_localizations.dart   # 生成的基类
│   │   ├── app_localizations_en.dart, _es.dart, _it.dart, _fr.dart, _de.dart, _ja.dart, _zh.dart
│   │   └── language_prefs.dart      # 持久化的语言覆盖设置（shared_preferences）
│   └── ui/
│       ├── login_screen.dart        # 主机/端口/用户/密码字段 + “扫描本地网络”
│       ├── main_screen.dart         # 水平触控导航栏（6 个选项卡）——精神上接近 KlipperScreen
│       ├── dashboard_screen.dart    # 每机器人卡片 + 系统指标栏
│       ├── control_screen.dart      # 点动/速度/阀门/泵/回放控制，并排触控布局
│       ├── camera_screen.dart       # MJPEG 查看器 + 视觉开关
│       ├── three_d_screen.dart      # 原生等距 X/Y/Z 指示器——非 WebView（见 docs/ARCHITECTURE.md §4）
│       ├── metrics_screen.dart      # CM5 主机指标 + 服务器身份专属选项卡
│       ├── settings_screen.dart     # 连接信息 + 退出登录 + 自身应用版本
│       └── widgets/
│           ├── joystick_pad.dart     # 点动方向键，为触控放大
│           ├── digital_readout.dart, status_led.dart
│           └── mjpeg_view.dart       # 手写的 MJPEG 流解析器
├── linux/                            # GTK 桌面运行器——真正的目标平台，固定 1280x720 窗口
├── windows/                          # Windows 桌面运行器——仅供开发机验证
├── docs/ARCHITECTURE.md
├── tools/
│   └── ci_validate.py               # CI 使用的清单/CHANGELOG/文档校验
├── bump_manifest_version.py          # 将 hydra-umc.project.json 的版本与原生版本同步(--sync)
├── test/                             # widget_test、format_uptime_test、localization_test、robot_view_model_test
├── README.md                         # 本文件
└── README_spa.md / README_ita.md / README_fra.md / README_deu.md / README_zho.md / README_jpn.md  # 翻译
```

## 🔗 相关项目

本项目是同一作者（JuanenRac / Electro Hobby 3D）打造的更大规模机器人生态系统的一部分,涵盖核心平台控制、视觉与认知 AI 节点、群体编排、数字孪生、数据分析,以及跨众多项目的工业集成。值得了解,因为某个请求实际所指的可能正是这些项目之一,而非本仓库。

**与 HYDRA-UMC-DSI 直接相关**
- **[HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** —— 本面板通过真实的 `REMOTE_API.md` 契约(发现、登录、原子命令、WebSocket 同步)连接的服务器。
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)**、**[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)**、**[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** —— 与本面板讲完全相同 `REMOTE_API.md` 契约的兄弟客户端;iOS 应用尤其是本面板真实 mDNS 发现功能的移植来源。
- **[HYDRA-UMC-WATCH](https://github.com/JuanenRac/HYDRA-UMC-WATCH)** —— 一款与本触控面板互补的可穿戴安全警报设备,除了主板自身的屏幕之外,还能将警告传达到操作员的手腕上。
- **[HYDRA-UMC-COGNITIVE-NODE](https://github.com/JuanenRac/HYDRA-UMC-COGNITIVE-NODE)** —— 直接在本触控面板上增加语音控制。
- **[HYDRA-UMC-VOICE-UI](https://github.com/JuanenRac/HYDRA-UMC-VOICE-UI)** —— 直接在本触控面板上增加语音控制。

**生态系统的其余部分**

💠 **核心生态系统**：[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC) · [HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER) · [HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO) · [HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE) · [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) · [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) · [HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF) · [URTC](https://github.com/JuanenRac/URTC) · [URTC-FLASHER](https://github.com/JuanenRac/URTC-FLASHER) · [URTC-TESTER](https://github.com/JuanenRac/URTC-TESTER) · [URTC-WEB-STUDIO](https://github.com/JuanenRac/URTC-WEB-STUDIO)

👁️ **视觉 AI 节点（Hailo-8）**：[HYDRA-UMC-VISION-NODE](https://github.com/JuanenRac/HYDRA-UMC-VISION-NODE) · [HYDRA-UMC-VISION-STREAMER](https://github.com/JuanenRac/HYDRA-UMC-VISION-STREAMER) · [HYDRA-UMC-DETECTION-HEF](https://github.com/JuanenRac/HYDRA-UMC-DETECTION-HEF) · [HYDRA-UMC-SAFETY-ZONES](https://github.com/JuanenRac/HYDRA-UMC-SAFETY-ZONES) · [HYDRA-UMC-VISUAL-SERVOING-API](https://github.com/JuanenRac/HYDRA-UMC-VISUAL-SERVOING-API)

🧠 **认知 AI 节点（Hailo-10）**：[HYDRA-UMC-VLA-ENGINE](https://github.com/JuanenRac/HYDRA-UMC-VLA-ENGINE) · [HYDRA-UMC-SEMANTIC-PLANNER](https://github.com/JuanenRac/HYDRA-UMC-SEMANTIC-PLANNER) · [HYDRA-UMC-DOCS-QA](https://github.com/JuanenRac/HYDRA-UMC-DOCS-QA)

🐝 **编排与集群**：[HYDRA-UMC-ORCHESTRATOR](https://github.com/JuanenRac/HYDRA-UMC-ORCHESTRATOR) · [HYDRA-UMC-SWARM-SYNC](https://github.com/JuanenRac/HYDRA-UMC-SWARM-SYNC) · [HYDRA-UMC-PATH-PLANNER-3D](https://github.com/JuanenRac/HYDRA-UMC-PATH-PLANNER-3D) · [HYDRA-UMC-JOB-DISPATCHER](https://github.com/JuanenRac/HYDRA-UMC-JOB-DISPATCHER) · [HYDRA-UMC-NODE-HEALING](https://github.com/JuanenRac/HYDRA-UMC-NODE-HEALING)

🎮 **数字孪生与仿真**：[HYDRA-UMC-TWIN](https://github.com/JuanenRac/HYDRA-UMC-TWIN) · [HYDRA-UMC-PHYSICS-REPLICA](https://github.com/JuanenRac/HYDRA-UMC-PHYSICS-REPLICA) · [HYDRA-UMC-HIL-BRIDGE](https://github.com/JuanenRac/HYDRA-UMC-HIL-BRIDGE) · [HYDRA-UMC-SYNTHETIC-DATA-GEN](https://github.com/JuanenRac/HYDRA-UMC-SYNTHETIC-DATA-GEN)

📊 **数据与分析**：[HYDRA-UMC-DATALAKE](https://github.com/JuanenRac/HYDRA-UMC-DATALAKE) · [HYDRA-UMC-TELEMETRY-COLLECTOR](https://github.com/JuanenRac/HYDRA-UMC-TELEMETRY-COLLECTOR) · [HYDRA-UMC-ANOMALY-DETECTOR](https://github.com/JuanenRac/HYDRA-UMC-ANOMALY-DETECTOR) · [HYDRA-UMC-PRODUCTION-REPORTS](https://github.com/JuanenRac/HYDRA-UMC-PRODUCTION-REPORTS)

🏭 **工业网关**：[HYDRA-UMC-GATEWAY-INDUSTRIAL](https://github.com/JuanenRac/HYDRA-UMC-GATEWAY-INDUSTRIAL) · [HYDRA-UMC-OPCUA-SERVER](https://github.com/JuanenRac/HYDRA-UMC-OPCUA-SERVER) · [HYDRA-UMC-MQTT-BROKER](https://github.com/JuanenRac/HYDRA-UMC-MQTT-BROKER) · [HYDRA-UMC-MTCONNECT-ADAPTER](https://github.com/JuanenRac/HYDRA-UMC-MTCONNECT-ADAPTER)

🛠️ **配套工具**：[URTC-SMART-RACK](https://github.com/JuanenRac/URTC-SMART-RACK) · [URTC-VISION-TOOL](https://github.com/JuanenRac/URTC-VISION-TOOL) · [HYDRA-UMC-TOOL-CLI](https://github.com/JuanenRac/HYDRA-UMC-TOOL-CLI) · [HYDRA-UMC-DASHBOARD-AI](https://github.com/JuanenRac/HYDRA-UMC-DASHBOARD-AI)

---

## 👤 作者
**JuanenRac** (Electro Hobby 3D)
📧 electrohobby3d@gmail.com
📺 [youtube.com/@electrohobby3d](https://youtube.com/@electrohobby3d)

## 📜 许可证

源代码采用 **GNU 通用公共许可证 v3.0（GPL-3.0）**——见 [`LICENSE`](LICENSE)。

文档（本 README 及其自身的翻译版本——`README_spa.md`、`README_ita.md`、`README_fra.md`、`README_deu.md`、`README_zho.md`、`README_jpn.md`）依据 **知识共享 署名-相同方式共享 4.0 国际许可协议（CC BY-SA 4.0）** 提供。完整文本见 https://creativecommons.org/licenses/by-sa/4.0/。
