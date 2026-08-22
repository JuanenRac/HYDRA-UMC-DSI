# 🖥️ HYDRA-UMC DSI

Eine native Flutter-Touch-UI (Dart, mit echtem Linux-Desktop-Ziel) für HYDRA-UMCs eigenen 5"/7"-DSI-Touchscreen am Compute Module 5 - beide physischen Panelgrößen teilen sich exakt dieselbe Auflösung von 1280x720 Pixeln, weshalb diese App ein einziges, festes, nicht responsives Layout verwendet, statt sich an zwei Größen anzupassen. Sie spricht genau denselben [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-STUDIO/blob/main/docs/REMOTE_API.md)-Vertrag wie [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE), [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) und [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) - Discovery, Login, atomare Befehle pro Roboter und Live-Synchronisation per WebSocket mit einem laufenden [HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)-Server, direkt auf der Platine selbst ausgeführt statt in einem Browser-Tab. Siehe [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) für das vollständige Design, einschließlich der Begründung für Flutter (statt Kivy) und warum der 3D-Bildschirm keine WebView verwendet.

**Diese App ist eine von zwei gleichzeitig existierenden Steuerungswegen auf derselben Platine** - das CM5 betreibt außerdem einen HDMI-Ausgang für einen vollwertigen externen Monitor, auf dem die Web-Oberfläche läuft. Diese DSI-App ergänzt diesen Weg um eine direkte, dauerhaft verfügbare Touch-Konsole direkt an der Platine; sie ersetzt die Web-Oberfläche nicht.

## 🏗️ Was implementiert ist

- **Login** (`lib/ui/login_screen.dart`, `lib/state/robot_view_model.dart`) - Server-IP/Port- und Benutzername/Passwort-Felder in Touch-Größe, `POST /api/login` gegen `admin`/`admin` (vorausgefüllt - das Standardkonto, das jeder Server in diesem Ökosystem bei seinem allerersten Start selbst anlegt; zusätzliche Konten mit geringeren Rechten "operator" können über Config > Users in der Web-Oberfläche angelegt werden), Sitzungstoken wird über Neustarts hinweg via `shared_preferences` gespeichert - wichtig auf einem Kiosk-Panel, das auch nach einem Aus-/Einschaltzyklus des CM5 selbst angemeldet bleiben soll, nicht nur nach einem App-Neustart. Ein "Lokales Netzwerk durchsuchen"-Dialog (`lib/network/discovery.dart`) findet Server, ohne die IP bereits zu kennen - hier doppelt nützlich, da das CM5, auf dem diese App läuft, oft genau der Controller ist, mit dem sie sich verbinden soll.
- **Netzwerk-Discovery** (`lib/network/discovery.dart`) - zwei parallele Wege aus demselben "Scan local network"-Dialog: echtes mDNS/Bonjour (`discoverMdns()`, das den von `server.ts` selbst veröffentlichten `_hydra._tcp`-Dienst über das Paket `multicast_dns` abfragt) und ein paralleler Brute-Force-Scan von `GET /api/hydra-info` über die echten lokalen Subnetze dieses Geräts (`scanSubnets()`), dedupliziert nach Host:Port - übernommen von HYDRA-UMC-IOS-CONTROL, dem ersten Client im Ökosystem mit echtem mDNS.
- **Atomare Befehlssynchronisation** (`lib/state/robot_view_model.dart`, eigenes `_sendAtomicCommand()`) - jeder Schreibvorgang (enable/disable/play/pause/stop/jog/valve/pump/speed/vision) nutzt den echten Endpunkt `POST /api/robot/:id/command`, mit korrekter Weitergabe an kombinierte Roboter (`combinedWith`) und einem Rollback auf den vorherigen Zustand bei einem fehlgeschlagenen Request - besonders wichtig für ein Jog-Pendant/E-STOP, das sich nur wenige Meter von den echten Robotern entfernt befindet.
- **Live-WebSocket-Synchronisation** (`lib/network/hydra_websocket.dart`) - hängt immer `?token=` an, verarbeitet sowohl `"settings"`- als auch `"delta"`-Broadcast-Typen, verbindet sich bei Abbruch automatisch neu.
- **Horizontale Touch-Navigation** (`lib/ui/main_screen.dart`) - eine dauerhafte obere Leiste mit 6 großen Icon+Beschriftung-Tabs (Dashboard/Steuerung/Kamera/3D-Ansicht/Metriken/Einstellungen) über die gesamte feste Breite von 1280px, im Geiste von KlipperScreen statt einer Bottom-Nav-Bar wie bei Telefonen - entsprechend dem vom Projektinhaber gewünschten Katalog, neu angeordnet für ein breites Touch-Panel statt eines vertikalen Telefon-Layouts.
- **Dashboard** (`lib/ui/dashboard_screen.dart`) - Karten pro Roboter, in Echtzeit reaktiv über `Provider`, LED-Konvention (grün blinkend = aktiv, rot durchgehend = inaktiv), Anzeige kombinierter Roboter und Modul-Chips (CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK) - dieselbe visuelle Sprache wie bei jedem anderen Client in diesem Ökosystem.
- **Manuelle Steuerung** (`lib/ui/control_screen.dart`, `lib/ui/widgets/joystick_pad.dart`) - Nebeneinander-Layout (Jog-Pad links, Telemetrie/Geschwindigkeit/E-A rechts) für den festen 1280x720-Rahmen statt einer einzigen scrollenden Spalte, echter Long-Press-Schutz bei E-STOP/STOP (ein kurzes Antippen bewirkt nichts außer haptischem Feedback + visuellem Hinweis, nur ein echtes Halten sendet den Befehl), Geschwindigkeits-/Beschleunigungsregler, Ventil-/Pumpenschalter.
- **Kamera** (`lib/ui/camera_screen.dart`, `lib/ui/widgets/mjpeg_view.dart`) - derselbe handgeschriebene, abhängigkeitsfreie MJPEG-Stream-Parser wie bei HYDRA-UMC-IOS-CONTROL (keine WebView, kein plattformspezifischer Code - läuft unverändert auf dem Linux-Desktop), ein klarer "Kamera deaktiviert"-Zustand und ein Schalter, um das Visionssystem eines Roboters direkt vom Server aus ein-/auszuschalten.
- **3D-Ansicht** (`lib/ui/three_d_screen.dart`) - **keine** WebView-Einbettung der echten Three.js-Szene von STUDIO, anders als bei den iOS-/Android-Apps - `webview_flutter` besitzt überhaupt keine Linux-Desktop-Implementierung, und eine vollständige Browser-Engine bedeutet eine schwerere Laufzeitlast, als dieses stromsparende eingebettete Panel benötigt. Stattdessen: eine kleine native isometrische X/Y/Z-Positionsanzeige (`CustomPainter`, keine 3D-Engine), mit einem Hinweis auf dem Bildschirm, der auf die echte 3D-Szene auf dem an dieselbe Platine per HDMI angeschlossenen Monitor verweist. Siehe Abschnitt 4 von `docs/ARCHITECTURE.md` für die vollständige Begründung.
- **Systemmetriken** (`lib/ui/metrics_screen.dart`) - ein eigener, dedizierter Tab (nicht wie bei iOS/Android ins Dashboard integriert) mit CPU-/Speicher-/Temperatur-/Laufzeit-Kacheln aus `GET /api/system/metrics`, plus Hostname/Controller-Anzahl/Roboter-Anzahl/App-Version aus `GET /api/hydra-info`.
- **Einstellungen** (`lib/ui/settings_screen.dart`) - Verbindungsinformationen, Serveridentität, Abmelden und die eigene Version dieser App (siehe [Versionierung](#-versionierung) weiter unten).
- **Kiosk-Autostart** (`kiosk/hydra-umc-dsi.service`, `kiosk/install_kiosk.sh`) - systemd-Unit, die die App über `cage` im Vollbild auf `tty1` startet, mit `Restart=always`. Siehe "Ausführen auf dem echten CM5" weiter unten.

**Status: Grundgerüst + alle 6 Katalogbildschirme implementiert und an den echten REMOTE_API.md-Vertrag angebunden.** `flutter analyze` sauber, `flutter build windows` erzeugt eine lauffähige Binärdatei, `flutter test` besteht - siehe "Build" weiter unten für genau das, was sich aus dieser Windows-Arbeitsumgebung heraus verifizieren ließ und was nicht, da das eigentliche Ziel Linux ist.

## 🚀 Build

Erfordert das [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable-Kanal). Dieses Repository wird gegen Flutter 3.47.0 gebaut/verifiziert. Nur `linux/` und `windows/` sind als Plattformen in diesem Repository konfiguriert (keine `android/`-, `ios/`-, `web/`- oder `macos/`-Ordner) - Linux ist das echte Ziel (das Betriebssystem des CM5 selbst); Windows existiert ausschließlich, damit die Logik dieser App auf einer Maschine ohne Linux-Toolchain gebaut, ausgeführt und getestet werden kann.

### Build-Skripte

```bash
./build.sh          # Git Bash / WSL, oder build.bat für cmd/PowerShell - flutter pub get + Versionserhöhung + flutter build windows (Verifikation auf der Entwicklungsmaschine)
./build_linux.sh    # Muss AUF einer echten Linux-Maschine ausgeführt werden (oder dem CM5 selbst) - flutter pub get + Versionserhöhung + flutter build linux (das echte Deployment-Ziel)
./run_dev.sh         # Git Bash / WSL, oder run_dev.bat für cmd/PowerShell - Desktop-Simulationsmodus (flutter run), ohne Hardware nötig
```

Alle 3 Build-Skripte (`build.sh`/`build.bat`/`build_linux.sh`) erhöhen zuerst die Version der App - siehe [Versionierung](#-versionierung) weiter unten. `run_dev.sh`/`run_dev.bat` tun dies nicht - ein `flutter run` im Entwicklungszyklus zählt nicht als "echter Build" im Sinne dieser Richtlinie.

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

**Ehrlichkeitshinweis zur Linux-Verifikation:** dieses Repository wurde auf einer Windows-Maschine ohne verfügbare Linux-Build-Toolchain erstellt (bestätigt via `wsl --status` - keine WSL-Distribution installiert). `flutter build linux` wurde von dieser Arbeitsumgebung aus nie tatsächlich gegen diesen Code ausgeführt; `flutter build windows` wurde als Smoke-Test-Ersatz verwendet, wie es der Auftrag ausdrücklich erlaubt. Siehe Abschnitt 7 von `docs/ARCHITECTURE.md` für die genaue Liste dessen, was verifiziert wurde und was nicht, sowie `mejoras_futuras.txt` für die noch offene Nacharbeit.

## 🔢 Versionierung

Dieses Repository folgt einer ökosystemweiten Richtlinie (gemeinsam mit
[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL),
dort parallel umgesetzt): Die Version wird bei **jedem echten Build**
automatisch erhöht, ohne manuelle Bearbeitung der `version:`-Zeile in
`pubspec.yaml`. `build.sh`/`build.bat`/`build_linux.sh` führen
`tool/bump_version.dart` aus, bevor `flutter build` aufgerufen wird, und
wenden dabei an:

- **Patch, Kilometerzähler-Stil (Basis 10):** +1 bei jedem Build; würde
  er 9 überschreiten, wird er auf 0 zurückgesetzt und die Minor-Version
  stattdessen um +1 erhöht - Beispiel: `1.0.9` -> `1.1.0`. Die
  Major-Version wird davon nie automatisch berührt.
- **Build-Nummer** (der Teil nach dem `+`): ein einfacher monotoner
  Zähler, +1 bei jedem Build, ohne Übertrag.

Dasselbe Skript regeneriert `lib/app_version.dart` (generiert, nicht von
Hand bearbeitet - eine einfache `const`-Datei, keine neue
Laufzeitabhängigkeit wie `package_info_plus`), die die App zur Laufzeit
liest, um ihre eigene Version auf dem **Einstellungen**-Bildschirm
anzuzeigen. Siehe [CHANGELOG.md](CHANGELOG.md) für die Versionshistorie.

### Ausführen auf dem echten CM5

Nachdem `build_linux.sh` `build/linux/*/release/bundle/` erzeugt hat, kopiere das gesamte `bundle/`-Verzeichnis auf das CM5 (es hängt von den `.so`-Dateien neben der Binärdatei ab, nicht nur von der ausführbaren Datei selbst) nach `/opt/hydra-umc-dsi/bundle/` und führe dann `sudo kiosk/install_kiosk.sh` aus, um `kiosk/hydra-umc-dsi.service` zu installieren und zu aktivieren - eine systemd-Unit, die die App über [`cage`](https://github.com/cage-kiosk/cage) (ein minimaler Wayland-Kiosk-Compositor, der genau einen Vollbild-Client ausführt) im Vollbild auf `tty1` startet, mit `Restart=always`, damit ein Absturz die App neu startet statt einen schwarzen Bildschirm zu hinterlassen. Gegenüber [`flutter-pi`](https://github.com/ardera/flutter-pi) (ein Flutter-Engine-Einbetter eines Drittanbieters für Raspberry Pi, der ganz ohne Fenstersystem läuft) gewählt, weil es die echte, von `build_linux.sh` bereits erzeugte `flutter build linux`-Ausgabe unverändert weiterverwendet - flutter-pi kompiliert stattdessen direkt gegen die Flutter-Engine und bräuchte daher einen eigenen separaten Build-Schritt, ist also kein direkter Ersatz. **Ehrlichkeitshinweis:** geschrieben und geprüft, aber nie wirklich gegen ein echtes CM5 oder eine andere Linux-Maschine ausgeführt - gleicher unverifizierter Status wie `flutter build linux` selbst (siehe `docs/ARCHITECTURE.md` Abschnitt 7). Siehe den Kopfkommentar von `kiosk/hydra-umc-dsi.service` für die genauen Annahmen (Root-Servicebenutzer, Besitz von `tty1`), die gegen das tatsächlich auf dem CM5 laufende Raspberry-Pi-OS-Image zu prüfen wären.

## 📂 Repository-Struktur

```text
HYDRA-UMC-DSI/
├── build.bat, build.sh              # flutter pub get + Versionserhöhung + flutter build windows (Verifikation auf der Entwicklungsmaschine)
├── build_linux.sh                   # flutter pub get + Versionserhöhung + flutter build linux (das echte CM5-Ziel - auf echtem Linux ausführen)
├── CHANGELOG.md                      # Versionshistorie (siehe Versionierung weiter oben)
├── kiosk/
│   ├── hydra-umc-dsi.service        # systemd-Unit - Vollbild-Autostart über cage
│   └── install_kiosk.sh             # installiert und aktiviert die obige Unit (auf dem echten CM5 ausführen)
├── tool/
│   └── bump_version.dart            # Versionserhöhungs-Skript, das build.bat/build.sh/build_linux.sh vor jedem Build ausführen (siehe Versionierung weiter oben)
├── run_dev.bat, run_dev.sh          # flutter run - Desktop-Simulationsmodus
├── lib/
│   ├── main.dart                    # App-Einstiegspunkt, ChangeNotifierProvider + Login-Gate, festes dunkles Theme
│   ├── app_version.dart             # GENERIERT - von tool/bump_version.dart regeneriert, nicht von Hand bearbeiten
│   ├── models/
│   │   ├── server_info.dart         # Discovery-/Verbindungseintrag - spiegelt ServerInfo der anderen 3 Clients
│   │   └── hydra_state.dart         # RobotView/ControllerView/HydraState - schlanke veränderbare Sichten auf den rohen settings.json-Baum
│   ├── network/
│   │   ├── hydra_api_client.dart    # REST: Login, Settings, atomarer Roboterbefehl, Systemmetriken - X-Hydra-Client: dsi
│   │   ├── hydra_websocket.dart     # /ws-Live-Sync-Client
│   │   ├── discovery.dart           # Gleichzeitiger Scan der echten lokalen Subnetze dieses Geräts
│   │   └── auth_prefs.dart          # Persistierte Verbindung + Token (shared_preferences)
│   ├── state/
│   │   └── robot_view_model.dart    # Einziger ChangeNotifier, den jeder Bildschirm abonniert
│   └── ui/
│       ├── login_screen.dart        # Host-/Port-/Benutzer-/Passwort-Felder + "Lokales Netzwerk durchsuchen"
│       ├── main_screen.dart         # Horizontale Touch-Navigationsleiste (6 Tabs) - im Geiste von KlipperScreen
│       ├── dashboard_screen.dart    # Karten pro Roboter + Systemmetrik-Leiste
│       ├── control_screen.dart      # Jog-/Geschwindigkeits-/Ventil-/Pumpen-/Wiedergabesteuerung, Touch-Layout nebeneinander
│       ├── camera_screen.dart       # MJPEG-Viewer + Vision-Ein/Aus-Schalter
│       ├── three_d_screen.dart      # Native isometrische X/Y/Z-Anzeige - KEINE WebView (siehe docs/ARCHITECTURE.md §4)
│       ├── metrics_screen.dart      # Dedizierter Tab für CM5-Host-Metriken + Serveridentität
│       ├── settings_screen.dart     # Verbindungsinformationen + Abmelden + eigene App-Version
│       └── widgets/
│           ├── joystick_pad.dart     # Jog-Steuerkreuz, für Touch vergrößert
│           ├── digital_readout.dart, status_led.dart
│           └── mjpeg_view.dart       # Handgeschriebener MJPEG-Stream-Parser
├── linux/                            # GTK-Desktop-Runner - das ECHTE Ziel, festes 1280x720-Fenster
├── windows/                          # Windows-Desktop-Runner - nur Verifikation auf der Entwicklungsmaschine
├── docs/ARCHITECTURE.md
├── test/widget_test.dart
├── README.md                         # Originaldokument (Englisch)
└── README_spa.md / README_ita.md / README_fra.md / README_deu.md  # Übersetzungen
```

## 🔗 Verwandte Projekte

Dieses Projekt ist Teil eines größeren Robotik-Ökosystems desselben Autors (JuanenRac / Electro Hobby 3D). Gut zu wissen, da eine Anfrage sich eigentlich auf eines davon statt auf dieses Repository beziehen könnte:

**HYDRA-UMC-Plattform** — die Multi-Roboter-Mikrofabrikzelle
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** — das Mainboard selbst: Raspberry-Pi-CM5-Host + Dual-Core-STM32H745-Echtzeit-Coprozessor, der bis zu 8 verteilte Roboterarme über CAN-OTA/SPI-OTA orchestriert. Eigene Hardware + Firmware, GPL-3.0/CERN-OHL-S v2/CC BY-SA 4.0.
- **[HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — webbasiertes Steuerungs-Dashboard für HYDRA-UMC: Multi-Roboter-3D-Visualisierung, Kinematik-/Trajektorienaufzeichnung, CAN-OTA-Flashing und -Tests für die gesamte Plattform. React + Vite + Three.js.
- **[HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)** — das Headless-Backend (Node/Express/WebSocket), das früher im eigenen Prozess von HYDRA-UMC-STUDIO gebündelt war. Es beherbergt die REST/WS-API zur Robotersteuerung, die settings.json-Persistenz, die JWT-Authentifizierung und die mDNS-Erkennung. HYDRA-UMC-STUDIO ist jetzt ein reiner statischer Frontend-Client, der über das Netzwerk mit ihm kommuniziert.
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** — Android-Steuerungs-App für HYDRA-UMC über Wi-Fi/Bluetooth. Echte, funktionierende App - vollständiger Funktionsumfang zur Fernsteuerung, JWT-Authentifizierung, verschlüsselte Anmeldedatenspeicherung.
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — iOS/iPadOS-Steuerungs-App für HYDRA-UMC über Wi-Fi, in Flutter erstellt (plattformübergreifend, unter Windows ohne Mac verifizierbar; das endgültige `.ipa`-Packaging benötigt weiterhin Xcode). Echte, funktionierende App - derselbe Funktionsumfang wie die Android-App.
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** — Desktop-Kommandozentrale (Python/PySide6) für den Schwarm: Multi-Controller-Netzwerkerkennung, bidirektionale Live-Synchronisation, echter 3D-Roboter-Viewport, andockbarer Arbeitsbereich im Photoshop-Stil. Echt und funktionsfähig, kein Platzhalter.
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** — grafischer Desktop-URDF-Ersteller/-Editor (Python/PySide6) für den Modellkatalog dieses Projekts: bezieht Quelldateien von GitHub oder einem lokalen Ordner, validiert die Machbarkeit der Freiheitsgrade, bearbeitet Farbe/Skalierung/Kinematik mit Live-3D-Vorschau und überträgt das fertige Ergebnis an einen laufenden STUDIO-Server. Echt und funktionsfähig, kein Platzhalter.
- **HYDRA-UMC-DSI** *(dieses Repository)* — native Flutter-Touch-UI für HYDRA-UMCs eigenen 5"/7"-DSI-Touchscreen (1280×720, gleiche Auflösung bei beiden Größen) am Compute Module 5, das denselben Server direkt von der Platine aus steuert. Echtes, funktionierendes Grundgerüst mit allen 6 Katalogbildschirmen, angebunden an den Live-Server; echter Linux-Ziel-Build noch nicht auf echter Hardware ausgeführt (nur Windows-Arbeitsumgebung - siehe den Abschnitt "Build" des README).

**URTC-Plattform** — der Werkzeugkopf-Controller, den jeder HYDRA-UMC-Roboterarm trägt
- **[URTC](https://github.com/JuanenRac/URTC)** — Universal Robot Tool Controller: STM32F303-basierter CAN-Bus-Werkzeugkopf-Controller, 25 vollständig implementierte Werkzeugprofile, CAN-OTA-Firmware-Update.
- **[URTC Flasher](https://github.com/JuanenRac/URTC-FLASHER)** — Desktop-Tool für CAN-OTA- + Full-Chip-SWD/JTAG-Flashing für URTC-Platinen (Windows/Linux).
- **[URTC Tester](https://github.com/JuanenRac/URTC-TESTER)** — Desktop-Tool für Live-CAN-Bus-Diagnose für URTC-Platinen, ein Panel pro Werkzeugprofil (Windows/Linux).
- **[URTC Web Studio](https://github.com/JuanenRac/URTC-WEB-STUDIO)** — browserbasierte Alternative zu den 2 oben genannten Desktop-Tools (Web Serial API + SLCAN), keine lokale Installation nötig.

---

## 👤 Autor

**JuanenRac** (Electro Hobby 3D)
📧 electrohobby3d@gmail.com
📺 youtube.com/@electrohobby3d

---

## 📜 Lizenz

GNU General Public License v3.0 (GPL-3.0) für den Quellcode - siehe [`LICENSE`](LICENSE).

Die Dokumentation (dieses README und seine Übersetzungen - `README_spa.md`, `README_ita.md`, `README_fra.md`, `README_deu.md`) steht unter **Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)** zur Verfügung. Vollständiger Text unter https://creativecommons.org/licenses/by-sa/4.0/.
