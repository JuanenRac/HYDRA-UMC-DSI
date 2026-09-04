<p align="center">
  <img src="images/HYDRA_UMC_BANNER.svg" alt="HYDRA-UMC-DSI banner" width="100%">
</p>
# 🖥️ HYDRA-UMC DSI

<p align="center">
  <a href="README.md">🇺🇸 English</a> |
  <a href="README_spa.md">🇪🇸 Español</a> |
  <a href="README_fra.md">🇫🇷 Français</a> |
  🇮🇹 <b>Italiano</b> |
  <a href="README_deu.md">🇩🇪 Deutsch</a> |
  <a href="README_zho.md">🇨🇳 简体中文</a> |
  <a href="README_jpn.md">🇯🇵 日本語</a>
</p>


<p align="left">
  <img src="https://img.shields.io/badge/Licenza-GPL%203.0-blue.svg" alt="GPL 3.0">
  <img src="https://img.shields.io/badge/Framework-Flutter%203.x-02569B.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Linguaggio-Dart-0175C2.svg" alt="Dart">
  <img src="https://img.shields.io/badge/Piattaforma-Linux%20%7C%20CM5-E34F26.svg" alt="Platform">
</p>


Un'interfaccia touch nativa in Flutter (Dart, con target reale desktop Linux) per il touchscreen DSI da 5"/7" di HYDRA-UMC sul Compute Module 5 - le due dimensioni fisiche del pannello condividono esattamente la stessa risoluzione di 1280x720 pixel, quindi questa app usa un unico layout fisso, non responsive, invece di adattarsi a due dimensioni. Parla esattamente lo stesso contratto [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-STUDIO/blob/main/docs/REMOTE_API.md) usato da [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE), [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) e [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) - discovery, login, comandi atomici per robot e sincronizzazione live via WebSocket con un server [HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO) in esecuzione, avviata direttamente sulla scheda stessa invece che in una scheda del browser. Vedere [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) per il design completo, incluso il motivo della scelta di Flutter (e non Kivy) e perché la schermata 3D non usa una WebView.

**Questa app è una delle due modalità di controllo che coesistono sulla stessa scheda** - il CM5 gestisce anche un'uscita HDMI per un monitor esterno completo che esegue l'interfaccia web. Questa app DSI integra quel percorso con una console touch diretta e sempre disponibile sulla scheda stessa; non sostituisce l'interfaccia web.

## 🏗️ Cosa è implementato

- **Login** (`lib/ui/login_screen.dart`, `lib/state/robot_view_model.dart`) - campi IP/porta del server precompilati con un valore LAN ragionevole, campi nome utente/password dimensionati per il tocco e vuoti per impostazione predefinita (nessuna credenziale precompilata - il precompilamento iniziale `admin`/`admin` è stato rimosso quando ogni server ha smesso di creare quell'account predefinito al primo avvio reale di produzione), `POST /api/login` verso l'account inserito dall'operatore; è possibile creare account aggiuntivi a privilegio minore "operator" da Config > Users nell'interfaccia web. Token di sessione persistito tra gli avvii tramite `shared_preferences` - importante su un pannello kiosk che deve restare autenticato anche dopo un ciclo di spegnimento/accensione del CM5 stesso, non solo dopo la riapertura dell'app. Una finestra di dialogo "Scan local network" (`lib/network/discovery.dart`) trova i server senza dover già conoscere l'IP - doppiamente utile qui, dato che il CM5 su cui gira questa app è spesso proprio il controller a cui deve connettersi.
- **Discovery di rete** (`lib/network/discovery.dart`) - due percorsi in parallelo dalla stessa finestra "Scan local network": mDNS/Bonjour reale (`discoverMdns()`, interrogando il servizio `_hydra._tcp` pubblicato da `server.ts` tramite il pacchetto `multicast_dns`) e una scansione concorrente a forza bruta di `GET /api/hydra-info` sulle sottoreti locali reali di questo dispositivo (`scanSubnets()`), deduplicata per host:porta - portato da HYDRA-UMC-IOS-CONTROL, il primo client dell'ecosistema ad aggiungere mDNS reale.
- **Sincronizzazione atomica dei comandi** (`lib/state/robot_view_model.dart`, il proprio `_sendAtomicCommand()`) - ogni scrittura (enable/disable/play/pause/stop/jog/valve/pump/speed/vision) usa il reale endpoint `POST /api/robot/:id/command`, con la corretta propagazione ai robot combinati (`combinedWith`) e un rollback allo stato precedente se la richiesta fallisce - particolarmente importante per un pendant di jog/E-STOP posizionato a pochi metri dai robot reali.
- **Sincronizzazione live via WebSocket** (`lib/network/hydra_websocket.dart`) - allega sempre `?token=`, gestisce sia i tipi di broadcast `"settings"` che `"delta"`, si riconnette automaticamente in caso di caduta.
- **Navigazione touch orizzontale** (`lib/ui/main_screen.dart`) - una barra superiore persistente con 6 grandi schede icona+etichetta (Dashboard/Control/Camera/Vista 3D/Metriche/Impostazioni) lungo tutta la larghezza fissa di 1280px, nello spirito di KlipperScreen invece di una barra di navigazione inferiore in stile telefono - seguendo il catalogo richiesto dal proprietario del progetto, riorganizzato per un pannello touch largo invece di un layout verticale da telefono.
- **Dashboard** (`lib/ui/dashboard_screen.dart`) - schede per robot, reattive in tempo reale tramite `Provider`, convenzione dei LED (verde lampeggiante = attivo, rosso fisso = inattivo), visualizzazione dei robot combinati e chip dei moduli (CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK) - lo stesso linguaggio visivo di tutti gli altri client di questo ecosistema.
- **Controllo Manuale** (`lib/ui/control_screen.dart`, `lib/ui/widgets/joystick_pad.dart`) - layout affiancato (pad di jog a sinistra, telemetria/velocità/IO a destra) dimensionato per il frame 1280x720 invece di un'unica colonna scorrevole, reale protezione a pressione prolungata su E-STOP/STOP (un tocco rapido non fa nulla se non una vibrazione + un suggerimento visivo, solo una pressione prolungata reale invia il comando), cursori di velocità/accelerazione, interruttori di valvole/pompe.
- **Camera** (`lib/ui/camera_screen.dart`, `lib/ui/widgets/mjpeg_view.dart`) - lo stesso parser MJPEG scritto a mano e senza dipendenze usato da HYDRA-UMC-IOS-CONTROL (nessuna WebView, nessun codice specifico della piattaforma - funziona su desktop Linux senza modifiche), uno stato chiaro di "Camera Disabilitata" e un interruttore per attivare/disattivare la visione di un robot direttamente dal server.
- **Vista 3D** (`lib/ui/three_d_screen.dart`) - **non** è una WebView che incorpora la vera scena Three.js di STUDIO, a differenza delle app iOS/Android - `webview_flutter` non ha alcuna implementazione per desktop Linux, e un motore browser completo rappresenta un carico di runtime maggiore di quanto serva a questo pannello embedded a basso consumo. Al suo posto: un piccolo indicatore isometrico nativo di posizione X/Y/Z (`CustomPainter`, nessun motore 3D), con una nota a schermo che rimanda alla vera scena 3D sul monitor collegato via HDMI a questa stessa scheda. Vedere la sezione 4 di `docs/ARCHITECTURE.md` per il ragionamento completo.
- **Metriche di Sistema** (`lib/ui/metrics_screen.dart`) - una scheda dedicata (non integrata nella Dashboard come fanno iOS/Android) con riquadri di CPU/memoria/temperatura/uptime da `GET /api/system/metrics`, più hostname/numero di controller/numero di robot/versione app da `GET /api/hydra-info`.
- **Impostazioni** (`lib/ui/settings_screen.dart`) - informazioni di connessione, identità del server, logout e la versione stessa di questa app (vedere [Versionamento](#-versionamento) più sotto).
- **Avvio automatico kiosk** (`kiosk/hydra-umc-dsi.service`, `kiosk/install_kiosk.sh`) - unit systemd che avvia l'app a schermo intero su `tty1` tramite `cage`, con `Restart=always`. Vedere "Esecuzione sul CM5 reale" più sotto.
- **UI in 7 lingue** (`lib/l10n/`, pipeline standard `flutter gen-l10n`) - inglese, spagnolo, francese, tedesco, italiano, giapponese e cinese, come il resto dei client di questo ecosistema. Un'impostazione persistente in `Impostazioni > Lingua` usa come predefinita la lingua di sistema; `RobotViewModel.lastError` è un `HydraError` tipizzato invece di testo inglese già formattato, quindi anche i messaggi di errore della logica di business vengono tradotti correttamente, non solo il testo statico delle schermate.

**Stato: scaffold + tutte le 6 schermate del catalogo implementate e collegate al contratto reale REMOTE_API.md.** `flutter analyze` pulito, sia `flutter build windows` che `flutter build linux` (via WSL2) producono un binario funzionante, `flutter test` passa - vedere "Compilazione" più sotto per cosa è stato verificato e cosa no, incluso il divario rimasto tra questa verifica su WSL2 e il vero hardware della CM5.

## 🚀 Compilazione

Richiede il [Flutter SDK](https://docs.flutter.dev/get-started/install) (canale stable). Questo repository viene compilato/verificato con Flutter 3.47.0. Solo `linux/` e `windows/` sono configurate come piattaforme in questo repository (nessuna cartella `android/`, `ios/`, `web/` o `macos/`) - Linux è il target reale (il sistema operativo del CM5 stesso); Windows esiste unicamente per poter compilare, eseguire e testare la logica di questa app su una macchina priva di toolchain Linux.

### Script di compilazione

```bash
./build.sh          # Git Bash / WSL, oppure build.bat per cmd/PowerShell - flutter pub get + incremento versione + flutter build windows (verifica sulla macchina di sviluppo)
./build_linux.sh    # Deve essere eseguito SU una macchina Linux reale (o sul CM5 stesso) - flutter pub get + incremento versione + flutter build linux (il vero target di deployment)
./run_dev.sh         # Git Bash / WSL, oppure run_dev.bat per cmd/PowerShell - modalità simulazione desktop (flutter run), senza bisogno dell'hardware
```

Tutti e 3 gli script di compilazione (`build.sh`/`build.bat`/`build_linux.sh`) incrementano prima la versione dell'app - vedere [Versionamento](#-versionamento) più sotto. `run_dev.sh`/`run_dev.bat` non lo fanno - un `flutter run` da ciclo di sviluppo non è una "compilazione reale" secondo questa policy.

### Compilazione manuale

```bash
flutter pub get
flutter analyze                  # analisi statica - non serve un compilatore
flutter test                     # test dei widget
dart run tool/bump_version.dart  # incrementa la versione, come fanno build.sh/build.bat/build_linux.sh
flutter build windows            # smoke test sulla macchina di sviluppo - produce build/windows/x64/runner/Release/hydra_umc_dsi.exe
flutter build linux              # il target REALE - deve essere eseguito su una macchina Linux reale, produce build/linux/*/release/bundle/
flutter run -d windows           # oppure -d linux su una macchina Linux reale, per un ciclo di sviluppo live in simulazione desktop
```

**Nota di onestà sulla verifica Linux:** `flutter build linux --release` è stato ora effettivamente eseguito su questo codice, da un vero ambiente Ubuntu 24.04 su WSL2 con una vera toolchain desktop Linux (`cmake`, `ninja-build`, `libgtk-3-dev`, `clang`) - compila pulito e produce un vero `build/linux/x64/release/bundle/hydra_umc_dsi`, confermato come effettivamente avviabile (è stato eseguito sotto un vero display X11 ed è rimasto attivo, non solo un codice di uscita 0), non solo `flutter build windows` come sostituto di smoke test. Cosa **non** copre questo: lo userspace di WSL2 è x86_64, non il vero aarch64 del Raspberry Pi OS della CM5, e il flusso di autoavvio di `kiosk/hydra-umc-dsi.service` non è comunque mai stato eseguito su una vera macchina Linux. Vedere la sezione 7 di `docs/ARCHITECTURE.md` per l'elenco esatto di ciò che è stato e non è stato verificato, e "Prossimi Passi Noti" più sotto per ciò che resta da fare.

## 🔢 Versionamento

Questo repository segue una policy a livello di ecosistema (condivisa con
[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL),
implementata lì in parallelo): la versione viene incrementata
automaticamente a **ogni compilazione reale**, senza modifica manuale
della riga `version:` di `pubspec.yaml`. `build.sh`/`build.bat`/
`build_linux.sh` eseguono `tool/bump_version.dart` prima di invocare
`flutter build`, applicando:

- **Patch, stile contachilometri (base 10):** +1 a ogni compilazione; se
  supererebbe 9, si resetta a 0 e la minor sale di +1 - esempio: `0.0.9`
  -> `0.1.0`. La major non viene mai toccata automaticamente.
- **Build-number** (la parte dopo il `+`): un semplice contatore
  monotono, +1 a ogni compilazione, senza riporto.

Lo stesso script rigenera `lib/app_version.dart` (generato, non
modificato a mano - un semplice file `const`, non una nuova dipendenza a
runtime come `package_info_plus`), che l'app legge a runtime per
mostrare la propria versione nella schermata **Impostazioni**. Vedere
[CHANGELOG.md](CHANGELOG.md) per lo storico delle versioni.

### Esecuzione sul CM5 reale

Dopo che `build_linux.sh` produce `build/linux/*/release/bundle/`, copia l'intera directory `bundle/` sul CM5 (dipende dai file `.so` accanto al binario, non solo dall'eseguibile stesso) in `/opt/hydra-umc-dsi/bundle/`, poi esegui `sudo kiosk/install_kiosk.sh` per installare e abilitare `kiosk/hydra-umc-dsi.service`, una unit systemd che avvia l'app a schermo intero su `tty1` tramite [`cage`](https://github.com/cage-kiosk/cage) (un compositore kiosk Wayland minimale che esegue esattamente un client a schermo intero), con `Restart=always` così un crash rilancia l'app invece di lasciare lo schermo nero. Scelto rispetto a [`flutter-pi`](https://github.com/ardera/flutter-pi) (un embedder del motore Flutter di terze parti per Raspberry Pi, eseguito senza alcun window system) proprio perché riutilizza senza modifiche l'output reale di `flutter build linux` già prodotto da `build_linux.sh` - flutter-pi invece compila direttamente contro il motore Flutter, quindi richiederebbe un proprio passaggio di build separato, non è un sostituto diretto. **Nota di onestà:** scritto e revisionato, ma mai eseguito realmente contro un CM5 reale o qualsiasi altra macchina Linux - a differenza dello stesso `flutter build linux`, ora verificato sotto WSL2 (vedere `docs/ARCHITECTURE.md` sezione 7), questo flusso di autoavvio del kiosk resta interamente non verificato. Vedere il commento di intestazione di `kiosk/hydra-umc-dsi.service` per le assunzioni esatte (utente root del servizio, possesso di `tty1`) da verificare contro l'immagine Raspberry Pi OS effettivamente usata dal CM5.

## 🗺️ Prossimi Passi Noti

Lacune reali e verificate che il codice di questa app ha ancora - non TODO vaghi, ognuna riconducibile a un punto preciso del codice o della documentazione sopra:

- **L'interruttore di accesso remoto non è ancora indipendente** - la sezione 1 di `REMOTE_API.md` riconosce solo `suite`, `android` e `ios` come valori di `X-Hydra-Client`; questa app invia `dsi`, un valore non riconosciuto che oggi non viene mai filtrato, quindi le sue richieste di discovery passano senza alcun controllo. Risolverlo richiede di aggiungere un 4° interruttore al tipo `SystemSettings.remoteAccess` di HYDRA-UMC-STUDIO e alla sua scheda Config > Remote Access - una modifica al codice server di un altro repository, fuori dall'ambito di questo. Vedere la sezione 3 di `docs/ARCHITECTURE.md`.
- **La vista 3D non ha un vero renderer 3D nativo** - `ui/three_d_screen.dart` disegna oggi un piccolo indicatore isometrico di posizione X/Y/Z invece di incorporare la vera scena Three.js di STUDIO (`webview_flutter` non ha alcuna implementazione Linux - vedere la sezione 4 di `docs/ARCHITECTURE.md` per il ragionamento completo). Un vero renderer 3D nativo per questa schermata è lavoro futuro, non ancora iniziato.
- **Manca ancora un'esecuzione reale sull'hardware della CM5** - `flutter build linux` in sé è ora verificato (vera toolchain Ubuntu 24.04 su WSL2, binario confermato come effettivamente avviabile - vedere la sezione 7 di `docs/ARCHITECTURE.md`), ma il flusso completo di `build_linux.sh` e l'unità di avvio automatico `kiosk/hydra-umc-dsi.service` non sono comunque mai stati eseguiti contro il CM5 stesso o qualsiasi altra vera macchina Linux (non-WSL2). Chi li esegue lì per la prima volta dovrebbe considerarlo come il vero primo deploy hardware di questa piattaforma, non una formalità - vedere "Esecuzione sul CM5 reale" più sopra.

## 📂 Struttura del Repository

```text
HYDRA-UMC-DSI/
├── build.bat, build.sh              # flutter pub get + incremento versione + flutter build windows (verifica sulla macchina di sviluppo)
├── build_linux.sh                   # flutter pub get + incremento versione + flutter build linux (il vero target CM5 - eseguire su Linux reale)
├── CHANGELOG.md                      # storico delle versioni (vedere Versionamento più sopra)
├── kiosk/
│   ├── hydra-umc-dsi.service        # unit systemd - avvio automatico a schermo intero via cage
│   └── install_kiosk.sh             # installa e abilita la unit sopra (eseguire sul CM5 reale)
├── tool/
│   └── bump_version.dart            # Script di incremento versione eseguito da build.bat/build.sh/build_linux.sh prima di ogni compilazione (vedere Versionamento più sopra)
├── run_dev.bat, run_dev.sh          # flutter run - modalità simulazione desktop
├── lib/
│   ├── main.dart                    # Entry point dell'app, ChangeNotifierProvider + gate di login, tema scuro fisso
│   ├── app_version.dart             # GENERATO - rigenerato da tool/bump_version.dart, non modificare a mano
│   ├── models/
│   │   ├── server_info.dart         # Voce di discovery/connessione - rispecchia ServerInfo negli altri 3 client
│   │   └── hydra_state.dart         # RobotView/ControllerView/HydraState - viste mutabili leggere sull'albero grezzo di settings.json
│   ├── network/
│   │   ├── hydra_api_client.dart    # REST: login, settings, comando atomico robot, metriche di sistema - X-Hydra-Client: dsi
│   │   ├── hydra_websocket.dart     # Client di sincronizzazione live /ws
│   │   ├── discovery.dart           # Scansione concorrente delle sottoreti locali reali di questo dispositivo
│   │   └── auth_prefs.dart          # Connessione e token persistiti (shared_preferences)
│   ├── state/
│   │   ├── robot_view_model.dart    # Unico ChangeNotifier ascoltato da ogni schermata
│   │   └── hydra_error.dart         # Superficie di errore tipizzata per RobotViewModel (senza un proprio BuildContext)
│   ├── services/
│   │   └── backlight.dart           # Retroilluminazione adattiva in base all'ora del giorno
│   ├── l10n/                        # Localizzazioni reali generate (7 lingue) - vedi l10n.yaml nella radice del repo
│   │   ├── app_localizations.dart   # Classe base generata
│   │   ├── app_localizations_en.dart, _es.dart, _it.dart, _fr.dart, _de.dart, _ja.dart, _zh.dart
│   │   └── language_prefs.dart      # Override della lingua persistito (shared_preferences)
│   └── ui/
│       ├── login_screen.dart        # Campi host/porta/utente/password + "Scan local network"
│       ├── main_screen.dart         # Barra di navigazione touch orizzontale (6 schede) - nello spirito di KlipperScreen
│       ├── dashboard_screen.dart    # Schede per robot + barra delle metriche di sistema
│       ├── control_screen.dart      # Controlli di jog/velocità/valvole/pompe/riproduzione, layout touch affiancato
│       ├── camera_screen.dart       # Visualizzatore MJPEG + interruttore visione
│       ├── three_d_screen.dart      # Indicatore isometrico nativo X/Y/Z - NON è una WebView (vedere docs/ARCHITECTURE.md §4)
│       ├── metrics_screen.dart      # Scheda dedicata alle metriche host CM5 + identità del server
│       ├── settings_screen.dart     # Informazioni di connessione + logout + versione propria dell'app
│       └── widgets/
│           ├── joystick_pad.dart     # Pad direzionale di jog, ingrandito per il tocco
│           ├── digital_readout.dart, status_led.dart
│           └── mjpeg_view.dart       # Parser di stream MJPEG scritto a mano
├── linux/                            # Runner desktop GTK - il target REALE, finestra fissa 1280x720
├── windows/                          # Runner desktop Windows - solo verifica sulla macchina di sviluppo
├── docs/ARCHITECTURE.md
├── tools/
│   └── ci_validate.py               # Validazione manifest/CHANGELOG/docs usata dalla CI
├── bump_manifest_version.py          # Sincronizza la versione di hydra-umc.project.json con quella nativa (--sync)
├── test/                             # widget_test, format_uptime_test, localization_test, robot_view_model_test
├── README.md                         # documento originale (inglese)
└── README_spa.md / README_ita.md / README_fra.md / README_deu.md / README_zho.md / README_jpn.md  # traduzioni
```

## 🔗 Progetti Correlati

Questo progetto fa parte dell'ecosistema robotico HYDRA-UMC dello stesso autore (JuanenRac / Electro Hobby 3D). Vale la pena conoscerlo, poiché una richiesta potrebbe in realtà riguardare uno di questi invece di questo repository.

**Progetto Padre**
- **[HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)** — il vero backend headless (REST/WebSocket) con cui parla davvero ogni client di controllo; il server a cui si connette questo pannello tramite il vero contratto `REMOTE_API.md` (scoperta, login, comandi atomici, sincronizzazione WebSocket).

**Progetti Fratelli** — parlano anch'essi con la stessa API di HYDRA-UMC-SERVER, ciascuno come proprio client
- **[HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — dashboard di controllo web con visualizzazione 3D multi-robot in tempo reale.
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** — centro di comando sciame desktop (PySide6) per più server contemporaneamente, pacchettizzato come eseguibile standalone; parla esattamente lo stesso contratto `REMOTE_API.md` di questo pannello.
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** — app di controllo nativa per Android con login biometrico e un companion Wear OS abbinato; parla esattamente lo stesso contratto `REMOTE_API.md` di questo pannello.
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — app di controllo per iOS/iPadOS (Flutter) con sincronizzazione WebSocket in tempo reale; parla esattamente lo stesso contratto `REMOTE_API.md` di questo pannello, ed è da cui è stata portata la vera scoperta mDNS propria di questo pannello.
- **[HYDRA-UMC-BRIDGE-AMR](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-AMR)** — barriera di coordinamento per flotte AGV/AMR tramite un publisher MQTT VDA 5050 reale.
- **[HYDRA-UMC-BRIDGE-CNC](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-CNC)** — coordinatore ad alto livello per celle CNC con accesso reale a stato/byte di controllo GRBL.
- **[HYDRA-UMC-BRIDGE-DROIDS](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-DROIDS)** — barriera di coordinamento per droidi con zampe/umanoidi, con un vero mittente di comandi per Boston Dynamics Spot.
- **[HYDRA-UMC-BRIDGE-LASER](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-LASER)** — coordinatore di sicurezza per celle laser che legge 3 salvaguardie GPIO reali di chiave/involucro/interblocco.
- **[HYDRA-UMC-BRIDGE-OPENPNP](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-OPENPNP)** — coordinatore ad alto livello sicuro per il flusso schede del pick-and-place OpenPnP.
- **[HYDRA-UMC-BRIDGE-PRINTER3D](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-PRINTER3D)** — barriera di coordinamento sicura per stampanti 3D Moonraker/Klipper, con comandi di lavoro reali e controllati.
- **[HYDRA-UMC-BRIDGE-ROS2](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-ROS2)** — coordinatore di sicurezza con un vero trasporto ROS 2 rclpy, importato in modo lazy.
- **[HYDRA-UMC-BRIDGE-UAV](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-UAV)** — barriera di coordinamento per UAV dotati di fotocamera, con un vero mittente di comandi MAVLink.

**Direttamente Correlati**
- **[HYDRA-UMC-WATCH](https://github.com/JuanenRac/HYDRA-UMC-WATCH)** — app companion WearOS con avvisi aptici reali e un relay vocale verso il telefono abbinato; il dispositivo di allarme di sicurezza indossabile che completa questo pannello touch, portando gli avvisi al polso dell'operatore oltre allo schermo della scheda.
- **[HYDRA-UMC-COGNITIVE-NODE](https://github.com/JuanenRac/HYDRA-UMC-COGNITIVE-NODE)** — hub di integrazione per la pipeline cognitiva Hailo-10 (orchestrazione LLM/VLA/voce); aggiunge il controllo vocale direttamente su questo pannello touch.
- **[HYDRA-UMC-VOICE-UI](https://github.com/JuanenRac/HYDRA-UMC-VOICE-UI)** — vero front-end vocale (VAD + parser di intenti) con un relay verso Watch limitato e soggetto a conferma; aggiunge il controllo vocale direttamente su questo pannello touch.

**Fa Anche Parte dell'Ecosistema**

*Hardware e Piattaforma di Base*
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** — la scheda madre fisica del braccio robotico: host CM5 + coprocessore STM32H745 dual-core, che coordina fino a 8 bracci utensile via CAN-OTA/SPI-OTA.
- **[HYDRA-UMC-OS](https://github.com/JuanenRac/HYDRA-UMC-OS)** — livello prodotto riproducibile su Raspberry Pi OS per il CM5: agente in sola lettura, config/profili validati, provisioning WiFi al primo contatto.
- **[HYDRA-UMC-SDK](https://github.com/JuanenRac/HYDRA-UMC-SDK)** — il contratto JSON-Schema condiviso e la barriera di sicurezza contro cui ogni bridge valida i propri comandi.

*Backend Centrale e Client*
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** — creatore/editor grafico desktop di URDF che invia i modelli finiti al catalogo di STUDIO.

*Piattaforma Strumenti URTC*
- **[URTC](https://github.com/JuanenRac/URTC)** — firmware per la scheda fisica dell'Universal Robot Tool Controller, oltre 25 profili utensile su bus CAN.
- **[URTC-FLASHER](https://github.com/JuanenRac/URTC-FLASHER)** — strumento desktop con GUI per il flashing delle schede URTC, CAN-OTA più SWD/JTAG a chip intero.
- **[URTC-TESTER](https://github.com/JuanenRac/URTC-TESTER)** — strumento desktop di diagnostica CAN-bus dal vivo per schede URTC, un pannello per profilo utensile.
- **[URTC-WEB-STUDIO](https://github.com/JuanenRac/URTC-WEB-STUDIO)** — alternativa basata su browser a URTC-TESTER tramite la Web Serial API, senza installazione locale.

*Nodo IA Visione (Hailo-8)*
- **[HYDRA-UMC-VISION-NODE](https://github.com/JuanenRac/HYDRA-UMC-VISION-NODE)** — hub di integrazione per la pipeline di visione Hailo-8, con un vero controllo di prontezza hardware per fase.
- **[HYDRA-UMC-DETECTION-HEF](https://github.com/JuanenRac/HYDRA-UMC-DETECTION-HEF)** — registro reale di modelli compilati con verifica di caricamento sicuro per architettura Hailo/checksum.
- **[HYDRA-UMC-VISION-STREAMER](https://github.com/JuanenRac/HYDRA-UMC-VISION-STREAMER)** — generatore reale di pipeline GStreamer + config MediaMTX, con una vera barriera di integrazione HailoRT.
- **[HYDRA-UMC-VISUAL-SERVOING-API](https://github.com/JuanenRac/HYDRA-UMC-VISUAL-SERVOING-API)** — vera legge di correzione Position-Based Visual Servoing, con cancello di sicurezza sullo stato di zona a monte.
- **[HYDRA-UMC-SAFETY-ZONES](https://github.com/JuanenRac/HYDRA-UMC-SAFETY-ZONES)** — vero controllo di violazione zona e richiesta E-STOP, con imposizione della freschezza di calibrazione.

*Nodo IA Cognitivo (Hailo-10)*
- **[HYDRA-UMC-VLA-ENGINE](https://github.com/JuanenRac/HYDRA-UMC-VLA-ENGINE)** — vera codifica/decodifica di token d'azione e generazione di traiettoria per un modello Vision-Language-Action.
- **[HYDRA-UMC-SEMANTIC-PLANNER](https://github.com/JuanenRac/HYDRA-UMC-SEMANTIC-PLANNER)** — vera scomposizione dei task basata su regole e recupero semantico degli errori sui codici errore MCU.
- **[HYDRA-UMC-DOCS-QA](https://github.com/JuanenRac/HYDRA-UMC-DOCS-QA)** — vera ricerca documentale TF-IDF (solo libreria standard) sui documenti Markdown di questo ecosistema.

*Orchestrazione e Sciame*
- **[HYDRA-UMC-ORCHESTRATOR](https://github.com/JuanenRac/HYDRA-UMC-ORCHESTRATOR)** — hub di integrazione con un vero contratto di health-report gRPC/Protobuf e una macchina a stati di missione.
- **[HYDRA-UMC-JOB-DISPATCHER](https://github.com/JuanenRac/HYDRA-UMC-JOB-DISPATCHER)** — vera coda di lavori basata su priorità con deduplicazione, su una vera API HTTP.
- **[HYDRA-UMC-NODE-HEALING](https://github.com/JuanenRac/HYDRA-UMC-NODE-HEALING)** — vero watchdog di salute della flotta basato su gRPC, con retry/backoff e rilevamento di discrepanza d'identità.
- **[HYDRA-UMC-PATH-PLANNER-3D](https://github.com/JuanenRac/HYDRA-UMC-PATH-PLANNER-3D)** — vero pianificatore di percorsi 3D basato su RRT, con vera validazione delle collisioni ostacolo/spazio di lavoro.
- **[HYDRA-UMC-SWARM-SYNC](https://github.com/JuanenRac/HYDRA-UMC-SWARM-SYNC)** — vera sincronizzazione di stato CRDT LWW-Element-Map, con property test per la convergenza multi-cella.

*Gemello Digitale e Simulazione*
- **[HYDRA-UMC-TWIN](https://github.com/JuanenRac/HYDRA-UMC-TWIN)** — hub di integrazione per il motore di gemello digitale, con un vero contratto di sincronizzazione per compatibilità di versione.
- **[HYDRA-UMC-HIL-BRIDGE](https://github.com/JuanenRac/HYDRA-UMC-HIL-BRIDGE)** — vero interblocco di sicurezza hardware-in-the-loop che instrada i comandi tra simulazione e hardware reale.
- **[HYDRA-UMC-PHYSICS-REPLICA](https://github.com/JuanenRac/HYDRA-UMC-PHYSICS-REPLICA)** — vera cinematica diretta e validazione dei limiti articolari su un vero sottoinsieme URDF.
- **[HYDRA-UMC-SYNTHETIC-DATA-GEN](https://github.com/JuanenRac/HYDRA-UMC-SYNTHETIC-DATA-GEN)** — vero generatore procedurale di scene 2D con esportazione di annotazioni YOLO/COCO.

*Dati e Analisi*
- **[HYDRA-UMC-DATALAKE](https://github.com/JuanenRac/HYDRA-UMC-DATALAKE)** — vero archivio di serie temporali basato su sqlite3, con una vera API HTTP di ingestione/query.
- **[HYDRA-UMC-ANOMALY-DETECTOR](https://github.com/JuanenRac/HYDRA-UMC-ANOMALY-DETECTOR)** — vero rilevatore di anomalie FFT + baseline statistica, con monitoraggio della deriva.
- **[HYDRA-UMC-PRODUCTION-REPORTS](https://github.com/JuanenRac/HYDRA-UMC-PRODUCTION-REPORTS)** — vero calcolo OEE/disponibilità sullo storico di DATALAKE, con esportazione CSV riproducibile.
- **[HYDRA-UMC-TELEMETRY-COLLECTOR](https://github.com/JuanenRac/HYDRA-UMC-TELEMETRY-COLLECTOR)** — vera pipeline di ingestione CAN/WebSocket verso DATALAKE, con deduplicazione per sequenza.

*Gateway Industriale*
- **[HYDRA-UMC-GATEWAY-INDUSTRIAL](https://github.com/JuanenRac/HYDRA-UMC-GATEWAY-INDUSTRIAL)** — hub di integrazione che inoltra ai protocolli industriali, con un vero livello di allowlist dei comandi/backpressure.
- **[HYDRA-UMC-OPCUA-SERVER](https://github.com/JuanenRac/HYDRA-UMC-OPCUA-SERVER)** — vero spazio di indirizzi OPC-UA, verificato con una vera sessione client del protocollo binario.
- **[HYDRA-UMC-MQTT-BROKER](https://github.com/JuanenRac/HYDRA-UMC-MQTT-BROKER)** — vero broker MQTT con autenticazione opzionale per client e ACL sui topic.
- **[HYDRA-UMC-MTCONNECT-ADAPTER](https://github.com/JuanenRac/HYDRA-UMC-MTCONNECT-ADAPTER)** — veri endpoint XML `/probe` e `/current` di MTConnect, con output in modalità degradata.

*Strumenti Complementari e Operazioni dell'Ecosistema*
- **[HYDRA-UMC-DASHBOARD-AI](https://github.com/JuanenRac/HYDRA-UMC-DASHBOARD-AI)** — pannelli Smart Summaries e Anomaly Highlighting su DATALAKE/ANOMALY-DETECTOR, con un fallback statistico onesto.
- **[HYDRA-UMC-TOOL-CLI](https://github.com/JuanenRac/HYDRA-UMC-TOOL-CLI)** — CLI di flotta con un vero e stabile contratto di exit-code, un client live reale della stessa API di HYDRA-UMC-SERVER.
- **[URTC-SMART-RACK](https://github.com/JuanenRac/URTC-SMART-RACK)** — firmware per un rack di montaggio schede con decodifica reale dell'ID utensile e logica di preriscaldamento Smart Idle.
- **[URTC-VISION-TOOL](https://github.com/JuanenRac/URTC-VISION-TOOL)** — firmware più un vero companion di visione Python per una testa utensile di ispezione termica/RGB.
- **[HYDRA-UMC-UPDATER](https://github.com/JuanenRac/HYDRA-UMC-UPDATER)** — strumento amministrativo desktop che scopre, clona e aggiorna ogni repository di questo ecosistema.
- **[HYDRA-UMC-OS-REBUILDER](https://github.com/JuanenRac/HYDRA-UMC-OS-REBUILDER)** — strumento desktop Windows/Linux che costruisce un'immagine della CM5 pronta da scrivere, precaricata con le versioni più aggiornate dell'ecosistema, con configurazione di primo avvio Wi-Fi/utente/SSH in stile Raspberry Pi Imager.

---

## 📚 Documentazione e Comunità

- **[CONTRIBUTING.md](CONTRIBUTING.md)** — stack tecnologico e linee guida di codifica per una pull request.
- **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** — gli standard di comportamento attesi in questa comunità.
- **[SECURITY.md](SECURITY.md)** — come segnalare una vulnerabilità, e le reali aree di attenzione sulla sicurezza di questo progetto.
- **[SUPPORT.md](SUPPORT.md)** — dove porre domande e segnalare bug.
- **[LICENSE.md](LICENSE.md)** — la licenza propria di questo progetto.

## 👤 AUTORE
**JuanenRac** (Electro Hobby 3D)
📧 electrohobby3d@gmail.com
📺 [youtube.com/@electrohobby3d](https://youtube.com/@electrohobby3d)

## 📜 LICENZA

GNU General Public License v3.0 (GPL-3.0) per il codice sorgente - vedere [`LICENSE`](LICENSE).

La documentazione (questo README e le sue traduzioni - `README_spa.md`, `README_ita.md`, `README_fra.md`, `README_deu.md`, `README_zho.md`, `README_jpn.md`) è disponibile sotto **Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)**. Testo completo su https://creativecommons.org/licenses/by-sa/4.0/.
