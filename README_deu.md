<!-- =============================================================================
HYDRA-UMC-DSI - Native touch UI for the CM5 DSI screen
Copyright (C) JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
GPL-3.0-or-later - see LICENSE
============================================================================= -->

<p align="center">
  <img src="images/HYDRA_UMC_BANNER.svg" alt="HYDRA-UMC-DSI banner" width="100%">
</p>

# 🖥️ HYDRA-UMC-DSI

<p align="center"><a href="README.md">🇺🇸 English</a> | <a href="README_spa.md">🇪🇸 Español</a> | <a href="README_fra.md">🇫🇷 Français</a> | <a href="README_ita.md">🇮🇹 Italiano</a> | 🇩🇪 <b>Deutsch</b> | <a href="README_zho.md">🇨🇳 简体中文</a> | <a href="README_jpn.md">🇯🇵 日本語</a> | <a href="README_por.md">🇵🇹 Português</a></p>

### Eine native Touch-Oberfläche für den DSI-Bildschirm des Compute Module 5

<p align="center">
  <img src="https://img.shields.io/badge/License-GPL%203.0--or--later-blue.svg" alt="GPL 3.0 or later">
  <img src="https://img.shields.io/badge/Framework-Flutter%203.x-02569B.svg" alt="Framework">
  <img src="https://img.shields.io/badge/Language-Dart-0175C2.svg" alt="Language">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20CM5-E34F26.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Tests-203%20passing-2ea44f.svg" alt="Tests">
  <img src="https://img.shields.io/badge/Version-0.2.7-0f6cbd.svg" alt="Version">
  <img src="https://img.shields.io/badge/Maturity-functional-0F6CBD.svg" alt="Maturity">
</p>

---

Eine native Flutter-Touch-UI (Dart, mit echtem Linux-Desktop-Ziel) für HYDRA-UMCs eigenen 5"/7"-DSI-Touchscreen am Compute Module 5 - beide physischen Panelgrößen teilen sich exakt dieselbe Auflösung von 1280x720 Pixeln, weshalb diese App ein einziges, festes, nicht responsives Layout verwendet, statt sich an zwei Größen anzupassen. Sie spricht genau denselben [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-SERVER/blob/main/docs/REMOTE_API.md)-Vertrag wie [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE), [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) und [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) - Discovery, Login, atomare Befehle pro Roboter und Live-Synchronisation per WebSocket mit einem laufenden [HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)-Server, direkt auf der Platine selbst ausgeführt statt in einem Browser-Tab. Siehe [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) für das vollständige Design, einschließlich der Begründung für Flutter (statt Kivy) und warum der 3D-Bildschirm keine WebView verwendet.

**Diese App ist eine von zwei gleichzeitig existierenden Steuerungswegen auf derselben Platine** - das CM5 betreibt außerdem einen HDMI-Ausgang für einen vollwertigen externen Monitor, auf dem die Web-Oberfläche läuft. Diese DSI-App ergänzt diesen Weg um eine direkte, dauerhaft verfügbare Touch-Konsole direkt an der Platine; sie ersetzt die Web-Oberfläche nicht.

---

**Ehrlichkeitscheck - was heute wirklich läuft:** die Netzwerkschicht (`lib/network/hydra_api_client.dart`, `hydra_websocket.dart`, `discovery.dart`, `auth_prefs.dart`) und die Zustandsschicht (`lib/state/robot_view_model.dart`, `hydra_error.dart`) sind real und getestet (203 bestandene Tests in `test/*.dart`, einschließlich eines echten WebSocket-Verbindungs-/Wiederverbindungs-/Auth-Ablehnungs-Roundtrips gegen einen echten lokalen Server, kein Mock), und `flutter analyze` meldet keine Probleme. Alle 6 Katalog-Bildschirme sind echte, verdrahtete UI, keine Platzhalter. Was tatsächlich nicht gebaut ist: der Bildschirm **3D View** ist ein kleiner nativer isometrischer X/Y/Z-Indikator, kein echter 3D-Renderer - er bettet nicht die echte Three.js-Szene von STUDIO ein (es gibt keine Linux-Implementierung von `webview_flutter`). Was real, aber auf der Zielhardware unverifiziert ist: `flutter build linux --release` wurde ausgeführt und erzeugt eine Binärdatei, die nachweislich startet, aber nur unter Ubuntu 24.04 WSL2 (x86_64) - niemals auf dem echten aarch64 Raspberry Pi OS des CM5 - und die Autostart-Unit `kiosk/hydra-umc-dsi.service` lief noch nie auf einer echten Linux-Maschine. Siehe "Known Follow-ups" weiter unten und `CHANGELOG.md` für das, was bisher genau ausgeliefert wurde.

> **Stand von Sicherheit (Safety) und Security:** Dieses Ökosystem ist kein zertifiziertes Sicherheitssystem. Es gibt noch keinen Hardware-E-STOP-Pfad, keine von der Firmware durchgesetzten Grenzen oder Verriegelungen und keinen verifizierten Bewegungsbefehl; Firmware-Images werden mit CRC-32 und einer Ed25519-Signatur geprüft, und ein Release-Build verweigert die veröffentlichten Entwicklungsschlüssel (die Werkzeugköpfe und Erweiterungsplatinen hinter dem Relais laufen noch mit URTC-Bootloadern, die statt einer Signatur ein HMAC-SHA256 mit gemeinsamem Schlüssel verwenden); TLS und gegenseitiges TLS sind optional und standardmäßig aus; noch keine eigene Platine wurde bestückt oder getestet. Lesen Sie die [Sicherheitsbasis](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/SECURITY_BASELINE.md) und das [Bedrohungsmodell](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/THREAT_MODEL.md), bevor Sie sich für die Sicherheit einer Person auf eine Aussage hier verlassen.

---

## 📋 Auf einen Blick

| | |
|---|---|
| Version | `0.2.7` |
| Reifegrad | Funktionsfähig |
| Tests | 203 (`flutter test`) |
| Technik | Flutter 3.x / Dart |
| Ziel | Der Raspberry Pi CM5 einer HYDRA-UMC-Zelle |
| Auf echter Hardware | Noch nicht: für diese Version ist kein Lauf auf echter Hardware vermerkt |

**Springe zu:** [Überblick](#-überblick) · [Architektur](#-architektur) · [Schnellstart](#-schnellstart) · [Tests](#-tests) · [Struktur des Repositorys](#-struktur-des-repositorys) · [Verwandte Projekte](#-verwandte-projekte)

## 🚦 Projektstatus

Jede Zeile ist ein Teil dieses Repositorys, und die Ampel sagt, wie weit er heute ist. Sie beruht auf dem, was das Repository zeigen kann (Tests, Builds, Läufe), nicht auf dem, was geplant ist.

🟢 Fertig und überprüft · 🟡 Funktioniert, mit bekannten Grenzen · 🟠 Teilweise fertig oder noch nicht überprüft · 🔴 Nicht gemacht oder funktioniert nicht

| Bereich | Stand | Was das hier bedeutet |
|---|---|---|
| Software | 🟡 | Funktioniert für seinen Hauptzweck; die Ehrlichkeitsprüfung oben nennt, was noch fehlt |
| Tests | 🟢 | 203 automatische Tests, bei jeder Änderung ausgeführt |
| Echte Hardware | 🔴 | Noch nicht: für diese Version ist kein Lauf auf echter Hardware vermerkt |
| Dokumentation | 🟢 | README in acht Sprachen, bei jeder Änderung gegen das Manifest geprüft |

## 🎯 Überblick

- **Login** (`lib/ui/login_screen.dart`, `lib/state/robot_view_model.dart`) - Server-IP/Port-Felder mit einem sinnvollen LAN-Standardwert vorausgefüllt, Benutzername/Passwort-Felder in Touch-Größe und standardmäßig leer (kein fest hinterlegtes Kennwort wird vorausgefüllt - das anfängliche `admin`/`admin`-Vorausfüllen wurde entfernt, sobald jeder Server dieses Standardkonto bei einem echten Produktions-Erststart nicht mehr selbst anlegte), `POST /api/login` gegen das vom Bediener eingegebene Konto; zusätzliche Konten mit geringeren Rechten "operator" können über Config > Users in der Web-Oberfläche angelegt werden. Das Sitzungstoken liegt im sicheren Speicher der Plattform (unter Linux libsecret, das einen laufenden Schlüsselbunddienst braucht: auf einem Panel ohne ihn gilt die Sitzung bis zum Neustart der App, danach wird die Anmeldung erneut verlangt). Ein "Lokales Netzwerk durchsuchen"-Dialog (`lib/network/discovery.dart`) findet Server, ohne die IP bereits zu kennen - hier doppelt nützlich, da das CM5, auf dem diese App läuft, oft genau der Controller ist, mit dem sie sich verbinden soll.
- **Netzwerk-Discovery** (`lib/network/discovery.dart`) - zwei parallele Wege aus demselben "Scan local network"-Dialog: echtes mDNS/Bonjour (`discoverMdns()`, das den von `server.ts` selbst veröffentlichten `_hydra._tcp`-Dienst über das Paket `multicast_dns` abfragt) und ein paralleler Brute-Force-Scan von `GET /api/hydra-info` über die echten lokalen Subnetze dieses Geräts (`scanSubnets()`), dedupliziert nach Host:Port - übernommen von HYDRA-UMC-IOS-CONTROL, dem ersten Client im Ökosystem mit echtem mDNS.
- **Atomare Befehlssynchronisation** (`lib/state/robot_view_model.dart`, eigenes `_sendAtomicCommand()`) - jeder Schreibvorgang (play/pause/stop/jog/valve/pump/speed/vision) nutzt den echten Endpunkt `POST /api/robot/:id/command`, mit korrekter Weitergabe an kombinierte Roboter (`combinedWith`) und einem Rollback auf den vorherigen Zustand bei einem fehlgeschlagenen Request - besonders wichtig für ein Jog-Pendant/E-STOP, das sich nur wenige Meter von den echten Robotern entfernt befindet.
- **Live-WebSocket-Synchronisation** (`lib/network/hydra_websocket.dart`) - sendet das Token als `hydra.bearer`-Subprotokoll und nie in der Adresse, verarbeitet sowohl `"settings"`- als auch `"delta"`-Broadcast-Typen, verbindet sich bei Abbruch automatisch neu.
- **Horizontale Touch-Navigation** (`lib/ui/main_screen.dart`) - eine dauerhafte obere Leiste mit 6 großen Icon+Beschriftung-Tabs (Dashboard/Steuerung/Kamera/3D-Ansicht/Metriken/Einstellungen) über die gesamte feste Breite von 1280px, im Geiste von KlipperScreen statt einer Bottom-Nav-Bar wie bei Telefonen - entsprechend dem vom Projektinhaber gewünschten Katalog, neu angeordnet für ein breites Touch-Panel statt eines vertikalen Telefon-Layouts.
- **Dashboard** (`lib/ui/dashboard_screen.dart`) - Karten pro Roboter, in Echtzeit reaktiv über `Provider`, LED-Konvention (grün blinkend = aktiv, rot durchgehend = inaktiv), Anzeige kombinierter Roboter und Modul-Chips (CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK) - dieselbe visuelle Sprache wie bei jedem anderen Client in diesem Ökosystem.
- **Manuelle Steuerung** (`lib/ui/control_screen.dart`, `lib/ui/widgets/joystick_pad.dart`) - Nebeneinander-Layout (Jog-Pad links, Telemetrie/Geschwindigkeit/E-A rechts) für den festen 1280x720-Rahmen statt einer einzigen scrollenden Spalte, der globale **STOP** (`lib/ui/widgets/stop_all.dart`) in der oberen Leiste jedes Tabs, auch im Steuerungs-Tab und im Bildschirmreinigungs-Overlay: ein Antippen, kein langes Drücken und keine Bestätigung, er hält alle Roboter an (`POST /api/stop-all`), zeigt das Ergebnis Roboter für Roboter (Warnung, wenn ein Roboter ausfiel oder der Stopp nicht gespeichert wurde, von anderen Konten reservierte Roboter markiert), wiederholt einmal bei einem Netzwerkfehler, fällt bei einem 429 oder einem älteren Server auf den Stopp je Roboter zurück und hält einen dauerhaften Hinweis „STOP nicht bestätigt“, bis ein späterer STOP beantwortet wird (der runde Stopp je Roboter behält seinen Long-Press-Schutz), Geschwindigkeits-/Beschleunigungsregler, Ventil-/Pumpenschalter.
- **Reservierungen und Sicherheitsgrenzen** (`lib/ui/widgets/access_panel.dart`, `lib/models/access.dart`, `lib/network/hydra_api_client.dart`, `lib/state/robot_view_model.dart`) - Der Control-Bildschirm zeigt, wer den gewählten Roboter hält (niemand, dieses Gerät, dasselbe Konto auf einem anderen Gerät oder ein anderes Konto), und bietet **Reservieren** und **Freigeben** sowie die Liste aller Reservierungen des Servers (`GET /api/claims`). Das Gerät behält pro Installation eine Controller-ID und sendet sie bei jeder Reservierung, Freigabe, Jog-Schaltung und jedem Befehl mit (Body und Header `X-Controller-Id`); die Reservierung gehört also dem Konto und diesem Telefon, nicht dem ganzen Konto. Die Ablehnungen des Servers werden unterschieden: von einem anderen Konto reserviert, von deinem Konto auf einem anderen Gerät oder Fenster, Controller-ID erforderlich und Jog nicht scharf. Die Grenzen des Robotermodells kommen von `GET /api/safety-limits`: Ein Jog-Schritt über dem Limit wird nicht gesendet, und die Warnungen des Servers werden angezeigt. Verlangt der Administrator es, muss **Jog scharfschalten** (mit Countdown) gedrückt werden, bevor der Joystick den Roboter bewegt; die Schaltung endet von selbst, mit STOP oder bei der Freigabe. Reservierungen sind optional: Ein Roboter, den niemand reserviert hat, wird wie bisher gesteuert. Nur für einen **Administrator** erscheint bei einem Roboter, den jemand anderes hält, eine Schaltfläche **Steuerung übernehmen**; sie fragt nach einer Bestätigung und reserviert den Roboter dann mit `force: true` (der Server akzeptiert das nur von Administratoren und prüft die Rolle erneut). Schreibzugriffe sind bedingt: jeder trägt die Revision des Roboters, die diese App zuletzt gesehen hat (`If-Match`, `lib/models/contract_v2.dart`); hat inzwischen jemand anderes den Roboter geändert, antwortet der Server mit 412, nichts wird ausgeführt, der Roboter wird neu gelesen und die Meldung sagt es (Standard prüft Reservierungen, Tisch und einmalige Befehle; Streng prüft alles außer STOP; Aus prüft nichts; die Wahl steht in der Liste der Reservierungen; STOP wird nie geprüft). Der Jog des XY-Tischs ist ein einziger atomarer Befehl `table` (ein älterer Server bekommt die Jogs, die er versteht), der Server schickt die Reservierungen über den WebSocket, sodass der Control-Bildschirm nicht abfragt, solange sie ankommen, und Administratoren lesen das Audit-Protokoll (`lib/ui/widgets/audit_dialog.dart`) mit zweifach geprüfter SHA-256-Kette, vom Server und auf dem Computer, und können dessen Zeilen als `.jsonl` kopieren.
- **Vor PLAY nachfragen** - standardmäßig an, in den Einstellungen abschaltbar: Vor dem Start einer Bahn zeigt die App den Roboter, seine aufgezeichneten Punkte, die Geschwindigkeit und wer ihn reserviert hat (ein von jemand anderem reservierter Roboter weist darauf hin, dass der Server den Befehl ablehnt). Ein Roboter, der schon spielt, wird nicht erneut gefragt. Die Wahl bleibt gespeichert.
- **Kamera** (`lib/ui/camera_screen.dart`, `lib/ui/widgets/mjpeg_view.dart`) - derselbe handgeschriebene, abhängigkeitsfreie MJPEG-Stream-Parser wie bei HYDRA-UMC-IOS-CONTROL (keine WebView, kein plattformspezifischer Code - läuft unverändert auf dem Linux-Desktop), ein klarer "Kamera deaktiviert"-Zustand und ein Schalter, um das Visionssystem eines Roboters direkt vom Server aus ein-/auszuschalten.
- **3D-Ansicht** (`lib/ui/three_d_screen.dart`) - **keine** WebView-Einbettung der echten Three.js-Szene von STUDIO, anders als bei den iOS-/Android-Apps - `webview_flutter` besitzt überhaupt keine Linux-Desktop-Implementierung, und eine vollständige Browser-Engine bedeutet eine schwerere Laufzeitlast, als dieses stromsparende eingebettete Panel benötigt. Stattdessen: eine kleine native isometrische X/Y/Z-Positionsanzeige (`CustomPainter`, keine 3D-Engine), mit einem Hinweis auf dem Bildschirm, der auf die echte 3D-Szene auf dem an dieselbe Platine per HDMI angeschlossenen Monitor verweist. Siehe Abschnitt 4 von `docs/ARCHITECTURE.md` für die vollständige Begründung.
- **Systemmetriken** (`lib/ui/metrics_screen.dart`) - ein eigener, dedizierter Tab (nicht wie bei iOS/Android ins Dashboard integriert) mit CPU-/Speicher-/Temperatur-/Laufzeit-Kacheln aus `GET /api/system/metrics`, plus Hostname/Controller-Anzahl/Roboter-Anzahl/App-Version aus `GET /api/hydra-info`.
- **Einstellungen** (`lib/ui/settings_screen.dart`) - Verbindungsinformationen, Serveridentität, Abmelden und die eigene Version dieser App (siehe [Versionierung](#-versionierung) weiter unten).
- **Kiosk-Autostart** (`kiosk/hydra-umc-dsi.service`, `kiosk/install_kiosk.sh`) - systemd-Unit, die die App über `cage` im Vollbild auf `tty1` startet, mit `Restart=always`. Siehe "Ausführen auf dem echten CM5" weiter unten.
- **UI in 8 Sprachen** (`lib/l10n/`, Standard-`flutter gen-l10n`-Pipeline) - Englisch, Spanisch, Französisch, Deutsch, Italienisch, Japanisch, Chinesisch und Portugiesisch, wie bei den übrigen Clients dieses Ökosystems. Eine gespeicherte Einstellung unter `Einstellungen > Sprache` verwendet standardmäßig die Systemsprache; `RobotViewModel.lastError` ist ein typisierter `HydraError` statt vorformatiertem englischem Text, sodass auch die Fehlermeldungen der Geschäftslogik korrekt lokalisiert werden, nicht nur der statische Bildschirmtext.

**Status: Grundgerüst + alle 6 Katalogbildschirme implementiert und an den echten REMOTE_API.md-Vertrag angebunden.** `flutter analyze` sauber, `flutter build windows` und `flutter build linux` (über WSL2) erzeugen beide eine lauffähige Binärdatei, `flutter test` besteht - siehe "Build" weiter unten für genau das, was bereits verifiziert ist und was nicht, einschließlich der verbleibenden Lücke zwischen dieser WSL2-Verifikation und der echten CM5-Hardware.

**Verbindungssicherheit:** Das Panel verbindet sich zuerst per HTTPS. Unverschlüsseltes HTTP wird nur zu diesem Rechner selbst (Standard `127.0.0.1`) verwendet oder, wenn es im Fenster Sicherheit der Anmeldung und der Einstellungen erlaubt ist, zu einem Server im lokalen Netzwerk (außerhalb nur, wenn auch das erlaubt ist). Einem Server mit selbst signiertem Zertifikat wird über den SHA-256-Fingerabdruck vertraut, der von ihm gelesen und dort bestätigt wird, oder über eine angegebene CA.

## 🧩 Rolle in HYDRA-UMC

**HYDRA-UMC-DSI** ist der Touchscreen der CM5 selbst: eine native Flutter-App für das 5"/7"-DSI-Panel, die über REST und WebSocket mit `HYDRA-UMC-SERVER` spricht, neben der Browseroberfläche von `HYDRA-UMC-STUDIO`. Sie hat keine eigene Robotiklogik; der Server entscheidet, was erlaubt ist.

## 🏛️ Architektur

<p align="center">
  <img src="images/architecture.svg" alt="HYDRA-UMC-DSI architecture" width="100%">
</p>

## 🚀 Schnellstart

Benötigt das stabile Flutter-SDK (3.x) mit Linux-Desktop-Unterstützung.

```bash
flutter pub get
./run_dev.sh      # desktop simulation, no hardware (run_dev.bat on Windows)
./build_linux.sh  # on a Linux machine or the CM5: the real target
```

## 🧪 Tests

203 automatische Tests laufen mit `flutter test`. Sie brauchen weder Hardware noch etwas außerhalb dieses Rechners.

Die CI führt `HYDRA_UMC_CI=1 python tools/ci_validate.py` aus; das prüft das Manifest, die Dokumente, die acht READMEs und die Bilder.

## 🏗️ Build und Veröffentlichung

Erfordert das [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable-Kanal). Dieses Repository wird gegen Flutter 3.47.0 gebaut/verifiziert. Nur `linux/` und `windows/` sind als Plattformen in diesem Repository konfiguriert (keine `android/`-, `ios/`-, `web/`- oder `macos/`-Ordner) - Linux ist das echte Ziel (das Betriebssystem des CM5 selbst); Windows existiert ausschließlich, damit die Logik dieser App auf einer Maschine ohne Linux-Toolchain gebaut, ausgeführt und getestet werden kann.

### Build-Skripte

```bash
./build.sh          # Git Bash / WSL, oder build.bat für cmd/PowerShell - flutter pub get + Versionserhöhung + flutter build windows (Verifikation auf der Entwicklungsmaschine)
./build_linux.sh    # Muss AUF einer echten Linux-Maschine ausgeführt werden (oder dem CM5 selbst) - flutter pub get + Versionserhöhung + flutter build linux (das echte Deployment-Ziel)
./run_dev.sh         # Git Bash / WSL, oder run_dev.bat für cmd/PowerShell - Desktop-Simulationsmodus (flutter run), ohne Hardware nötig
```

Alle 3 Build-Skripte (`build.sh`/`build.bat`/`build_linux.sh`) ändern die Version der App nicht - siehe [Versionierung](#-versionierung) weiter unten. `run_dev.sh`/`run_dev.bat` tun dies nicht - ein `flutter run` im Entwicklungszyklus zählt nicht als "echter Build" im Sinne dieser Richtlinie.

### Manueller Build

```bash
flutter pub get
flutter analyze                  # statische Analyse - kein Compiler nötig
flutter test                     # Widget-Tests
dart run tool/bump_version.dart  # erhöht die Version, genau wie build.sh/build.bat/build_linux.sh
flutter build windows            # Smoke-Test auf der Entwicklungsmaschine - erzeugt build/windows/x64/runner/Release/hydra_umc_dsi.exe
flutter build linux              # das ECHTE Ziel - muss auf einer echten Linux-Maschine ausgeführt werden, erzeugt build/linux/*/release/bundle/
flutter run -d windows           # oder -d linux auf einer echten Linux-Maschine, für eine Live-Entwicklungsschleife im Desktop-Simulationsmodus
```

**Ehrlichkeitshinweis zur Linux-Verifikation:** `flutter build linux --release` wurde jetzt tatsächlich gegen diesen Code ausgeführt, aus einer echten Ubuntu-24.04-WSL2-Umgebung mit einer echten Linux-Desktop-Toolchain (`cmake`, `ninja-build`, `libgtk-3-dev`, `clang`) - der Build läuft sauber durch und erzeugt ein echtes `build/linux/x64/release/bundle/hydra_umc_dsi`, bestätigt als tatsächlich startfähig (es lief unter einem echten X11-Display und blieb aktiv, nicht nur ein Exitcode 0), nicht nur `flutter build windows` als Smoke-Test-Ersatz. Was das **nicht** abdeckt: WSL2s Userspace ist x86_64, nicht das echte aarch64 des Raspberry-Pi-OS der CM5, und der Autostart-Ablauf von `kiosk/hydra-umc-dsi.service` wurde weiterhin nie auf einer echten Linux-Maschine ausgeführt. Siehe Abschnitt 7 von `docs/ARCHITECTURE.md` für die genaue Liste dessen, was verifiziert wurde und was nicht, sowie „Bekannte Folgeaufgaben" weiter unten für das, was noch offen ist.

## 📂 Struktur des Repositorys

<p align="center">
  <img src="images/repository-structure.svg" alt="Repository structure of HYDRA-UMC-DSI" width="100%">
</p>

<details>
<summary>Textversion des Baums</summary>

```text
HYDRA-UMC-DSI/
├── lib/                                                              Quellcode
│   ├── main.dart                                                     App-Einstiegspunkt, ChangeNotifierProvider + Login-Gate, festes dunkles Theme
│   ├── app_version.dart                                              GENERIERT - von tool/bump_version.dart regeneriert, nicht von Hand bearbeiten
│   ├── models/                                                       Datenmodelle und reine Regeln
│   ├── network/                                                      REST-Client, WebSocket und Erkennung
│   ├── state/                                                        der Zustand, den jede Ansicht beobachtet
│   ├── services/                                                     Dienste der App (Hintergrundbeleuchtung)
│   ├── l10n/                                                         Lokalisierungen in acht Sprachen
│   ├── util/                                                         Hilfsfunktionen ohne eigenen Bildschirm
│   └── ui/                                                           Ansichten und Widgets
├── kiosk/                                                            Kiosk-Unit und ihr Installationsskript
├── tool/                                                             Versionswerkzeug
├── linux/                                                            GTK-Desktop-Runner - das ECHTE Ziel, festes 1280x720-Fenster
├── windows/                                                          Windows-Desktop-Runner - nur Verifikation auf der Entwicklungsmaschine
├── tools/                                                            Projektwerkzeuge und CI-Prüfungen
├── test/                                                             widget_test, format_uptime_test, localization_test, robot_view_model_test, robot_view_model_silent_refresh_test, auth_prefs_test, hydra_websocket_test, hostile_answers_test, hydra_error_test, play_confirmation_test, stop_long_press_test
├── .github/                                                          CI-Workflow und Issue-Vorlagen
├── images/                                                           Banner und Bilder der README
├── build.bat / build.sh                                              flutter pub get + Versionserhöhung + flutter build windows (Verifikation auf der Entwicklungsmaschine)
├── build_linux.sh                                                    flutter pub get + Versionserhöhung + flutter build linux (das echte CM5-Ziel - auf echtem Linux ausführen)
├── run_dev.bat / run_dev.sh                                          flutter run - Desktop-Simulationsmodus
├── CHANGELOG.md                                                      was sich in jeder Version geändert hat
├── docs/ARCHITECTURE.md                                              Architektur des Projekts
├── bump_manifest_version.py                                          Synchronisiert die Version von hydra-umc.project.json mit der nativen (--sync)
├── pubspec.yaml / pubspec.lock / l10n.yaml / analysis_options.yaml   Die Flutter-Paketdefinition mit ihren festgelegten Versionen, die Einstellungen des l10n-Generators und die Lint-Regeln
├── build-test.sh                                                     Build-Prüfung ohne Änderungen
├── hydra-umc.project.json                                            Manifest: Version, Reifegrad, Familie
└── test.sh                                                           führt die Tests aus
```

</details>

## 🗺️ Roadmap und bekannte Grenzen

**Bekannte Grenzen heute**

Reale, verifizierte Lücken, die der Code dieser App noch hat - keine vagen TODOs, jede einzelne auf eine konkrete Stelle im Code oder in der obigen Dokumentation zurückführbar:

- **Der Fernzugriffs-Schalter ist noch nicht unabhängig** - Abschnitt 1 von `REMOTE_API.md` erkennt nur `suite`, `android` und `ios` als `X-Hydra-Client`-Werte an; diese App sendet `dsi`, einen nicht erkannten Wert, der heute nie gefiltert wird, sodass ihre Discovery-Anfragen bedingungslos durchgehen. Das zu beheben erfordert einen 4. Schalter im eigenen `SystemSettings.remoteAccess`-Typ von HYDRA-UMC-STUDIO und dessen Config > Remote Access-Tab - eine Änderung am Server-Code eines anderen Repositorys, außerhalb des Umfangs dieses hier. Siehe Abschnitt 3 von `docs/ARCHITECTURE.md`.
- **Die 3D-Ansicht hat keinen echten nativen 3D-Renderer** - `ui/three_d_screen.dart` zeichnet derzeit nur einen kleinen isometrischen X/Y/Z-Positionsindikator, statt STUDIOs echte Three.js-Szene einzubetten (`webview_flutter` hat keine Linux-Implementierung - siehe Abschnitt 4 von `docs/ARCHITECTURE.md` für die vollständige Begründung). Ein echter nativer 3D-Renderer für diesen Bildschirm ist zukünftige Arbeit, noch nicht begonnen.
- **Ein echter Lauf auf der CM5-Hardware steht noch aus** - `flutter build linux` selbst ist jetzt verifiziert (echte Ubuntu-24.04-WSL2-Toolchain, Binärdatei bestätigt tatsächlich startfähig - siehe Abschnitt 7 von `docs/ARCHITECTURE.md`), aber der vollständige Ablauf von `build_linux.sh` und die Autostart-Unit `kiosk/hydra-umc-dsi.service` wurden weiterhin nie tatsächlich gegen das CM5 selbst oder eine andere echte (Nicht-WSL2-)Linux-Maschine ausgeführt. Wer sie dort zum ersten Mal ausführt, sollte das als den echten ersten Hardware-Deploy dieses Plattform-Ziels behandeln, nicht als Formalität - siehe „Ausführen auf dem echten CM5" oben.

## 🌍 Sprachen

Diese README und die Dokumente des Repositorys gibt es in acht Sprachen: Englisch, Spanisch, Deutsch, Französisch, Italienisch, Japanisch, Chinesisch und Portugiesisch (Portugal). Sie entstehen gemeinsam, und die CI prüft, dass die acht Dateien dieselben Abschnitte und dieselben Links haben.

## 🔗 Verwandte Projekte

Dieses Projekt ist Teil des HYDRA-UMC-Robotik-Ökosystems desselben Autors (JuanenRac / Electro Hobby 3D). Gut zu wissen, da eine Anfrage eigentlich eines dieser Projekte betreffen könnte statt dieses Repositorys.

**Übergeordnetes Projekt**
- **[HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)** — das reale Headless-Backend (REST/WebSocket), mit dem jeder Steuerungsclient tatsächlich spricht; der Server, mit dem sich dieses Panel über den echten `REMOTE_API.md`-Vertrag verbindet (Discovery, Login, atomare Befehle, WebSocket-Synchronisierung).

**Geschwisterprojekte** — sprechen ebenfalls mit der eigenen API von HYDRA-UMC-SERVER, jeweils als eigener Client
- **[HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — Web-Steuerungs-Dashboard mit Echtzeit-3D-Visualisierung mehrerer Roboter.
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** — Desktop-Schwarmleitstand (PySide6) für mehrere Server gleichzeitig, verpackt als eigenständige ausführbare Datei; spricht genau denselben `REMOTE_API.md`-Vertrag wie dieses Panel.
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** — native Android-Steuerungs-App mit biometrischem Login und einer gekoppelten Wear-OS-Begleit-App; spricht genau denselben `REMOTE_API.md`-Vertrag wie dieses Panel.
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — iOS/iPadOS-Steuerungs-App (Flutter) mit Echtzeit-WebSocket-Synchronisierung; spricht genau denselben `REMOTE_API.md`-Vertrag wie dieses Panel und ist die Quelle, aus der die eigene echte mDNS-Erkennung dieses Panels portiert wurde.
- **[HYDRA-UMC-BRIDGE-AMR](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-AMR)** — Koordinationsschranke für AGV-/AMR-Flotten über einen VDA-5050-MQTT-Publisher (nur gegen eine emulierte Flotte getestet).
- **[HYDRA-UMC-BRIDGE-CNC](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-CNC)** — High-Level-Koordinator für CNC-Zellen mit GRBL-Status-/Steuerbyte-Zugriff (nur gegen einen Emulator getestet).
- **[HYDRA-UMC-BRIDGE-DROIDS](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-DROIDS)** — Koordinationsschranke für laufende/humanoide Droiden, mit einem Boston-Dynamics-Spot-Befehlssender (nur gegen einen Emulator getestet).
- **[HYDRA-UMC-BRIDGE-LASER](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-LASER)** — Koordinator für Laserzellen, liest 3 Schlüssel-/Gehäuse-/Verriegelungs-GPIO-Signale (nur gegen einen simulierten Chip getestet; kann keinen Laser scharfschalten oder auslösen).
- **[HYDRA-UMC-BRIDGE-OPENPNP](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-OPENPNP)** — sicherer High-Level-Koordinator für den Leiterplattenfluss von OpenPnP Pick-and-Place.
- **[HYDRA-UMC-BRIDGE-PRINTER3D](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-PRINTER3D)** — sichere Koordinationsschranke für Moonraker/Klipper-3D-Drucker, mit echten gesicherten Job-Befehlen.
- **[HYDRA-UMC-BRIDGE-ROS2](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-ROS2)** — Koordinator mit einem träge importierten rclpy-ROS-2-Transport (noch nicht gegen eine ROS-2-Installation ausgeführt).
- **[HYDRA-UMC-BRIDGE-UAV](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-UAV)** — Koordinationsschranke für kameraausgestattete UAVs, mit einem MAVLink-Befehlssender (nur gegen einen Emulator getestet).

**Direkt verwandt**
- **[HYDRA-UMC-WATCH](https://github.com/JuanenRac/HYDRA-UMC-WATCH)** — WearOS-Begleit-App mit haptischen Alarmmustern und einem Sprach-Relay zum gekoppelten Telefon (noch nicht auf einer physischen Uhr ausgeführt); das tragbare Sicherheitsalarmgerät, das dieses Touch-Panel ergänzt und Warnungen zusätzlich zum eigenen Bildschirm der Platine ans Handgelenk des Bedieners trägt.
- **[HYDRA-UMC-COGNITIVE-NODE](https://github.com/JuanenRac/HYDRA-UMC-COGNITIVE-NODE)** — Integrationsknoten für die Hailo-10-Cognitive-Pipeline (LLM-/VLA-/Sprach-Orchestrierung); fügt diesem Touch-Panel direkt eine Sprachsteuerung hinzu.
- **[HYDRA-UMC-VOICE-UI](https://github.com/JuanenRac/HYDRA-UMC-VOICE-UI)** — echtes Sprach-Frontend (VAD + Intent-Parser) mit einem begrenzten, bestätigungsgesicherten Watch-Relay; fügt diesem Touch-Panel direkt eine Sprachsteuerung hinzu.
- **[HYDRA-UMC-LOCAL-TECHNICIAN](https://github.com/JuanenRac/HYDRA-UMC-LOCAL-TECHNICIAN)** — lokaler, richtlinien-gesteuerter KI-Wartungstechniker für das Ökosystem selbst - beobachtet, diagnostiziert und schlägt Korrekturen vor; die zwei höchsten Risikostufen sind absichtlich noch nicht implementiert.

**Ebenfalls Teil des Ökosystems**

*Kern-Hardware & Plattform*
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** — der Entwurf des Motherboards des Roboterarms: CM5-Host + Dual-Core-STM32H745, gedacht zur Koordination von bis zu 8 Werkzeugarmen über CAN-OTA/SPI-OTA (Firmware in einer frühen Phase; noch keine bestückte Platine).
- **[HYDRA-UMC-OS](https://github.com/JuanenRac/HYDRA-UMC-OS)** — reproduzierbare Raspberry-Pi-OS-Produktschicht für den CM5: schreibgeschützter Agent, validierte Konfiguration/Profile, WiFi-Ersteinrichtung.
- **[HYDRA-UMC-SDK](https://github.com/JuanenRac/HYDRA-UMC-SDK)** — der gemeinsame JSON-Schema-Vertrag und die Software-Auftragsschranke, gegen die jede Bridge ihre Befehle validiert (keine zertifizierte Sicherheitsfunktion).
- **[HYDRA-UMC-CONNECTOR-HUB](https://github.com/JuanenRac/HYDRA-UMC-CONNECTOR-HUB)** — deklaratives Adapter-Manifest-Register und Validator für Konnektoren externer Maschinen; erweitert die eigene Vertragsidee des SDK auf externe Maschinen, ohne die Industrie-Gateway-Projekte zu ersetzen.

*Kern-Backend & Clients*
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** — grafischer Desktop-URDF-Ersteller/-Editor, der fertige Modelle in STUDIOs eigenen Katalog überträgt.
- **[HYDRA-UMC-EDITOR-STL](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-STL)** — Desktop-STL-Modelleditor, der echte Teile im selben Modellkatalog transformiert/ersetzt/entfernt/hinzufügt, den auch HYDRA-UMC-EDITOR-URDF bearbeitet.

*URTC-Werkzeugplattform*
- **[URTC](https://github.com/JuanenRac/URTC)** — Firmware für die physische Universal-Robot-Tool-Controller-Platine, 25+ Werkzeugprofile über CAN-Bus.
- **[URTC-FLASHER](https://github.com/JuanenRac/URTC-FLASHER)** — Desktop-GUI-Flash-Tool für URTC-Platinen, CAN-OTA plus Full-Chip-SWD/JTAG.
- **[URTC-TESTER](https://github.com/JuanenRac/URTC-TESTER)** — Desktop-Live-CAN-Bus-Diagnosetool für URTC-Platinen, ein Panel pro Werkzeugprofil.
- **[URTC-WEB-STUDIO](https://github.com/JuanenRac/URTC-WEB-STUDIO)** — browserbasierte Alternative zu URTC-TESTER über die Web-Serial-API, ohne lokale Installation.
- **[URTC-GATEWAY](https://github.com/JuanenRac/URTC-GATEWAY)** — Gateway vor dem CAN-Bus von URTC: Liste erlaubter Kennungen, Ratenbegrenzung und Sitzungsschlüssel; Software auf dem Computer getestet, noch nicht an einem echten Bus.

*Vision-KI-Knoten (Hailo-8)*
- **[HYDRA-UMC-VISION-NODE](https://github.com/JuanenRac/HYDRA-UMC-VISION-NODE)** — Integrationsknoten für die Hailo-8-Vision-Pipeline, mit einer echten stufenweisen Hardware-Bereitschaftsprüfung.
- **[HYDRA-UMC-DETECTION-HEF](https://github.com/JuanenRac/HYDRA-UMC-DETECTION-HEF)** — echte Registry für kompilierte Modelle mit Hailo-Architektur-/Prüfsummen-Safe-Load-Verifizierung.
- **[HYDRA-UMC-VISION-STREAMER](https://github.com/JuanenRac/HYDRA-UMC-VISION-STREAMER)** — echter GStreamer-Pipeline- + MediaMTX-Konfigurationsgenerator mit einer echten HailoRT-Integrationsschranke.
- **[HYDRA-UMC-VISUAL-SERVOING-API](https://github.com/JuanenRac/HYDRA-UMC-VISUAL-SERVOING-API)** — Position-Based-Visual-Servoing-Korrekturgesetz mit Freigabe abhängig vom Zonenstatus; noch keine Posenschätzung per Kamera.
- **[HYDRA-UMC-SAFETY-ZONES](https://github.com/JuanenRac/HYDRA-UMC-SAFETY-ZONES)** — v0-Logik für Zonenverletzung, Kalibrierungsaktualität und E-STOP-Anforderung, die Objektpositionen aus einer Datei nimmt; kein Detektor speist sie, und noch kein physischer E-STOP ist angeschlossen.

*Kognitiver KI-Knoten (Hailo-10)*
- **[HYDRA-UMC-VLA-ENGINE](https://github.com/JuanenRac/HYDRA-UMC-VLA-ENGINE)** — echte Aktions-Token-Kodierung/-Dekodierung und Trajektoriengenerierung für ein Vision-Language-Action-Modell.
- **[HYDRA-UMC-SEMANTIC-PLANNER](https://github.com/JuanenRac/HYDRA-UMC-SEMANTIC-PLANNER)** — echte regelbasierte Aufgabenzerlegung und semantische Fehlerbehebung über MCU-Fehlercodes.
- **[HYDRA-UMC-DOCS-QA](https://github.com/JuanenRac/HYDRA-UMC-DOCS-QA)** — echte, nur auf der Standardbibliothek basierende TF-IDF-Dokumentensuche über die eigenen Markdown-Dokumente dieses Ökosystems.

*Orchestrierung & Schwarm*
- **[HYDRA-UMC-ORCHESTRATOR](https://github.com/JuanenRac/HYDRA-UMC-ORCHESTRATOR)** — Integrationsknoten mit einem echten gRPC/Protobuf-Health-Report-Vertrag und einer Missions-Zustandsmaschine.
- **[HYDRA-UMC-JOB-DISPATCHER](https://github.com/JuanenRac/HYDRA-UMC-JOB-DISPATCHER)** — echte prioritätsbasierte Job-Queue mit Deduplizierung, über eine echte HTTP-API.
- **[HYDRA-UMC-NODE-HEALING](https://github.com/JuanenRac/HYDRA-UMC-NODE-HEALING)** — echter gRPC-basierter Flotten-Health-Watchdog mit Retry/Backoff und Identitäts-Mismatch-Erkennung.
- **[HYDRA-UMC-PATH-PLANNER-3D](https://github.com/JuanenRac/HYDRA-UMC-PATH-PLANNER-3D)** — echter RRT-basierter 3D-Pfadplaner mit echter Hindernis-/Arbeitsraum-Kollisionsvalidierung.
- **[HYDRA-UMC-SWARM-SYNC](https://github.com/JuanenRac/HYDRA-UMC-SWARM-SYNC)** — echte CRDT-LWW-Element-Map-Zustandssynchronisation, eigenschaftsgetestet auf Multi-Zellen-Konvergenz.

*Digitaler Zwilling & Simulation*
- **[HYDRA-UMC-TWIN](https://github.com/JuanenRac/HYDRA-UMC-TWIN)** — Integrationsknoten für die Digital-Twin-Engine, mit einem echten Versionskompatibilitäts-Sync-Vertrag.
- **[HYDRA-UMC-HIL-BRIDGE](https://github.com/JuanenRac/HYDRA-UMC-HIL-BRIDGE)** — Hardware-in-the-Loop-Router mit einer Software-Kollisionsverriegelung zwischen Simulation und echter Hardware (ohne echte Hardware getestet).
- **[HYDRA-UMC-PHYSICS-REPLICA](https://github.com/JuanenRac/HYDRA-UMC-PHYSICS-REPLICA)** — echte Vorwärtskinematik und Gelenkgrenzenvalidierung über eine echte URDF-Teilmenge.
- **[HYDRA-UMC-SYNTHETIC-DATA-GEN](https://github.com/JuanenRac/HYDRA-UMC-SYNTHETIC-DATA-GEN)** — echter prozeduraler 2D-Szenengenerator mit YOLO/COCO-Annotationsexport.

*Daten & Analytik*
- **[HYDRA-UMC-DATALAKE](https://github.com/JuanenRac/HYDRA-UMC-DATALAKE)** — echter sqlite3-gestützter Zeitreihenspeicher mit einer echten Ingest-/Abfrage-HTTP-API.
- **[HYDRA-UMC-ANOMALY-DETECTOR](https://github.com/JuanenRac/HYDRA-UMC-ANOMALY-DETECTOR)** — echter FFT- + statistischer Basislinien-Anomaliedetektor mit Drift-Überwachung.
- **[HYDRA-UMC-PRODUCTION-REPORTS](https://github.com/JuanenRac/HYDRA-UMC-PRODUCTION-REPORTS)** — echte OEE-/Verfügbarkeitsberechnung über den DATALAKE-Verlauf, mit reproduzierbarem CSV-Export.
- **[HYDRA-UMC-TELEMETRY-COLLECTOR](https://github.com/JuanenRac/HYDRA-UMC-TELEMETRY-COLLECTOR)** — echte CAN/WebSocket-Ingestion-Pipeline in DATALAKE, mit Sequenz-Deduplizierung.

*Industrie-Gateway*
- **[HYDRA-UMC-GATEWAY-INDUSTRIAL](https://github.com/JuanenRac/HYDRA-UMC-GATEWAY-INDUSTRIAL)** — Integrationsknoten, der zu Industrieprotokollen weiterleitet, mit einer echten Befehls-Allowlist-/Backpressure-Schicht.
- **[HYDRA-UMC-OPCUA-SERVER](https://github.com/JuanenRac/HYDRA-UMC-OPCUA-SERVER)** — echter OPC-UA-Adressraum, verifiziert mit einer echten Binärprotokoll-Client-Session.
- **[HYDRA-UMC-MQTT-BROKER](https://github.com/JuanenRac/HYDRA-UMC-MQTT-BROKER)** — echter MQTT-Broker mit optionaler Pro-Client-Authentifizierung und Topic-ACLs.
- **[HYDRA-UMC-MTCONNECT-ADAPTER](https://github.com/JuanenRac/HYDRA-UMC-MTCONNECT-ADAPTER)** — echte MTConnect-`/probe`- und `/current`-XML-Endpunkte mit Degraded-Mode-Ausgabe.

*Ergänzende Tools & Ökosystembetrieb*
- **[HYDRA-UMC-DASHBOARD-AI](https://github.com/JuanenRac/HYDRA-UMC-DASHBOARD-AI)** — Smart-Summaries- und Anomaly-Highlighting-Panels über DATALAKE/ANOMALY-DETECTOR, mit einem ehrlichen statistischen Fallback.
- **[HYDRA-UMC-TOOL-CLI](https://github.com/JuanenRac/HYDRA-UMC-TOOL-CLI)** — Flotten-CLI mit einem echten, stabilen Exit-Code-Vertrag, ein echter Live-Client der eigenen API von HYDRA-UMC-SERVER.
- **[URTC-SMART-RACK](https://github.com/JuanenRac/URTC-SMART-RACK)** — Firmware für ein Platinenmontagegestell mit echter Werkzeug-ID-Dekodierung und Smart-Idle-Vorheizlogik.
- **[URTC-VISION-TOOL](https://github.com/JuanenRac/URTC-VISION-TOOL)** — Firmware plus ein echter Python-Vision-Begleiter für einen Thermal-/RGB-Inspektionswerkzeugkopf.
- **[HYDRA-UMC-UPDATER](https://github.com/JuanenRac/HYDRA-UMC-UPDATER)** — administratives Desktop-Tool, das jedes Repository in diesem Ökosystem entdeckt, klont und aktualisiert.
- **[HYDRA-UMC-OS-REBUILDER](https://github.com/JuanenRac/HYDRA-UMC-OS-REBUILDER)** — Windows/Linux-Desktop-Tool, das ein flashbereites CM5-Image baut, vorgeladen mit den aktuellsten Versionen des Ökosystems, mit Ersteinrichtungs-Konfiguration für WLAN/Benutzer/SSH im Stil von Raspberry Pi Imager.
- **[HYDRA-UMC-OPS-AGENT](https://github.com/JuanenRac/HYDRA-UMC-OPS-AGENT)** — Wartungsvorfall-Koordinator: eine Edge-Rolle mit niedrigem Privileg sammelt einen bereinigten Inventar-/Gesundheits-Snapshot, eine Control-Plane-Rolle rendert ihn schreibgeschützt und bittet einen KI-Anbieter um einen Diagnosevorschlag - wendet nie einen Patch an und stellt nie etwas bereit.
- **[HYDRA-UMC-DEV-SERVER](https://github.com/JuanenRac/HYDRA-UMC-DEV-SERVER)** — reproduzierbarer Entwicklungshost (Raspberry Pi 5 / CM5), der den Quellcode des Ökosystems vorhält und begrenzte Build-/Test-Aufgaben über eine dauerhafte Warteschlange ausführt; eine dedizierte Entwicklerrolle, ausdrücklich kein operativer CM5.

## 📚 Dokumentation

Hier steht mehr:

* [Sicherheitsgrundlage des Ökosystems](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/SECURITY_BASELINE.md)
* [Bedrohungsmodell des Ökosystems](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/THREAT_MODEL.md)
* [Änderungsprotokoll dieses Repositorys](CHANGELOG.md)
* [Lizenz dieses Repositorys](LICENSE.md)

## 🤝 Mitwirken und Community

* Führe vor einem Pull Request `HYDRA_UMC_CI=1 py -3 tools/ci_validate.py` (oder `HYDRA_UMC_CI=1 python3 tools/ci_validate.py`) aus: Es muss `CI_VALIDATION=PASS` ausgeben. Führe dafür nicht `build.sh` oder `build.bat` aus; Bauen ist keine Prüfung.
* Die acht READMEs entstehen aus einer einzigen Quelle in HYDRA-UMC-DOCS; bearbeite sie nicht von Hand. Ändere die Quelle und schreibe sie mit `tools/make_readmes.py` neu.
* Behaupte in einer README nichts, was nicht gelaufen ist: Schreibe „simuliert“ oder „nicht auf Hardware erprobt“, wo das stimmt.
* Siehe [CONTRIBUTING.md](CONTRIBUTING.md), den [Verhaltenskodex](CODE_OF_CONDUCT.md), [SECURITY.md](SECURITY.md) und [SUPPORT.md](SUPPORT.md).

## 👤 AUTOR

**JuanenRac (Electro Hobby 3D)** · electrohobby3d@gmail.com

## 📜 LIZENZ

GPL-3.0-or-later - [LICENSE](LICENSE).
