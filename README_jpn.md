<!-- =============================================================================
HYDRA-UMC-DSI - Native touch UI for the CM5 DSI screen
Copyright (C) JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
GPL-3.0-or-later - see LICENSE
============================================================================= -->

<p align="center">
  <img src="images/HYDRA_UMC_BANNER.svg" alt="HYDRA-UMC-DSI banner" width="100%">
</p>

# 🖥️ HYDRA-UMC-DSI

<p align="center"><a href="README.md">🇺🇸 English</a> | <a href="README_spa.md">🇪🇸 Español</a> | <a href="README_fra.md">🇫🇷 Français</a> | <a href="README_ita.md">🇮🇹 Italiano</a> | <a href="README_deu.md">🇩🇪 Deutsch</a> | <a href="README_zho.md">🇨🇳 简体中文</a> | 🇯🇵 <b>日本語</b> | <a href="README_por.md">🇵🇹 Português</a></p>

### Compute Module 5 の DSI 画面向けネイティブのタッチ UI

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

Compute Module 5 上の HYDRA-UMC 自身の 5"/7" DSI タッチスクリーン向けのネイティブ Flutter タッチ UI（Dart、実際の Linux デスクトップターゲット）——2 つの物理パネルサイズはまったく同じ 1280x720 ピクセル解像度を共有しているため、本アプリは 2 つのサイズに適応させるのではなく、1 つの固定された非レスポンシブレイアウトを提供します。[HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)、[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)、[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) が使用しているのとまったく同じ [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-SERVER/blob/main/docs/REMOTE_API.md) 契約を話します——稼働中の [HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER) サーバーに対するディスカバリー、ログイン、原子的なロボットごとの指令、そしてリアルタイム WebSocket 同期を、ブラウザタブ経由ではなくボード自体の上で直接実行します。フルデザインは [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) を参照してください。Flutter を選んだ理由（Kivy ではなく）や、3D 画面が WebView ではない理由も含まれています。

**本アプリは、同じボード上に共存する 2 つの制御サーフェスのうちの 1 つです**——CM5 は、ブラウザ UI を実行する完全な外部モニター向けの HDMI 出力も同時に駆動します。この DSI アプリはそのパスを補完するもので、ボード自体に直接的で常時稼働するタッチコンソールを提供します。ブラウザ UI を置き換えるものではありません。

---

**正直な現状確認 - 今日実際に動くもの:** ネットワーク層(`lib/network/hydra_api_client.dart`、`hydra_websocket.dart`、`discovery.dart`、`auth_prefs.dart`)と状態層(`lib/state/robot_view_model.dart`、`hydra_error.dart`)は本物でテスト済みである(`test/*.dart` 全体で 208 件のテストが成功しており、モックではなく本物のローカルサーバーに対する本物の WebSocket 接続/再接続/認証拒否の往復テストも含む)。`flutter analyze` も問題を報告していない。カタログの 6 画面はすべて本物の配線されたUIであり、プレースホルダーではない。実際にまだ構築されていないもの: **3D View** 画面は本物の 3D レンダラーではなく、小さなネイティブの等角 X/Y/Z インジケーターにすぎない - STUDIO の本物の Three.js シーンは埋め込まれていない(Linux 版の `webview_flutter` 実装が存在しないため)。本物だが対象ハードウェアでは未検証のもの: `flutter build linux --release` は実行され、実際に起動することが確認されたバイナリを生成しているが、これは Ubuntu 24.04 WSL2(x86_64)上でのみであり、CM5 の実際の aarch64 Raspberry Pi OS 上では一度も実行されていない。また `kiosk/hydra-umc-dsi.service` の自動起動ユニットも、実際の Linux マシン上で一度も実行されたことがない。これまでに何が実際に出荷されたかは、下記の "Known Follow-ups" と `CHANGELOG.md` を参照。

> **安全性とセキュリティの現状:** このエコシステムは認証された安全システムではありません。ハードウェアの E-STOP 経路、ファームウェアが強制する制限やインターロック、検証済みの動作コマンドはまだありません。ファームウェアイメージは CRC-32 と Ed25519 署名で検査し、リリースビルドは公開済みの開発用鍵を拒否します(リレーの先のツールヘッドと拡張ボードは引き続き URTC のブートローダーを使い、署名ではなく共有鍵の HMAC-SHA256 を使います)。TLS と相互 TLS は任意で、既定では無効です。独自基板はまだ実装も試験もされていません。ここに書かれた内容を人の安全のために頼る前に、[セキュリティベースライン](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/SECURITY_BASELINE.md)と[脅威モデル](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/THREAT_MODEL.md)をお読みください。

---

## 📋 ひと目で

| | |
|---|---|
| バージョン | `0.2.8` |
| 成熟度 | 機能する |
| テスト | 208 (`flutter test`) |
| 技術 | Flutter 3.x / Dart |
| 対象 | HYDRA-UMC セルの Raspberry Pi CM5 |
| 実機での確認 | まだです：このバージョンについて実機での動作記録はありません |

**移動：** [概要](#-概要) · [アーキテクチャ](#-アーキテクチャ) · [クイックスタート](#-クイックスタート) · [テスト](#-テスト) · [リポジトリの構成](#-リポジトリの構成) · [関連プロジェクト](#-関連プロジェクト)

## 🚦 プロジェクトの状況

各行はこのリポジトリの一部分で、信号は今日どこまで進んでいるかを示します。計画ではなく、リポジトリが示せるもの（テスト、ビルド、実行）に基づいて書かれています。

🟢 完了・検証済み · 🟡 動作する（既知の制限あり） · 🟠 一部のみ、または未検証 · 🔴 未実装または動作しない

| 領域 | 状態 | ここでの意味 |
|---|---|---|
| ソフトウェア | 🟡 | 主な目的では動作します。足りない点は上の正直さの確認に書かれています |
| テスト | 🟢 | 自動テスト 208 件。変更のたびに実行されます |
| 実機 | 🔴 | まだです：このバージョンについて実機での動作記録はありません |
| ドキュメント | 🟢 | 8 言語の README。変更のたびにマニフェストと照合されます |

## 🎯 概要

- **ログイン**（`lib/ui/login_screen.dart`、`lib/state/robot_view_model.dart`）—— サーバー IP/ポートフィールドは妥当な LAN 既定値で事前入力済み、ユーザー名/パスワードフィールドはタッチ操作向けに調整され既定では空欄（ハードコードされた認証情報は事前入力されません——各サーバーが実運用での初回起動時にデフォルトアカウントを作成しなくなったのに合わせ、初期の `admin`/`admin` 事前入力は削除されました)、オペレーターが入力したアカウントに対する `POST /api/login`。追加の低権限「オペレーター」アカウントはブラウザ UI の Config > Users から作成可能です。セッショントークンはプラットフォームのセキュアストレージに保存されます（Linux では libsecret で、キーリングサービスが動作している必要があります。ない場合、セッションはアプリを再起動するまで有効で、その後ログインが再度求められます）。「ローカルネットワークをスキャン」ダイアログ（`lib/network/discovery.dart`）は、IP を事前に知らなくてもサーバーを見つけられます——本アプリが動作している CM5 自体が、それが接続すべきまさにそのコントローラーであることが多いため、ここでは特に有用です。
- **ネットワークディスカバリー**（`lib/network/discovery.dart`）—— 同じ「ローカルネットワークをスキャン」ダイアログから 2 つの経路が並行して動作します：実際の mDNS/Bonjour（`discoverMdns()`、`multicast_dns` パッケージ経由で `server.ts` 自身が公開する `_hydra._tcp` を照会）と、このデバイス自身の実際のローカルサブネットに対する `GET /api/hydra-info` の並行総当たりスキャン（`scanSubnets()`）——host:port で重複排除。HYDRA-UMC-IOS-CONTROL から移植されたもので、同アプリは本エコシステムで最初に実際の mDNS ディスカバリーを追加したクライアントです。
- **原子的な指令同期**（`lib/state/robot_view_model.dart` 自身の `_sendAtomicCommand()`）—— すべての書き込み（再生/一時停止/停止/ジョグ/バルブ/ポンプ/速度/ビジョン）は、実際の `POST /api/robot/:id/command` エンドポイントを使用し、正しい統合ロボット（`combinedWith`）の伝播、およびリクエストが失敗した場合の変更前スナップショットへのロールバックを備えています——実際のロボットから数フィート離れた場所にあるジョグペンダント/緊急停止にとって特に重要です。
- **リアルタイム WebSocket 同期**（`lib/network/hydra_websocket.dart`）—— トークンを `hydra.bearer` サブプロトコルで送り（アドレスには含めず）、`"settings"` と `"delta"` の両方のブロードキャストタイプを処理し、切断時には自動的に再接続します。
- **水平タッチナビゲーション**（`lib/ui/main_screen.dart`）—— 固定 1280px 幅にわたる、6 つの大きなアイコン+ラベルタブ（ダッシュボード/制御/カメラ/3D ビュー/指標/設定）からなる常設のトップバー。スマートフォン式のボトムナビゲーションバーというより、精神的には KlipperScreen に近いものです——プロジェクトオーナーが求めたカタログに一致させつつ、縦長のスマートフォンレイアウトではなく、横長のタッチパネル向けに再編成されています。
- **ダッシュボード**（`lib/ui/dashboard_screen.dart`）—— ロボットごとのカード、`Provider` によるリアルタイムの反応、LED の慣例（緑の点滅=アクティブ、赤の点灯=非アクティブ）、統合ロボット表示、モジュールチップ（CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK）——本エコシステム内の他のすべてのクライアントと同じビジュアル言語です。
- **手動制御**（`lib/ui/control_screen.dart`、`lib/ui/widgets/joystick_pad.dart`）—— 単一のスクロール列ではなく 1280x720 のフレームに合わせたサイズの左右配置レイアウト（左にジョグパッド、右にテレメトリ/速度/IO）、グローバル **STOP**（`lib/ui/widgets/stop_all.dart`）が各タブの上部バー、制御タブ、画面清掃オーバーレイに常時表示され、1 回のタップのみで（長押しも確認もなし）全ロボットを停止し（`POST /api/stop-all`）、結果をロボットごとに表示し（ロボットが失敗した場合や停止が保存されなかった場合は警告、他のアカウントが予約中のロボットには印）、ネットワークエラー時は 1 回再試行し、429 や古いサーバーではロボットごとの停止に切り替え、後の STOP が応答を得るまで「STOP 未確認」の表示を残します（丸いロボット単位の停止ボタンは長押し保護を維持）、速度/加速度スライダー、バルブ/ポンプのトグル。
- **予約と安全上限**（`lib/ui/widgets/access_panel.dart`、`lib/models/access.dart`、`lib/network/hydra_api_client.dart`、`lib/state/robot_view_model.dart`）- Control 画面は、選択したロボットを誰が保持しているか（誰も、この端末、別の端末の同じアカウント、別のアカウント）を表示し、**予約**と**解放**を提供し、サーバーのすべての予約の一覧（`GET /api/claims`）も表示します。端末はインストールごとにコントローラーIDを1つ保持し、予約・解放・ジョグのアーム・コマンドのたびにそれを送ります（本文と `X-Controller-Id` ヘッダー）。このため予約はアカウント全体ではなく、アカウントとこの端末に属します。サーバーの拒否は区別されます：別のアカウントが予約、あなたのアカウントが別の端末またはウィンドウで予約、コントローラーID必須、ジョグ未アーム。ロボットのモデルの上限は `GET /api/safety-limits` から読み取ります：上限を超えるジョグのステップは送信されず、サーバーの警告が表示されます。管理者が要求した場合は、ジョグでロボットを動かす前に**ジョグをアームする**（カウントダウン付き）を押す必要があり、アームは自動で、STOP で、または解放時に終了します。予約は任意です：誰も予約していないロボットはこれまでどおり操作できます。 **管理者**にのみ、他の人が予約しているロボットに **制御を引き継ぐ** ボタンが表示されます。確認を求めたうえで `force: true` でロボットを予約します (サーバーは管理者からのみ受け付け、ロールを再確認します)。 書き込みは条件付きです。各書き込みには、このアプリが最後に見たロボットのリビジョン(`If-Match`、`lib/models/contract_v2.dart`)が付き、その間に他の人がロボットを変更していた場合、サーバーは 412 を返し、何も適用されず、ロボットが読み直されてメッセージで知らされます(標準は予約、テーブル、単発のコマンドを確認、厳格は STOP 以外すべてを確認、オフは何も確認せず、選択は予約一覧の中にあり、STOP は確認されません)。XY テーブルのジョグはアトミックな `table` コマンド 1 回で(古いサーバーには理解できるジョグを送ります)、サーバーは WebSocket で予約を通知するため Control 画面は通知が届く間ポーリングを止め、管理者は監査記録(`lib/ui/widgets/audit_dialog.dart`)を、SHA-256 チェーンをサーバーとこのコンピューターで 2 回検証した状態で読め、その行を `.jsonl` としてコピーできます。
- **PLAY の前に確認** - 既定でオン、設定でオフにできます。軌道を開始する前に、ロボット、記録済みの点、速度、予約している人を表示します(他の人が予約しているロボットは、サーバーがコマンドを拒否することを伝えます)。すでに再生中のロボットでは再度確認しません。選択は保存されます。
- **カメラ**（`lib/ui/camera_screen.dart`、`lib/ui/widgets/mjpeg_view.dart`）—— HYDRA-UMC-IOS-CONTROL と同じ、手作りで依存関係のない MJPEG ストリームパーサー（WebView なし、プラットフォーム固有コードなし——Linux デスクトップ上でそのまま動作します）、明確な「カメラ無効」状態、そしてサーバーから直接ロボットのビジョンシステムをオン/オフする切り替えスイッチ。
- **3D ビュー**（`lib/ui/three_d_screen.dart`）—— iOS/Android アプリとは異なり、STUDIO の実際の Three.js シーンを埋め込む WebView では**ありません**——`webview_flutter` には Linux デスクトップ実装がまったく存在せず、フルブラウザエンジンはこの低消費電力の組み込みパネルが必要とする以上に重いランタイム負荷になります。代わりに：小さなネイティブの等角 X/Y/Z 位置インジケーター（`CustomPainter`、3D エンジンなし）と、本ボード自身の HDMI 接続モニター上にある実際の 3D シーンを指し示す画面上の注記。完全な理由は `docs/ARCHITECTURE.md` 第 4 節を参照してください。
- **システム指標**（`lib/ui/metrics_screen.dart`）—— iOS/Android のようにダッシュボードに折りたたまれるのではなく、専用のタブを持ち、`GET /api/system/metrics` からの CPU/メモリ/温度/稼働時間タイルと、`GET /api/hydra-info` からのホスト名/コントローラー数/ロボット数/アプリバージョンを表示します。
- **設定**（`lib/ui/settings_screen.dart`）—— 接続情報、サーバー識別情報、サインアウト、そして本アプリ自身のバージョン（下記の[バージョン管理](#バージョン管理)参照）。
- **キオスク自動起動**（`kiosk/hydra-umc-dsi.service`、`kiosk/install_kiosk.sh`）—— `cage` 経由で `tty1` 上に本アプリをフルスクリーン起動する systemd ユニット、`Restart=always`。詳細は下記「実際の CM5 上での実行」を参照してください。ローカル画面は一度に 1 つだけです。設定 `HYDRA_LOCAL_SCREEN` が `dsi` のときだけインストーラーが本アプリをインストールします（`sudo kiosk/install_kiosk.sh --screen dsi` で `/etc/hydra-umc/local-screen.conf` に保存）。既定は HYDRA-UMC-OS の HDMI キオスクである `hdmi` で、`none` は `tty1` を誰にも割り当てないため、2 つのキオスクが同時に `tty1` を要求することはありません。実際の CM5 ではまだ実行していません。
- **8言語対応UI**（`lib/l10n/`、標準の `flutter gen-l10n` パイプライン）—— 英語・スペイン語・フランス語・ドイツ語・イタリア語・日本語・中国語・ポルトガル語に対応し、このエコシステムの他のクライアントと同じです。`設定 > 言語` に保存される上書き設定はデフォルトでOSのロケールに従います。`RobotViewModel.lastError` は整形済みの英語テキストではなく型付きの `HydraError` になっているため、ビジネスロジック側のエラーメッセージも画面の静的なテキストと同様に正しくローカライズされます。

**状態：雛形 + 全 6 のカタログ画面が実装され、実際の REMOTE_API.md 契約に接続済み。** `flutter analyze` はクリーン、`flutter build windows` と `flutter build linux`(WSL2 経由)はどちらも動作するバイナリを生成し、`flutter test` はパスします——何が検証済みで何がまだかの正確な内容(この WSL2 検証と実際の CM5 実機との間に残るギャップも含む)は、下記「ビルド」を参照してください。

**ローカル画面は一度に一つ、接続者、サーバーのアクセスオプション。** キオスクのインストーラーは、設定 `HYDRA_LOCAL_SCREEN` が `dsi` のときだけアプリをインストールします（`sudo kiosk/install_kiosk.sh --screen dsi` で `/etc/hydra-umc/local-screen.conf` に保存）。既定は HYDRA-UMC-OS の HDMI キオスクである `hdmi` で、`none` はコンソールを誰にも割り当てないため、2 つのキオスクが同時に `tty1` を取り合うことはありません（`tools/verify_kiosk_screen.py` がスタブで試験。CM5 では未実行）。アクセスパネルの「接続」ボタンは、サーバーが見たアプリの簡単な一覧と、最近のサインイン、拒否されたサインイン、サインアウト、終了したセッションを開きます（管理者はすべての項目を、その他のアカウントは自分の分だけを見ます。パスワードもトークンもなく、アドレスはサーバーが保存する場合だけ）。管理者には 2 つ目のボタンがあり、サーバー設定から読んだ 7 つのスイッチを開きます（サインインなしのヘルスルート、グローバル停止の通知、クライアントのアドレスの保存、チケットなしのカメラ映像、WebSocket アドレス内のトークン、ログの秘密情報の伏せ字、音声確認の署名）。それぞれ値の出どころを表示し、変更した分だけを送り、保護を下げる変更は先に確認を求めます。テキストは 8 言語です。

## 🧩 HYDRA-UMC での役割

**HYDRA-UMC-DSI** は CM5 自身のタッチ画面です。5"/7" の DSI パネル向けのネイティブ Flutter アプリで、`HYDRA-UMC-STUDIO` のブラウザー UI と並んで、REST と WebSocket で `HYDRA-UMC-SERVER` と通信します。ロボットのロジックは持たず、何が許されるかはサーバーが決めます。

## 🏛️ アーキテクチャ

<p align="center">
  <img src="images/architecture.svg" alt="HYDRA-UMC-DSI architecture" width="100%">
</p>

## 🚀 クイックスタート

Linux デスクトップ対応の安定版 Flutter SDK（3.x）が必要です。

```bash
flutter pub get
./run_dev.sh      # desktop simulation, no hardware (run_dev.bat on Windows)
./build_linux.sh  # on a Linux machine or the CM5: the real target
```

## 🧪 テスト

`flutter test` で自動テスト 208 件を実行します。 ハードウェアも、このマシンの外にあるものも必要ありません。

CI は `HYDRA_UMC_CI=1 python tools/ci_validate.py` を実行し、マニフェスト、文書、8 つの README、図を検査します。

## 🏗️ ビルドとリリース

[Flutter SDK](https://docs.flutter.dev/get-started/install)（stable チャンネル）が必要です。本リポジトリは Flutter 3.47.0 に対してビルド/検証されています。本リポジトリでは `linux/` と `windows/` のみがプラットフォームとして設定されています（`android/`、`ios/`、`web/`、`macos/` フォルダはありません）——Linux が実際のターゲットです（CM5 自身の OS）。Windows は、Linux ツールチェーンのないマシンでもこのアプリ自身のロジックをビルド、実行、テストできるようにするためだけに存在します。

### ビルドスクリプト

```bash
./build.sh          # Git Bash / WSL、または cmd/PowerShell 用の build.bat —— flutter pub get + flutter build windows（開発機での検証）
./build_linux.sh    # 実際の Linux マシン（または CM5 自体）上で実行する必要があります —— flutter pub get + flutter build linux（実際のデプロイ先）
./run_dev.sh         # Git Bash / WSL、または cmd/PowerShell 用の run_dev.bat —— デスクトップシミュレーションモード（flutter run）、ハードウェア不要
```

3 つのビルドスクリプト（`build.sh`/`build.bat`/`build_linux.sh`）はいずれもアプリのバージョンを変更しません——下記の[バージョン管理](#バージョン管理)参照。`run_dev.sh`/`run_dev.bat` は加算しません——このポリシーの下では、開発ループの `flutter run` は「実際のビルド」ではありません。

### 手動ビルド

```bash
flutter pub get
flutter analyze                  # 静的解析——コンパイラ不要
flutter test                     # ウィジェットテスト
dart run tool/bump_version.dart  # バージョンを加算、build.sh/build.bat/build_linux.sh が行うのと同じ
flutter build windows            # 開発機でのスモークテスト——build/windows/x64/runner/Release/hydra_umc_dsi.exe を生成
flutter build linux              # 実際のターゲット——実際の Linux マシン上で実行する必要があります。build/linux/*/release/bundle/ を生成
flutter run -d windows           # または実際の Linux マシン上で -d linux、ライブなデスクトップシミュレーション開発ループ用
```

**Linux 検証に関する正直な注記：** `flutter build linux --release` は、実際の Linux デスクトップツールチェーン(`cmake`、`ninja-build`、`libgtk-3-dev`、`clang`)を備えた本物の Ubuntu 24.04 WSL2 環境から、このコードに対して実際に実行されるようになりました——クリーンにビルドが通り、本物の `build/linux/x64/release/bundle/hydra_umc_dsi` を生成し、実際に起動することも確認済みです(実際の X11 ディスプレイ上で動作し続け、終了コード 0 だけではありません)。単なるスモークテストの代替としての `flutter build windows` にとどまりません。これが**カバーしていない**もの:WSL2 のユーザースペースは x86_64 であり、CM5 の実際の aarch64 の Raspberry Pi OS ではないこと、そして `kiosk/hydra-umc-dsi.service` の自動起動フローは依然として実際の Linux マシン上で一度も実行されていないことです。何が検証され何が検証されなかったかの正確なリストは `docs/ARCHITECTURE.md` 第 7 節を、残っている作業は下記の「既知のフォローアップ」を参照してください。

### バージョン管理

このリポジトリはエコシステム全体の方針に従います：ビルドはバージョンを一切変更しません。明示的な `bump` コマンド（`python tools/hydra_project_tool.py bump`）が `bump_manifest_version.py` を実行し、`pubspec.yaml` のバージョンを上げ（`+` の後のビルド番号は単純な単調カウンターで、bump のたびに +1、繰り上がりなし）、マニフェストを同期させます。また `lib/app_version.dart`（生成物であり、手作業で編集されるものではありません）も再生成され、アプリは実行時にこれを読み取って **Settings** 画面に自身のバージョンを表示します。バージョン履歴は [CHANGELOG.md](CHANGELOG.md) を参照してください。

## 📂 リポジトリの構成

<p align="center">
  <img src="images/repository-structure.svg" alt="Repository structure of HYDRA-UMC-DSI" width="100%">
</p>

<details>
<summary>ツリーのテキスト版</summary>

```text
HYDRA-UMC-DSI/
├── lib/                                                              ソースコード
│   ├── main.dart                                                     アプリのエントリポイント、ChangeNotifierProvider + ログインゲート、固定ダークテーマ
│   ├── app_version.dart                                              生成物——bump_manifest_version.py によって再生成される、手動編集禁止
│   ├── models/                                                       データモデルと純粋なルール
│   ├── network/                                                      REST クライアント、WebSocket、探索
│   ├── state/                                                        すべての画面が監視する状態
│   ├── services/                                                     アプリのサービス（バックライト）
│   ├── l10n/                                                         8 言語のローカライズ
│   ├── util/                                                         専用画面を持たない補助機能
│   └── ui/                                                           画面とウィジェット
├── kiosk/                                                            キオスクのユニットとインストーラー
├── linux/                                                            GTK デスクトップランナー——実際のターゲット、固定 1280x720 ウィンドウ
├── windows/                                                          Windows デスクトップランナー——開発機での検証専用
├── tools/                                                            プロジェクトのツールと CI の検査
├── test/                                                             widget_test、format_uptime_test、localization_test、robot_view_model_test、robot_view_model_silent_refresh_test、auth_prefs_test、hydra_websocket_test、hostile_answers_test、hydra_error_test, play_confirmation_test, stop_long_press_test
├── .github/                                                          CI ワークフローと Issue テンプレート
├── images/                                                           バナーと README の図
├── build.bat / build.sh                                              flutter pub get + バージョン加算 + flutter build windows（開発機での検証）
├── build_linux.sh                                                    flutter pub get + flutter build linux（実際の CM5 ターゲット——実際の Linux 上で実行）
├── run_dev.bat / run_dev.sh                                          flutter run —— デスクトップシミュレーションモード
├── CHANGELOG.md                                                      各バージョンの変更点
├── docs/ARCHITECTURE.md                                              プロジェクトのアーキテクチャ
├── bump_manifest_version.py                                          hydra-umc.project.json のバージョンをネイティブ版と同期(--sync)
├── pubspec.yaml / pubspec.lock / l10n.yaml / analysis_options.yaml   Flutter パッケージの定義とロックされたバージョン、l10n ジェネレーターの設定、lint ルール
├── build-test.sh                                                     変更を伴わないビルド確認
├── hydra-umc.project.json                                            マニフェスト：バージョン、成熟度、ファミリー
└── test.sh                                                           テストを実行
```

</details>

## 🗺️ ロードマップと既知の制限

**現時点の既知の制限**

このアプリのコードに実際に残っている、検証済みのギャップです——曖昧な TODO ではなく、それぞれ上記のコードまたはドキュメントの具体的な箇所に対応しています。

- **リモートアクセスの切り替えはまだ独立していません** —— `REMOTE_API.md` の第 1 節では `X-Hydra-Client` の値として `suite`、`android`、`ios` のみが認識されます。本アプリは `dsi` を送信しますが、これは認識されない値であり、現状では常にフィルタなしで通過します。修正には HYDRA-UMC-STUDIO 自身の `SystemSettings.remoteAccess` 型と Config > Remote Access タブへの 4 つ目のトグルの追加が必要です——これは別リポジトリのサーバーコードへの変更であり、本リポジトリの範囲外です。`docs/ARCHITECTURE.md` 第 3 節を参照してください。
- **3D View に実際のネイティブ 3D レンダラーはありません** —— `ui/three_d_screen.dart` は現在、STUDIO の実際の Three.js シーンを埋め込む代わりに、小さな等角投影の X/Y/Z 位置インジケーターを描画しています（`webview_flutter` には Linux 実装が存在しません——詳しい理由は `docs/ARCHITECTURE.md` 第 4 節を参照）。この画面向けの実際のネイティブ 3D レンダラーは今後の課題であり、着手されていません。
- **実際の CM5 実機での実行はまだ行われていません** —— `flutter build linux` 自体は既に検証済みです(実際の Ubuntu 24.04 WSL2 ツールチェーン、バイナリが実際に起動することを確認済み——`docs/ARCHITECTURE.md` 第 7 節参照)が、`build_linux.sh` の一連の流れと自動起動ユニット `kiosk/hydra-umc-dsi.service` は、CM5 自体や他の実際の(非 WSL2)Linux マシンに対しては依然として一度も実行されていません。そこで初めて実行する人は、それを形式的なものとしてではなく、このプラットフォームターゲットの実際の初回ハードウェアデプロイとして扱うべきです——上記の「実際の CM5 上での実行」を参照してください。

## 🌍 言語

この README とリポジトリの文書は、英語・スペイン語・ドイツ語・フランス語・イタリア語・日本語・中国語・ポルトガル語（ポルトガル）の 8 言語で提供されています。8 つのファイルは同時に書かれ、同じ節と同じリンクを持つことを CI が確認します。

## 🔗 関連プロジェクト

本プロジェクトは、同じ作者(JuanenRac / Electro Hobby 3D)による HYDRA-UMC ロボティクスエコシステムの一部です。リクエストが実はこの中のどれかについてのものである可能性があるため、知っておく価値があります。

**親プロジェクト**
- **[HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)** — すべての制御クライアントが実際に通信する、本物のヘッドレスバックエンド(REST/WebSocket)。本パネルが実際の `REMOTE_API.md` 契約(ディスカバリー、ログイン、アトミックコマンド、WebSocket 同期)経由で接続するサーバー。

**兄弟プロジェクト** —— それぞれ独自のクライアントとして、同じく HYDRA-UMC-SERVER 自身の API と通信する
- **[HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — リアルタイムのマルチロボット 3D 可視化を備えたウェブ制御ダッシュボード。
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** — 複数のサーバーを同時に扱えるデスクトップ(PySide6)スウォームコマンドセンター、スタンドアロン実行ファイルとしてパッケージ化。本パネルとまったく同じ `REMOTE_API.md` 契約を話す。
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** — 生体認証ログインとペアリングされた Wear OS コンパニオンを備えたネイティブ Android 制御アプリ。本パネルとまったく同じ `REMOTE_API.md` 契約を話す。
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — リアルタイム WebSocket 同期を備えた iOS/iPadOS 制御アプリ(Flutter)。本パネルとまったく同じ `REMOTE_API.md` 契約を話し、本パネル自身の実際の mDNS ディスカバリーはここから移植された。
- **[HYDRA-UMC-BRIDGE-AMR](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-AMR)** — VDA 5050 MQTT パブリッシャーによる AGV/AMR フリートの調整境界(エミュレートしたフリートに対してのみテスト済み)。
- **[HYDRA-UMC-BRIDGE-CNC](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-CNC)** — GRBL ステータス/制御バイトへのアクセスを持つ、CNC セルの高レベルコーディネーター(エミュレーターに対してのみテスト済み)。
- **[HYDRA-UMC-BRIDGE-DROIDS](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-DROIDS)** — Boston Dynamics Spot コマンド送信機能を持つ、脚型/ヒューマノイドドロイドの調整境界(エミュレーターに対してのみテスト済み)。
- **[HYDRA-UMC-BRIDGE-LASER](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-LASER)** — キー/筐体/インターロックの GPIO 信号 3 系統を読み取るレーザーセルのコーディネーター(模擬チップに対してのみテスト済み。レーザーの武装や発射はできない)。
- **[HYDRA-UMC-BRIDGE-OPENPNP](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-OPENPNP)** — OpenPnP ピックアンドプレースの基板フローを安全に統括する高レベルコーディネーター。
- **[HYDRA-UMC-BRIDGE-PRINTER3D](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-PRINTER3D)** — 実際にゲート制御されたジョブコマンドを持つ、Moonraker/Klipper 3D プリンター向けの安全な調整境界。
- **[HYDRA-UMC-BRIDGE-ROS2](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-ROS2)** — 遅延インポートの rclpy ROS 2 トランスポートを持つコーディネーター(ROS 2 環境ではまだ実行していない)。
- **[HYDRA-UMC-BRIDGE-UAV](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-UAV)** — MAVLink コマンド送信機能を持つ、カメラ搭載 UAV の調整境界(エミュレーターに対してのみテスト済み)。

**直接関連**
- **[HYDRA-UMC-WATCH](https://github.com/JuanenRac/HYDRA-UMC-WATCH)** — 触覚アラートのパターンとペアリング済みスマートフォンへの音声リレーを備えた WearOS コンパニオンアプリ(物理的なウォッチではまだ実行していない)。基板自身の画面に加えて、警告をオペレーターの手首に届けるウェアラブル安全アラート機器で、この本タッチパネルを補完する。
- **[HYDRA-UMC-COGNITIVE-NODE](https://github.com/JuanenRac/HYDRA-UMC-COGNITIVE-NODE)** — Hailo-10 コグニティブパイプライン(LLM/VLA/音声オーケストレーション)の統合ハブ。本タッチパネルに直接音声制御を追加する。
- **[HYDRA-UMC-VOICE-UI](https://github.com/JuanenRac/HYDRA-UMC-VOICE-UI)** — 確認ゲート付きの限定的な Watch リレーを備えた、実際の音声フロントエンド(VAD + 意図解析)。本タッチパネルに直接音声制御を追加する。
- **[HYDRA-UMC-LOCAL-TECHNICIAN](https://github.com/JuanenRac/HYDRA-UMC-LOCAL-TECHNICIAN)** — エコシステム自身のための、ローカルでポリシーゲート付きのAIメンテナンス技術者 — 観察、診断し、修正を提案する;最上位の2つのリスクレベルは意図的にまだ実装されていない。

**エコシステムの他のプロジェクト**

*コアハードウェア&プラットフォーム*
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** — ロボットアームのマザーボードの設計——CM5 ホスト + デュアルコア STM32H745、CAN-OTA/SPI-OTA 経由で最大 8 本のツールアームを統括することを目指す(ファームウェアは初期段階で、実装済みの基板はまだない)。
- **[HYDRA-UMC-OS](https://github.com/JuanenRac/HYDRA-UMC-OS)** — CM5 向けの再現可能な Raspberry Pi OS プロダクト層——読み取り専用エージェント、検証済み設定/プロファイル、WiFi 初回接続プロビジョニング。
- **[HYDRA-UMC-SDK](https://github.com/JuanenRac/HYDRA-UMC-SDK)** — すべてのブリッジが自身のコマンドを検証する共有 JSON-Schema 契約とソフトウェアのジョブゲート境界(認証済みの安全機能ではない)。
- **[HYDRA-UMC-CONNECTOR-HUB](https://github.com/JuanenRac/HYDRA-UMC-CONNECTOR-HUB)** — 外部マシン用コネクタのための宣言的アダプターマニフェストのレジストリとバリデーター。SDK 自身の契約という発想を外部マシンにまで拡張し、産業用ゲートウェイ系のプロジェクトを置き換えることはありません。

*コアバックエンド&クライアント*
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** — 完成したモデルを STUDIO 自身のカタログへ送信するデスクトップ用グラフィカル URDF 作成/編集ツール。
- **[HYDRA-UMC-EDITOR-STL](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-STL)** — HYDRA-UMC-EDITOR-URDF も編集する同じモデルカタログ内で、実在するパーツを変換/置換/削除/追加するデスクトップ STL モデルエディタ。

*URTC ツールプラットフォーム*
- **[URTC](https://github.com/JuanenRac/URTC)** — 物理的な Universal Robot Tool Controller 基板向けファームウェア、CAN バス経由の 25 以上のツールプロファイル。
- **[URTC-FLASHER](https://github.com/JuanenRac/URTC-FLASHER)** — URTC 基板用のデスクトップ GUI 書き込みツール、CAN-OTA およびフルチップ SWD/JTAG。
- **[URTC-TESTER](https://github.com/JuanenRac/URTC-TESTER)** — URTC 基板向けのデスクトップ CAN バスライブ診断ツール、ツールプロファイルごとに 1 パネル。
- **[URTC-WEB-STUDIO](https://github.com/JuanenRac/URTC-WEB-STUDIO)** — Web Serial API を使ったブラウザベースの URTC-TESTER の代替、ローカルインストール不要。
- **[URTC-GATEWAY](https://github.com/JuanenRac/URTC-GATEWAY)** — URTC の CAN バスの前に置くゲートウェイ：許可する識別子のリスト、レート制限、セッション鍵。コンピューター上でテスト済みで、実際のバスではまだ試していません。

*ビジョン AI ノード(Hailo-8)*
- **[HYDRA-UMC-VISION-NODE](https://github.com/JuanenRac/HYDRA-UMC-VISION-NODE)** — Hailo-8 ビジョンパイプラインの統合ハブ、段階ごとの実際のハードウェア準備状況チェック付き。
- **[HYDRA-UMC-DETECTION-HEF](https://github.com/JuanenRac/HYDRA-UMC-DETECTION-HEF)** — Hailo アーキテクチャ/チェックサムによる安全読み込み検証を備えた、実際のコンパイル済みモデルレジストリ。
- **[HYDRA-UMC-VISION-STREAMER](https://github.com/JuanenRac/HYDRA-UMC-VISION-STREAMER)** — 実際の HailoRT 統合境界を持つ、実際の GStreamer パイプライン + MediaMTX 設定生成器。
- **[HYDRA-UMC-VISUAL-SERVOING-API](https://github.com/JuanenRac/HYDRA-UMC-VISUAL-SERVOING-API)** — ゾーン状態を条件に承認する Position-Based Visual Servoing 補正則。カメラによる姿勢推定はまだない。
- **[HYDRA-UMC-SAFETY-ZONES](https://github.com/JuanenRac/HYDRA-UMC-SAFETY-ZONES)** — ファイルから物体位置を受け取る、ゾーン侵入・キャリブレーション鮮度・E-STOP 要求の v0 ロジック。検出器は接続されておらず、物理 E-STOP もまだ配線されていない。

*コグニティブ AI ノード(Hailo-10)*
- **[HYDRA-UMC-VLA-ENGINE](https://github.com/JuanenRac/HYDRA-UMC-VLA-ENGINE)** — Vision-Language-Action モデル向けの、実際のアクショントークンのエンコード/デコードと軌道生成。
- **[HYDRA-UMC-SEMANTIC-PLANNER](https://github.com/JuanenRac/HYDRA-UMC-SEMANTIC-PLANNER)** — MCU エラーコードに対する、実際のルールベースのタスク分解と意味的エラー復旧。
- **[HYDRA-UMC-DOCS-QA](https://github.com/JuanenRac/HYDRA-UMC-DOCS-QA)** — このエコシステム自身の Markdown ドキュメントに対する、標準ライブラリのみの実際の TF-IDF 文書検索。

*オーケストレーション&スウォーム*
- **[HYDRA-UMC-ORCHESTRATOR](https://github.com/JuanenRac/HYDRA-UMC-ORCHESTRATOR)** — 実際の gRPC/Protobuf ヘルスレポート契約とミッションステートマシンを持つ統合ハブ。
- **[HYDRA-UMC-JOB-DISPATCHER](https://github.com/JuanenRac/HYDRA-UMC-JOB-DISPATCHER)** — 実際の HTTP API 上に構築された、優先度ベースの実際のジョブキュー(重複排除付き)。
- **[HYDRA-UMC-NODE-HEALING](https://github.com/JuanenRac/HYDRA-UMC-NODE-HEALING)** — リトライ/バックオフとアイデンティティ不一致検出を備えた、実際の gRPC ベースのフリートヘルスウォッチドッグ。
- **[HYDRA-UMC-PATH-PLANNER-3D](https://github.com/JuanenRac/HYDRA-UMC-PATH-PLANNER-3D)** — 実際の障害物/ワークスペース衝突検証を備えた、実際の RRT ベースの 3D 経路プランナー。
- **[HYDRA-UMC-SWARM-SYNC](https://github.com/JuanenRac/HYDRA-UMC-SWARM-SYNC)** — 複数セルの収束についてプロパティテストされた、実際の CRDT LWW-Element-Map 状態同期。

*デジタルツイン&シミュレーション*
- **[HYDRA-UMC-TWIN](https://github.com/JuanenRac/HYDRA-UMC-TWIN)** — 実際のバージョン互換性同期契約を持つ、デジタルツインエンジンの統合ハブ。
- **[HYDRA-UMC-HIL-BRIDGE](https://github.com/JuanenRac/HYDRA-UMC-HIL-BRIDGE)** — シミュレーションと実機の間にソフトウェアの衝突インターロックを備えたハードウェア・イン・ザ・ループのルーター(実機なしでテスト済み)。
- **[HYDRA-UMC-PHYSICS-REPLICA](https://github.com/JuanenRac/HYDRA-UMC-PHYSICS-REPLICA)** — 実際の URDF サブセットに対する、実際の順運動学と関節限界検証。
- **[HYDRA-UMC-SYNTHETIC-DATA-GEN](https://github.com/JuanenRac/HYDRA-UMC-SYNTHETIC-DATA-GEN)** — YOLO/COCO アノテーションのエクスポート機能を持つ、実際のプロシージャル 2D シーンジェネレーター。

*データ&分析*
- **[HYDRA-UMC-DATALAKE](https://github.com/JuanenRac/HYDRA-UMC-DATALAKE)** — 実際の取り込み/クエリ HTTP API を備えた、実際の sqlite3 ベースの時系列ストア。
- **[HYDRA-UMC-ANOMALY-DETECTOR](https://github.com/JuanenRac/HYDRA-UMC-ANOMALY-DETECTOR)** — ドリフト監視を備えた、実際の FFT + 統計ベースラインによる異常検知器。
- **[HYDRA-UMC-PRODUCTION-REPORTS](https://github.com/JuanenRac/HYDRA-UMC-PRODUCTION-REPORTS)** — DATALAKE の履歴に対する実際の OEE/稼働率計算、再現可能な CSV エクスポート付き。
- **[HYDRA-UMC-TELEMETRY-COLLECTOR](https://github.com/JuanenRac/HYDRA-UMC-TELEMETRY-COLLECTOR)** — シーケンス重複排除機能を備えた、DATALAKE への実際の CAN/WebSocket 取り込みパイプライン。

*産業用ゲートウェイ*
- **[HYDRA-UMC-GATEWAY-INDUSTRIAL](https://github.com/JuanenRac/HYDRA-UMC-GATEWAY-INDUSTRIAL)** — 実際のコマンド許可リスト/バックプレッシャー層を持つ、産業用プロトコルへ中継する統合ハブ。
- **[HYDRA-UMC-OPCUA-SERVER](https://github.com/JuanenRac/HYDRA-UMC-OPCUA-SERVER)** — 実際のバイナリプロトコルクライアントセッションで検証された、実際の OPC-UA アドレス空間。
- **[HYDRA-UMC-MQTT-BROKER](https://github.com/JuanenRac/HYDRA-UMC-MQTT-BROKER)** — クライアント単位のオプション認証とトピック ACL を備えた、実際の MQTT ブローカー。
- **[HYDRA-UMC-MTCONNECT-ADAPTER](https://github.com/JuanenRac/HYDRA-UMC-MTCONNECT-ADAPTER)** — 縮退モード出力を備えた、実際の MTConnect `/probe` および `/current` XML エンドポイント。

*補完ツール&エコシステム運用*
- **[HYDRA-UMC-DASHBOARD-AI](https://github.com/JuanenRac/HYDRA-UMC-DASHBOARD-AI)** — 誠実な統計フォールバックを備えた、DATALAKE/ANOMALY-DETECTOR 上のスマートサマリーと異常ハイライトパネル。
- **[HYDRA-UMC-TOOL-CLI](https://github.com/JuanenRac/HYDRA-UMC-TOOL-CLI)** — 実際の安定した終了コード契約を持つフリート CLI、HYDRA-UMC-SERVER 自身の API の本物のライブクライアント。
- **[URTC-SMART-RACK](https://github.com/JuanenRac/URTC-SMART-RACK)** — 実際の工具 ID デコードと Smart Idle 予熱ロジックを備えた、基板搭載ラック用ファームウェア。
- **[URTC-VISION-TOOL](https://github.com/JuanenRac/URTC-VISION-TOOL)** — サーマル/RGB 検査ツールヘッド向けの、ファームウェアと実際の Python ビジョンコンパニオン。
- **[HYDRA-UMC-UPDATER](https://github.com/JuanenRac/HYDRA-UMC-UPDATER)** — このエコシステム内のすべてのリポジトリを検出・クローン・更新する、管理用デスクトップツール。
- **[HYDRA-UMC-OS-REBUILDER](https://github.com/JuanenRac/HYDRA-UMC-OS-REBUILDER)** — エコシステムの最新バージョンをプリロードした、書き込み可能なCM5イメージを構築するWindows/Linuxデスクトップツール。Raspberry Pi Imager方式の初回起動Wi-Fi/ユーザー/SSH設定を備える。
- **[HYDRA-UMC-OPS-AGENT](https://github.com/JuanenRac/HYDRA-UMC-OPS-AGENT)** — 保守インシデントコーディネーター: 低権限のエッジ役割がサニタイズされたインベントリ/ヘルスのスナップショットを収集し、コントロールプレーン役割がそれを読み取り専用でレンダリングして AI プロバイダーに診断の提案を依頼します - パッチを適用することも、何かをデプロイすることも決してありません。
- **[HYDRA-UMC-DEV-SERVER](https://github.com/JuanenRac/HYDRA-UMC-DEV-SERVER)** — 再現可能な開発ホスト（Raspberry Pi 5 / CM5）。エコシステムのソースコードを保管し、永続キューのもとで境界の明確なビルド/テストタスクを実行する。運用中の CM5 とは明確に異なる、開発専用の役割。

## 📚 ドキュメント

さらに読むには：

* [エコシステムのセキュリティ基準](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/SECURITY_BASELINE.md)
* [エコシステムの脅威モデル](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/THREAT_MODEL.md)
* [このリポジトリの変更履歴](CHANGELOG.md)
* [このリポジトリのライセンス](LICENSE.md)

## 🤝 コントリビュートとコミュニティ

* プルリクエストの前に `HYDRA_UMC_CI=1 py -3 tools/ci_validate.py`（または `HYDRA_UMC_CI=1 python3 tools/ci_validate.py`）を実行してください。`CI_VALIDATION=PASS` と表示される必要があります。この確認に `build.sh` や `build.bat` は使わないでください。ビルドは検査ではありません。
* 8 つの README は HYDRA-UMC-DOCS の 1 つのソースから書かれます。手で編集しないでください。ソースを変更し、`tools/make_readmes.py` で書き直します。
* 実行していないことを README に書かないでください。事実であれば「シミュレーションのみ」「実機では未確認」と書きます。
* [CONTRIBUTING.md](CONTRIBUTING.md)、[行動規範](CODE_OF_CONDUCT.md)、[SECURITY.md](SECURITY.md)、[SUPPORT.md](SUPPORT.md) を参照してください。

## 👤 作者

**JuanenRac (Electro Hobby 3D)** · electrohobby3d@gmail.com

## 📜 ライセンス

GPL-3.0-or-later - [LICENSE](LICENSE).
