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

本项目是同一作者(JuanenRac / Electro Hobby 3D)打造的 HYDRA-UMC 机器人生态系统的一部分。值得了解,因为某个请求实际上可能是关于这些项目之一,而非本仓库本身。

**父项目**
- **[HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)** —— 每个控制客户端真正通信的真实无头后端(REST/WebSocket);本面板通过真实的 `REMOTE_API.md` 契约(发现、登录、原子指令、WebSocket 同步)连接的服务器。

**兄弟项目** —— 同样与 HYDRA-UMC-SERVER 自身 API 通信,各自作为独立客户端
- **[HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** —— 具有实时多机器人 3D 可视化的网页控制面板。
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** —— 面向多台服务器的桌面(PySide6)集群指挥中心,打包为独立可执行文件;与本面板使用完全相同的 `REMOTE_API.md` 契约。
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** —— 具有生物识别登录和配对 Wear OS 伴侣应用的原生 Android 控制应用;与本面板使用完全相同的 `REMOTE_API.md` 契约。
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** —— 具有实时 WebSocket 同步的 iOS/iPadOS 控制应用(Flutter);与本面板使用完全相同的 `REMOTE_API.md` 契约,本面板自身真实的 mDNS 发现正是从它移植而来。
- **[HYDRA-UMC-BRIDGE-AMR](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-AMR)** —— 通过真实的 VDA 5050 MQTT 发布者为 AGV/AMR 车队提供的协调边界。
- **[HYDRA-UMC-BRIDGE-CNC](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-CNC)** —— 具备真实 GRBL 状态/控制字节访问能力的高层 CNC 单元协调器。
- **[HYDRA-UMC-BRIDGE-DROIDS](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-DROIDS)** —— 面向足式/人形机器人的协调边界,具备真实的 Boston Dynamics Spot 指令发送器。
- **[HYDRA-UMC-BRIDGE-LASER](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-LASER)** —— 读取 3 项真实钥匙/外壳/联锁 GPIO 安全信号的激光单元安全协调器。
- **[HYDRA-UMC-BRIDGE-OPENPNP](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-OPENPNP)** —— 面向 OpenPnP 贴片机板级流程的安全高层协调器。
- **[HYDRA-UMC-BRIDGE-PRINTER3D](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-PRINTER3D)** —— 面向 Moonraker/Klipper 3D 打印机的安全协调边界,具备真实的受控作业指令。
- **[HYDRA-UMC-BRIDGE-ROS2](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-ROS2)** —— 具备真实的惰性导入 rclpy ROS 2 传输层的安全协调器。
- **[HYDRA-UMC-BRIDGE-UAV](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-UAV)** —— 面向搭载摄像头的无人机的协调边界,具备真实的 MAVLink 指令发送器。

**直接相关**
- **[HYDRA-UMC-WATCH](https://github.com/JuanenRac/HYDRA-UMC-WATCH)** —— 具备真实触觉提醒与配对手机语音中继功能的 WearOS 伴侣应用;除了主板自身屏幕外,还能将警告传递到操作员手腕上的可穿戴安全警报设备,补充本触控面板。
- **[HYDRA-UMC-COGNITIVE-NODE](https://github.com/JuanenRac/HYDRA-UMC-COGNITIVE-NODE)** —— 面向 Hailo-10 认知流水线(LLM/VLA/语音编排)的集成中枢;直接在本触控面板上增加语音控制。
- **[HYDRA-UMC-VOICE-UI](https://github.com/JuanenRac/HYDRA-UMC-VOICE-UI)** —— 具备受限、需确认的 Watch 中继的真实语音前端(VAD + 意图解析);直接在本触控面板上增加语音控制。

**生态系统中的其他项目**

*核心硬件与平台*
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** —— 机器人手臂的真实主板——CM5 主机 + 双核 STM32H745,通过 CAN-OTA/SPI-OTA 协调最多 8 条工具臂。
- **[HYDRA-UMC-OS](https://github.com/JuanenRac/HYDRA-UMC-OS)** —— 面向 CM5 的可复现 Raspberry Pi OS 产品层——只读代理、经过验证的配置/配置文件、WiFi 首次配网。
- **[HYDRA-UMC-SDK](https://github.com/JuanenRac/HYDRA-UMC-SDK)** —— 每个桥接都据此校验自身指令的共享 JSON-Schema 契约与安全门限边界。

*核心后端与客户端*
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** —— 将完成的模型推送到 STUDIO 自身目录的桌面版图形化 URDF 创建/编辑工具。

*URTC 工具平台*
- **[URTC](https://github.com/JuanenRac/URTC)** —— 面向实体 Universal Robot Tool Controller 板卡的固件,通过 CAN 总线支持 25 种以上工具配置。
- **[URTC-FLASHER](https://github.com/JuanenRac/URTC-FLASHER)** —— 面向 URTC 板卡的桌面图形烧录工具,支持 CAN-OTA 以及全芯片 SWD/JTAG。
- **[URTC-TESTER](https://github.com/JuanenRac/URTC-TESTER)** —— 面向 URTC 板卡的桌面实时 CAN 总线诊断工具,每种工具配置对应一个面板。
- **[URTC-WEB-STUDIO](https://github.com/JuanenRac/URTC-WEB-STUDIO)** —— 通过 Web Serial API 实现的浏览器版 URTC-TESTER 替代方案,无需本地安装。

*视觉 AI 节点(Hailo-8)*
- **[HYDRA-UMC-VISION-NODE](https://github.com/JuanenRac/HYDRA-UMC-VISION-NODE)** —— 面向 Hailo-8 视觉流水线的集成中枢,具备逐阶段的真实硬件就绪检测。
- **[HYDRA-UMC-DETECTION-HEF](https://github.com/JuanenRac/HYDRA-UMC-DETECTION-HEF)** —— 具备 Hailo 架构/校验和安全加载验证的真实编译模型注册表。
- **[HYDRA-UMC-VISION-STREAMER](https://github.com/JuanenRac/HYDRA-UMC-VISION-STREAMER)** —— 具备真实 HailoRT 集成边界的真实 GStreamer 流水线 + MediaMTX 配置生成器。
- **[HYDRA-UMC-VISUAL-SERVOING-API](https://github.com/JuanenRac/HYDRA-UMC-VISUAL-SERVOING-API)** —— 具备真实 Position-Based Visual Servoing 修正律,并依据上游区域状态进行安全门控。
- **[HYDRA-UMC-SAFETY-ZONES](https://github.com/JuanenRac/HYDRA-UMC-SAFETY-ZONES)** —— 具备校准新鲜度强制检查的真实区域入侵检测与 E-STOP 请求。

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
- **[HYDRA-UMC-HIL-BRIDGE](https://github.com/JuanenRac/HYDRA-UMC-HIL-BRIDGE)** —— 在仿真与真实硬件之间路由指令的真实硬件在环安全联锁。
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

---

## 👤 作者
**JuanenRac** (Electro Hobby 3D)
📧 electrohobby3d@gmail.com
📺 [youtube.com/@electrohobby3d](https://youtube.com/@electrohobby3d)

## 📜 许可证

源代码采用 **GNU 通用公共许可证 v3.0（GPL-3.0）**——见 [`LICENSE`](LICENSE)。

文档（本 README 及其自身的翻译版本——`README_spa.md`、`README_ita.md`、`README_fra.md`、`README_deu.md`、`README_zho.md`、`README_jpn.md`）依据 **知识共享 署名-相同方式共享 4.0 国际许可协议（CC BY-SA 4.0）** 提供。完整文本见 https://creativecommons.org/licenses/by-sa/4.0/。
