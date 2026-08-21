# 🖥️ HYDRA-UMC DSI

Un'interfaccia touch nativa in Flutter (Dart, con target reale desktop Linux) per il touchscreen DSI da 5"/7" di HYDRA-UMC sul Compute Module 5 - le due dimensioni fisiche del pannello condividono esattamente la stessa risoluzione di 1280x720 pixel, quindi questa app usa un unico layout fisso, non responsive, invece di adattarsi a due dimensioni. Parla esattamente lo stesso contratto [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-STUDIO/blob/main/docs/REMOTE_API.md) usato da [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE), [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) e [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) - discovery, login, comandi atomici per robot e sincronizzazione live via WebSocket con un server [HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO) in esecuzione, avviata direttamente sulla scheda stessa invece che in una scheda del browser. Vedere [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) per il design completo, incluso il motivo della scelta di Flutter (e non Kivy) e perché la schermata 3D non usa una WebView.

**Questa app è una delle due modalità di controllo che coesistono sulla stessa scheda** - il CM5 gestisce anche un'uscita HDMI per un monitor esterno completo che esegue l'interfaccia web. Questa app DSI integra quel percorso con una console touch diretta e sempre disponibile sulla scheda stessa; non sostituisce l'interfaccia web.

## 🏗️ Cosa è implementato

- **Login** (`lib/ui/login_screen.dart`, `lib/state/robot_view_model.dart`) - campi IP/porta del server e nome utente/password dimensionati per il tocco, `POST /api/login` verso `admin`/`admin` (precompilato - l'account predefinito che ogni server di questo ecosistema crea al primo avvio; è possibile creare account aggiuntivi a privilegio minore "operator" da Config > Users nell'interfaccia web), token di sessione persistito tra gli avvii tramite `shared_preferences` - importante su un pannello kiosk che deve restare autenticato anche dopo un ciclo di spegnimento/accensione del CM5 stesso, non solo dopo la riapertura dell'app. Una finestra di dialogo "Scan local network" (`lib/network/discovery.dart`) trova i server senza dover già conoscere l'IP - doppiamente utile qui, dato che il CM5 su cui gira questa app è spesso proprio il controller a cui deve connettersi.
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

**Stato: scaffold + tutte le 6 schermate del catalogo implementate e collegate al contratto reale REMOTE_API.md.** `flutter analyze` pulito, `flutter build windows` produce un binario funzionante, `flutter test` passa - vedere "Compilazione" più sotto per cosa è stato e non è stato possibile verificare da questo ambiente di lavoro Windows, dato che il target reale è Linux.

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

**Nota di onestà sulla verifica Linux:** questo repository è stato scritto su una macchina Windows senza alcuna toolchain di compilazione Linux disponibile (confermato con `wsl --status` - nessuna distribuzione WSL installata). `flutter build linux` non è mai stato effettivamente eseguito su questo codice da questo ambiente di lavoro; `flutter build windows` è stato usato come sostituto di smoke test, come esplicitamente consentito dall'incarico. Vedere la sezione 7 di `docs/ARCHITECTURE.md` per l'elenco esatto di ciò che è stato e non è stato verificato, e `mejoras_futuras.txt` per il seguito da fare.

## 🔢 Versionamento

Questo repository segue una policy a livello di ecosistema (condivisa con
[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL),
implementata lì in parallelo): la versione viene incrementata
automaticamente a **ogni compilazione reale**, senza modifica manuale
della riga `version:` di `pubspec.yaml`. `build.sh`/`build.bat`/
`build_linux.sh` eseguono `tool/bump_version.dart` prima di invocare
`flutter build`, applicando:

- **Patch, stile contachilometri (base 10):** +1 a ogni compilazione; se
  supererebbe 9, si resetta a 0 e la minor sale di +1 - esempio: `1.0.9`
  -> `1.1.0`. La major non viene mai toccata automaticamente.
- **Build-number** (la parte dopo il `+`): un semplice contatore
  monotono, +1 a ogni compilazione, senza riporto.

Lo stesso script rigenera `lib/app_version.dart` (generato, non
modificato a mano - un semplice file `const`, non una nuova dipendenza a
runtime come `package_info_plus`), che l'app legge a runtime per
mostrare la propria versione nella schermata **Impostazioni**. Vedere
[CHANGELOG.md](CHANGELOG.md) per lo storico delle versioni.

### Esecuzione sul CM5 reale

Dopo che `build_linux.sh` produce `build/linux/*/release/bundle/`, copia l'intera directory `bundle/` sul CM5 (dipende dai file `.so` accanto al binario, non solo dall'eseguibile stesso) in `/opt/hydra-umc-dsi/bundle/`, poi esegui `sudo kiosk/install_kiosk.sh` per installare e abilitare `kiosk/hydra-umc-dsi.service`, una unit systemd che avvia l'app a schermo intero su `tty1` tramite [`cage`](https://github.com/cage-kiosk/cage) (un compositore kiosk Wayland minimale che esegue esattamente un client a schermo intero), con `Restart=always` così un crash rilancia l'app invece di lasciare lo schermo nero. Scelto rispetto a [`flutter-pi`](https://github.com/ardera/flutter-pi) (un embedder del motore Flutter di terze parti per Raspberry Pi, eseguito senza alcun window system) proprio perché riutilizza senza modifiche l'output reale di `flutter build linux` già prodotto da `build_linux.sh` - flutter-pi invece compila direttamente contro il motore Flutter, quindi richiederebbe un proprio passaggio di build separato, non è un sostituto diretto. **Nota di onestà:** scritto e revisionato, ma mai eseguito realmente contro un CM5 reale o qualsiasi altra macchina Linux - stesso stato non verificato dello stesso `flutter build linux` (vedere `docs/ARCHITECTURE.md` sezione 7). Vedere il commento di intestazione di `kiosk/hydra-umc-dsi.service` per le assunzioni esatte (utente root del servizio, possesso di `tty1`) da verificare contro l'immagine Raspberry Pi OS effettivamente usata dal CM5.

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
│   │   └── robot_view_model.dart    # Unico ChangeNotifier ascoltato da ogni schermata
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
├── test/widget_test.dart
├── README.md                         # documento originale (inglese)
└── README_spa.md / README_ita.md / README_fra.md / README_deu.md  # traduzioni
```

## 🔗 Progetti Correlati

Questo progetto fa parte di un più ampio ecosistema robotico dello stesso autore (JuanenRac / Electro Hobby 3D). Vale la pena conoscerli, poiché una richiesta potrebbe in realtà riguardare uno di questi invece che questo repository:

**Piattaforma HYDRA-UMC** — la cella di micro-fabbrica multi-robot
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** — la scheda madre stessa: host Raspberry Pi CM5 + coprocessore real-time STM32H745 dual-core, che orchestra fino a 8 bracci robotici distribuiti via CAN-OTA/SPI-OTA. Hardware e firmware propri, GPL-3.0/CERN-OHL-S v2/CC BY-SA 4.0.
- **[HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — dashboard di controllo web per HYDRA-UMC: visualizzazione 3D multi-robot, registrazione di cinematica/traiettorie, flashing e test CAN-OTA per l'intera piattaforma. React + Vite + Three.js.
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** — app di controllo Android per HYDRA-UMC via Wi-Fi/Bluetooth. App reale e funzionante - set completo di funzionalità di controllo remoto, autenticazione JWT, archiviazione crittografata delle credenziali.
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — app di controllo iOS/iPadOS per HYDRA-UMC via Wi-Fi, realizzata in Flutter (multipiattaforma, verificabile su Windows senza un Mac; il packaging finale dell'`.ipa` richiede ancora Xcode). App reale e funzionante - stesso set di funzionalità dell'app Android.
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** — centro di comando desktop (Python/PySide6) per lo sciame: discovery di rete multi-controller, sincronizzazione bidirezionale live, vero visualizzatore 3D dei robot, workspace agganciabile in stile Photoshop. Reale e funzionante, non un placeholder.
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** — creatore/editor grafico URDF desktop (Python/PySide6) per il catalogo di modelli di questo progetto: recupera i file sorgente da GitHub o da una cartella locale, valida la fattibilità dei gradi di libertà, modifica colore/scala/cinematica con anteprima 3D live, e invia il risultato finale a un server STUDIO in esecuzione. Reale e funzionante, non un placeholder.
- **HYDRA-UMC-DSI** *(questo repository)* — interfaccia touch nativa in Flutter per il touchscreen DSI da 5"/7" di HYDRA-UMC (1280×720, stessa risoluzione in entrambe le dimensioni) sul Compute Module 5, che controlla questo stesso server direttamente dalla scheda. Scaffold reale e funzionante con tutte le 6 schermate del catalogo collegate al server live; build reale del target Linux non ancora eseguita su hardware reale (ambiente di lavoro solo Windows - vedere la sezione "Compilazione" del README).

**Piattaforma URTC** — il controller della testa utensile montato su ogni braccio robotico HYDRA-UMC
- **[URTC](https://github.com/JuanenRac/URTC)** — Universal Robot Tool Controller: controller della testa utensile su bus CAN basato su STM32F303, 25 profili utensile completamente implementati, aggiornamento firmware CAN-OTA.
- **[URTC Flasher](https://github.com/JuanenRac/URTC-FLASHER)** — strumento desktop di flashing CAN-OTA + chip completo SWD/JTAG per schede URTC (Windows/Linux).
- **[URTC Tester](https://github.com/JuanenRac/URTC-TESTER)** — strumento desktop di diagnostica live su bus CAN per schede URTC, un pannello per ogni profilo utensile (Windows/Linux).
- **[URTC Web Studio](https://github.com/JuanenRac/URTC-WEB-STUDIO)** — alternativa basata su browser ai 2 strumenti desktop sopra (Web Serial API + SLCAN), nessuna installazione locale necessaria.

---

## 👤 Autore

**JuanenRac** (Electro Hobby 3D)
📧 electrohobby3d@gmail.com
📺 youtube.com/@electrohobby3d

---

## 📜 Licenza

GNU General Public License v3.0 (GPL-3.0) per il codice sorgente - vedere [`LICENSE`](LICENSE).

La documentazione (questo README e le sue traduzioni - `README_spa.md`, `README_ita.md`, `README_fra.md`, `README_deu.md`) è disponibile sotto **Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)**. Testo completo su https://creativecommons.org/licenses/by-sa/4.0/.
