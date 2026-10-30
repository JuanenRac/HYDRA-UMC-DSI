<!-- =============================================================================
HYDRA-UMC-DSI - Native touch UI for the CM5 DSI screen
Copyright (C) JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
GPL-3.0-or-later - see LICENSE
============================================================================= -->

<p align="center">
  <img src="images/HYDRA_UMC_BANNER.svg" alt="HYDRA-UMC-DSI banner" width="100%">
</p>

# 🖥️ HYDRA-UMC-DSI

<p align="center"><a href="README.md">🇺🇸 English</a> | <a href="README_spa.md">🇪🇸 Español</a> | <a href="README_fra.md">🇫🇷 Français</a> | 🇮🇹 <b>Italiano</b> | <a href="README_deu.md">🇩🇪 Deutsch</a> | <a href="README_zho.md">🇨🇳 简体中文</a> | <a href="README_jpn.md">🇯🇵 日本語</a> | <a href="README_por.md">🇵🇹 Português</a></p>

### Un'interfaccia touch nativa per lo schermo DSI del Compute Module 5

<p align="center">
  <img src="https://img.shields.io/badge/License-GPL%208.0--or--later-blue.svg" alt="GPL 3.0 or later">
  <img src="https://img.shields.io/badge/Framework-Flutter%208.x-02569B.svg" alt="Framework">
  <img src="https://img.shields.io/badge/Language-Dart-0175C2.svg" alt="Language">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20CM5-E34F26.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Tests-208%20passing-2ea44f.svg" alt="Tests">
  <img src="https://img.shields.io/badge/Version-0.2.7-0f6cbd.svg" alt="Version">
  <img src="https://img.shields.io/badge/Maturity-functional-0F6CBD.svg" alt="Maturity">
</p>

---

Un'interfaccia touch nativa in Flutter (Dart, con target reale desktop Linux) per il touchscreen DSI da 5"/7" di HYDRA-UMC sul Compute Module 5 - le due dimensioni fisiche del pannello condividono esattamente la stessa risoluzione di 1280x720 pixel, quindi questa app usa un unico layout fisso, non responsive, invece di adattarsi a due dimensioni. Parla esattamente lo stesso contratto [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-SERVER/blob/main/docs/REMOTE_API.md) usato da [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE), [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) e [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) - discovery, login, comandi atomici per robot e sincronizzazione live via WebSocket con un server [HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER) in esecuzione, avviata direttamente sulla scheda stessa invece che in una scheda del browser. Vedere [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) per il design completo, incluso il motivo della scelta di Flutter (e non Kivy) e perché la schermata 3D non usa una WebView.

**Questa app è una delle due modalità di controllo che coesistono sulla stessa scheda** - il CM5 gestisce anche un'uscita HDMI per un monitor esterno completo che esegue l'interfaccia web. Questa app DSI integra quel percorso con una console touch diretta e sempre disponibile sulla scheda stessa; non sostituisce l'interfaccia web.

---

**Controllo di onestà - cosa funziona davvero oggi:** il layer di rete (`lib/network/hydra_api_client.dart`, `hydra_websocket.dart`, `discovery.dart`, `auth_prefs.dart`) e il layer di stato (`lib/state/robot_view_model.dart`, `hydra_error.dart`) sono reali e testati (208 test superati in `test/*.dart`, incluso un vero round-trip di connessione/riconnessione/rifiuto di autenticazione WebSocket contro un vero server locale, non un mock), e `flutter analyze` non segnala alcun problema. Tutte e 6 le schermate del catalogo sono UI reale e cablata, non placeholder. Ciò che non è realmente costruito: la schermata **3D View** è un piccolo indicatore isometrico nativo X/Y/Z, non un vero motore di rendering 3D - non incorpora la scena Three.js di STUDIO (non esiste alcuna implementazione Linux di `webview_flutter`). Ciò che è reale ma non verificato sull'hardware di destinazione: `flutter build linux --release` è stato eseguito e produce un binario confermato all'avvio, ma solo sotto Ubuntu 24.04 WSL2 (x86_64) - mai sul vero aarch64 Raspberry Pi OS della CM5 - e l'unità di autoavvio `kiosk/hydra-umc-dsi.service` non è mai stata eseguita su nessuna vera macchina Linux. Vedi "Known Follow-ups" più sotto e `CHANGELOG.md` per ciò che è stato consegnato esattamente finora.

> **Stato di sicurezza (safety e security):** questo ecosistema non è un sistema di sicurezza certificato. Non esiste ancora un percorso E-STOP hardware, né limiti o interblocchi imposti dal firmware, né un comando di movimento verificato; le immagini firmware sono controllate con CRC-32 e una firma Ed25519, e una compilazione di rilascio rifiuta le chiavi di sviluppo pubblicate (le teste utensile e le schede di espansione dietro il relè usano ancora i bootloader di URTC, che accettano un HMAC-SHA256 a chiave condivisa invece di una firma); TLS e TLS reciproco sono opzionali e disattivati per impostazione predefinita; nessuna scheda propria è stata ancora assemblata o provata. Leggi la [base di sicurezza](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/SECURITY_BASELINE.md) e il [modello delle minacce](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/THREAT_MODEL.md) prima di fidarti di qualsiasi affermazione qui per la sicurezza di una persona.

---

## 📋 In breve

| | |
|---|---|
| Versione | `0.2.7` |
| Maturità | Funzionale |
| Test | 208 (`flutter test`) |
| Tecnologia | Flutter 3.x / Dart |
| Destinazione | Il Raspberry Pi CM5 di una cella HYDRA-UMC |
| Su hardware reale | Non ancora: per questa versione non risulta alcuna esecuzione su hardware reale |

**Vai a:** [Panoramica](#-panoramica) · [Architettura](#-architettura) · [Avvio rapido](#-avvio-rapido) · [Test](#-test) · [Struttura del repository](#-struttura-del-repository) · [Progetti correlati](#-progetti-correlati)

## 🚦 Stato del progetto

Ogni riga è una parte di questo repository e il semaforo dice a che punto è oggi. È scritta in base a ciò che il repository può mostrare (test, compilazioni, esecuzioni), non a ciò che è previsto.

🟢 Fatto e verificato · 🟡 Funziona, con limiti noti · 🟠 Fatto a metà o non ancora verificato · 🔴 Non fatto o non funzionante

| Area | Stato | Cosa significa qui |
|---|---|---|
| Software | 🟡 | Funziona per il suo scopo principale; la verifica di onestà qui sopra elenca ciò che manca ancora |
| Test | 🟢 | 208 test automatici, eseguiti a ogni modifica |
| Hardware reale | 🔴 | Non ancora: per questa versione non risulta alcuna esecuzione su hardware reale |
| Documentazione | 🟢 | README in otto lingue, verificato rispetto al manifesto a ogni modifica |

## 🎯 Panoramica

- **Login** (`lib/ui/login_screen.dart`, `lib/state/robot_view_model.dart`) - campi IP/porta del server precompilati con un valore LAN ragionevole, campi nome utente/password dimensionati per il tocco e vuoti per impostazione predefinita (nessuna credenziale precompilata - il precompilamento iniziale `admin`/`admin` è stato rimosso quando ogni server ha smesso di creare quell'account predefinito al primo avvio reale di produzione), `POST /api/login` verso l'account inserito dall'operatore; è possibile creare account aggiuntivi a privilegio minore "operator" da Config > Users nell'interfaccia web. Il token di sessione è conservato nell'archivio sicuro della piattaforma (libsecret su Linux, che richiede un servizio di portachiavi attivo: su un pannello che non lo ha la sessione dura fino al riavvio dell'app e il login viene richiesto di nuovo). Una finestra di dialogo "Scan local network" (`lib/network/discovery.dart`) trova i server senza dover già conoscere l'IP - doppiamente utile qui, dato che il CM5 su cui gira questa app è spesso proprio il controller a cui deve connettersi.
- **Discovery di rete** (`lib/network/discovery.dart`) - due percorsi in parallelo dalla stessa finestra "Scan local network": mDNS/Bonjour reale (`discoverMdns()`, interrogando il servizio `_hydra._tcp` pubblicato da `server.ts` tramite il pacchetto `multicast_dns`) e una scansione concorrente a forza bruta di `GET /api/hydra-info` sulle sottoreti locali reali di questo dispositivo (`scanSubnets()`), deduplicata per host:porta - portato da HYDRA-UMC-IOS-CONTROL, il primo client dell'ecosistema ad aggiungere mDNS reale.
- **Sincronizzazione atomica dei comandi** (`lib/state/robot_view_model.dart`, il proprio `_sendAtomicCommand()`) - ogni scrittura (play/pause/stop/jog/valve/pump/speed/vision) usa il reale endpoint `POST /api/robot/:id/command`, con la corretta propagazione ai robot combinati (`combinedWith`) e un rollback allo stato precedente se la richiesta fallisce - particolarmente importante per un pendant di jog/E-STOP posizionato a pochi metri dai robot reali.
- **Sincronizzazione live via WebSocket** (`lib/network/hydra_websocket.dart`) - invia il token come sottoprotocollo `hydra.bearer` e mai nell'indirizzo, gestisce sia i tipi di broadcast `"settings"` che `"delta"`, si riconnette automaticamente in caso di caduta.
- **Navigazione touch orizzontale** (`lib/ui/main_screen.dart`) - una barra superiore persistente con 6 grandi schede icona+etichetta (Dashboard/Control/Camera/Vista 3D/Metriche/Impostazioni) lungo tutta la larghezza fissa di 1280px, nello spirito di KlipperScreen invece di una barra di navigazione inferiore in stile telefono - seguendo il catalogo richiesto dal proprietario del progetto, riorganizzato per un pannello touch largo invece di un layout verticale da telefono.
- **Dashboard** (`lib/ui/dashboard_screen.dart`) - schede per robot, reattive in tempo reale tramite `Provider`, convenzione dei LED (verde lampeggiante = attivo, rosso fisso = inattivo), visualizzazione dei robot combinati e chip dei moduli (CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK) - lo stesso linguaggio visivo di tutti gli altri client di questo ecosistema.
- **Controllo Manuale** (`lib/ui/control_screen.dart`, `lib/ui/widgets/joystick_pad.dart`) - layout affiancato (pad di jog a sinistra, telemetria/velocità/IO a destra) dimensionato per il frame 1280x720 invece di un'unica colonna scorrevole, lo **STOP** globale (`lib/ui/widgets/stop_all.dart`) nella barra superiore di ogni scheda, anche in quella di Controllo e nell'overlay di pulizia dello schermo: un solo tocco, senza pressione prolungata né conferma, ferma tutti i robot (`POST /api/stop-all`), mostra il risultato robot per robot (avviso se un robot è fallito o l'arresto non è stato salvato, robot riservati da un altro account segnalati), ritenta una volta dopo un errore di rete, ripiega sull'arresto per robot con un 429 o un server più vecchio e mantiene un avviso permanente «STOP non confermato» finché uno STOP successivo non riceve risposta (il pulsante rotondo di arresto per robot mantiene la sua protezione a pressione prolungata), cursori di velocità/accelerazione, interruttori di valvole/pompe.
- **Prenotazioni e limiti di sicurezza** (`lib/ui/widgets/access_panel.dart`, `lib/models/access.dart`, `lib/network/hydra_api_client.dart`, `lib/state/robot_view_model.dart`) - La schermata Control mostra chi tiene il robot selezionato (nessuno, questo dispositivo, lo stesso account su un altro dispositivo o un altro account) e offre **Prenota** e **Rilascia**, oltre all’elenco di tutte le prenotazioni del server (`GET /api/claims`). Il dispositivo conserva un identificativo di controller per installazione e lo invia con ogni prenotazione, rilascio, armamento del jog e comando (corpo e intestazione `X-Controller-Id`): la prenotazione appartiene quindi all’account e a questo dispositivo, non a tutto l’account. I rifiuti del server sono distinti: prenotato da un altro account, dal tuo account su un altro dispositivo o finestra, identificativo di controller richiesto e jog non armato. I limiti del modello del robot si leggono da `GET /api/safety-limits`: un passo di jog oltre il limite non viene inviato e gli avvisi del server sono mostrati. Quando l’amministratore lo richiede, bisogna premere **Arma il jog** (con conto alla rovescia) prima che il joystick muova il robot; l’armamento termina da solo, con STOP o al rilascio. Le prenotazioni sono facoltative: un robot che nessuno ha prenotato si comanda come prima. Solo per un **amministratore** compare un pulsante **Prendi il controllo** su un robot detenuto da un altro; chiede conferma e poi prenota il robot con `force: true` (il server lo accetta solo dagli amministratori e ricontrolla il ruolo). Le scritture sono condizionali: ognuna porta la revisione del robot che questa app ha visto per ultima (`If-Match`, `lib/models/contract_v2.dart`); se nel frattempo qualcun altro ha modificato il robot, il server risponde 412, non viene applicato nulla, il robot viene riletto e il messaggio lo dice (Standard verifica prenotazioni, tavola e comandi singoli; Rigoroso verifica tutto tranne STOP; Disattivato non verifica nulla; la scelta è nell'elenco delle prenotazioni; STOP non è mai verificato). Il jog della tavola XY è un unico comando atomico `table` (un server più vecchio riceve i jog che capisce), il server invia le prenotazioni sul WebSocket così la schermata Control smette di interrogare mentre arrivano, e gli amministratori leggono il registro di audit (`lib/ui/widgets/audit_dialog.dart`) con la catena SHA-256 verificata due volte, dal server e sul computer, e possono copiarne le righe come `.jsonl`.
- **Chiedere prima di PLAY** - attivo per impostazione predefinita, si disattiva nelle Impostazioni: prima di avviare una traiettoria l'app mostra il robot, i suoi punti registrati, la velocità e chi lo ha prenotato (un robot prenotato da un altro segnala che il server rifiuterà il comando). Un robot già in riproduzione non viene richiesto di nuovo. La scelta viene conservata.
- **Camera** (`lib/ui/camera_screen.dart`, `lib/ui/widgets/mjpeg_view.dart`) - lo stesso parser MJPEG scritto a mano e senza dipendenze usato da HYDRA-UMC-IOS-CONTROL (nessuna WebView, nessun codice specifico della piattaforma - funziona su desktop Linux senza modifiche), uno stato chiaro di "Camera Disabilitata" e un interruttore per attivare/disattivare la visione di un robot direttamente dal server.
- **Vista 3D** (`lib/ui/three_d_screen.dart`) - **non** è una WebView che incorpora la vera scena Three.js di STUDIO, a differenza delle app iOS/Android - `webview_flutter` non ha alcuna implementazione per desktop Linux, e un motore browser completo rappresenta un carico di runtime maggiore di quanto serva a questo pannello embedded a basso consumo. Al suo posto: un piccolo indicatore isometrico nativo di posizione X/Y/Z (`CustomPainter`, nessun motore 3D), con una nota a schermo che rimanda alla vera scena 3D sul monitor collegato via HDMI a questa stessa scheda. Vedere la sezione 4 di `docs/ARCHITECTURE.md` per il ragionamento completo.
- **Metriche di Sistema** (`lib/ui/metrics_screen.dart`) - una scheda dedicata (non integrata nella Dashboard come fanno iOS/Android) con riquadri di CPU/memoria/temperatura/uptime da `GET /api/system/metrics`, più hostname/numero di controller/numero di robot/versione app da `GET /api/hydra-info`.
- **Impostazioni** (`lib/ui/settings_screen.dart`) - informazioni di connessione, identità del server, logout e la versione stessa di questa app (vedere [Versionamento](#-versionamento) più sotto).
- **Avvio automatico kiosk** (`kiosk/hydra-umc-dsi.service`, `kiosk/install_kiosk.sh`) - unit systemd che avvia l'app a schermo intero su `tty1` tramite `cage`, con `Restart=always`. Vedere "Esecuzione sul CM5 reale" più sotto.
- **UI in 8 lingue** (`lib/l10n/`, pipeline standard `flutter gen-l10n`) - inglese, spagnolo, francese, tedesco, italiano, giapponese, cinese e portoghese, come il resto dei client di questo ecosistema. Un'impostazione persistente in `Impostazioni > Lingua` usa come predefinita la lingua di sistema; `RobotViewModel.lastError` è un `HydraError` tipizzato invece di testo inglese già formattato, quindi anche i messaggi di errore della logica di business vengono tradotti correttamente, non solo il testo statico delle schermate.

**Stato: scaffold + tutte le 6 schermate del catalogo implementate e collegate al contratto reale REMOTE_API.md.** `flutter analyze` pulito, sia `flutter build windows` che `flutter build linux` (via WSL2) producono un binario funzionante, `flutter test` passa - vedere "Compilazione" più sotto per cosa è stato verificato e cosa no, incluso il divario rimasto tra questa verifica su WSL2 e il vero hardware della CM5.

**Sicurezza della connessione:** il pannello si connette prima in HTTPS. L'HTTP in chiaro è usato solo verso questa stessa macchina (predefinito `127.0.0.1`) o, se consentito nella finestra Sicurezza dell'accesso e delle Impostazioni, verso un server della rete locale (fuori da essa solo se anche questo è consentito). Un server con certificato autofirmato è considerato attendibile tramite l'impronta SHA-256 letta da esso e confermata lì, o tramite una CA fornita.

## 🧩 Ruolo in HYDRA-UMC

**HYDRA-UMC-DSI** è il touchscreen della CM5 stessa: un'app Flutter nativa per il pannello DSI da 5"/7" che parla con `HYDRA-UMC-SERVER` tramite la sua interfaccia REST e WebSocket, accanto all'interfaccia browser di `HYDRA-UMC-STUDIO`. Non ha logica robotica propria; è il server a decidere cosa è consentito.

## 🏛️ Architettura

<p align="center">
  <img src="images/architecture.svg" alt="HYDRA-UMC-DSI architecture" width="100%">
</p>

## 🚀 Avvio rapido

Richiede l'SDK Flutter stabile (3.x) con supporto desktop Linux.

```bash
flutter pub get
./run_dev.sh      # desktop simulation, no hardware (run_dev.bat on Windows)
./build_linux.sh  # on a Linux machine or the CM5: the real target
```

## 🧪 Test

208 test automatici si eseguono con `flutter test`. Non richiedono hardware né nulla al di fuori di questa macchina.

La CI esegue `HYDRA_UMC_CI=1 python tools/ci_validate.py`, che controlla il manifesto, i documenti, gli otto README e le immagini.

## 🏗️ Compilazione e rilascio

Richiede il [Flutter SDK](https://docs.flutter.dev/get-started/install) (canale stable). Questo repository viene compilato/verificato con Flutter 3.47.0. Solo `linux/` e `windows/` sono configurate come piattaforme in questo repository (nessuna cartella `android/`, `ios/`, `web/` o `macos/`) - Linux è il target reale (il sistema operativo del CM5 stesso); Windows esiste unicamente per poter compilare, eseguire e testare la logica di questa app su una macchina priva di toolchain Linux.

### Script di compilazione

```bash
./build.sh          # Git Bash / WSL, oppure build.bat per cmd/PowerShell - flutter pub get + flutter build windows (verifica sulla macchina di sviluppo)
./build_linux.sh    # Deve essere eseguito SU una macchina Linux reale (o sul CM5 stesso) - flutter pub get + flutter build linux (il vero target di deployment)
./run_dev.sh         # Git Bash / WSL, oppure run_dev.bat per cmd/PowerShell - modalità simulazione desktop (flutter run), senza bisogno dell'hardware
```

Tutti e 3 gli script di compilazione (`build.sh`/`build.bat`/`build_linux.sh`) non cambiano la versione dell'app - vedere [Versionamento](#-versionamento) più sotto. `run_dev.sh`/`run_dev.bat` non lo fanno - un `flutter run` da ciclo di sviluppo non è una "compilazione reale" secondo questa policy.

### Compilazione manuale

```bash
flutter pub get
flutter analyze                  # analisi statica - non serve un compilatore
flutter test                     # test dei widget
python tools/hydra_project_tool.py bump  # incrementa la versione (una build non lo fa mai)
flutter build windows            # smoke test sulla macchina di sviluppo - produce build/windows/x64/runner/Release/hydra_umc_dsi.exe
flutter build linux              # il target REALE - deve essere eseguito su una macchina Linux reale, produce build/linux/*/release/bundle/
flutter run -d windows           # oppure -d linux su una macchina Linux reale, per un ciclo di sviluppo live in simulazione desktop
```

**Nota di onestà sulla verifica Linux:** `flutter build linux --release` è stato ora effettivamente eseguito su questo codice, da un vero ambiente Ubuntu 24.04 su WSL2 con una vera toolchain desktop Linux (`cmake`, `ninja-build`, `libgtk-3-dev`, `clang`) - compila pulito e produce un vero `build/linux/x64/release/bundle/hydra_umc_dsi`, confermato come effettivamente avviabile (è stato eseguito sotto un vero display X11 ed è rimasto attivo, non solo un codice di uscita 0), non solo `flutter build windows` come sostituto di smoke test. Cosa **non** copre questo: lo userspace di WSL2 è x86_64, non il vero aarch64 del Raspberry Pi OS della CM5, e il flusso di autoavvio di `kiosk/hydra-umc-dsi.service` non è comunque mai stato eseguito su una vera macchina Linux. Vedere la sezione 7 di `docs/ARCHITECTURE.md` per l'elenco esatto di ciò che è stato e non è stato verificato, e "Prossimi Passi Noti" più sotto per ciò che resta da fare.

## 📂 Struttura del repository

<p align="center">
  <img src="images/repository-structure.svg" alt="Repository structure of HYDRA-UMC-DSI" width="100%">
</p>

<details>
<summary>Versione testuale dell'albero</summary>

```text
HYDRA-UMC-DSI/
├── lib/                                                              codice sorgente
│   ├── main.dart                                                     Entry point dell'app, ChangeNotifierProvider + gate di login, tema scuro fisso
│   ├── app_version.dart                                              GENERATO - rigenerato da bump_manifest_version.py, non modificare a mano
│   ├── models/                                                       modelli di dati e regole pure
│   ├── network/                                                      client REST, WebSocket e individuazione
│   ├── state/                                                        lo stato che ogni schermata ascolta
│   ├── services/                                                     servizi dell'app (retroilluminazione)
│   ├── l10n/                                                         localizzazioni in otto lingue
│   ├── util/                                                         Utilità senza schermata propria
│   └── ui/                                                           schermate e widget
├── kiosk/                                                            unità kiosk e il suo installatore
├── linux/                                                            Runner desktop GTK - il target REALE, finestra fissa 1280x720
├── windows/                                                          Runner desktop Windows - solo verifica sulla macchina di sviluppo
├── tools/                                                            strumenti del progetto e controlli della CI
├── test/                                                             widget_test, format_uptime_test, localization_test, robot_view_model_test, robot_view_model_silent_refresh_test, auth_prefs_test, hydra_websocket_test, hostile_answers_test, hydra_error_test, play_confirmation_test, stop_long_press_test
├── .github/                                                          workflow di CI e modelli di segnalazione
├── images/                                                           banner e immagini del README
├── build.bat / build.sh                                              flutter pub get + incremento versione + flutter build windows (verifica sulla macchina di sviluppo)
├── build_linux.sh                                                    flutter pub get + flutter build linux (il vero target CM5 - eseguire su Linux reale)
├── run_dev.bat / run_dev.sh                                          flutter run - modalità simulazione desktop
├── CHANGELOG.md                                                      storico delle versioni (vedere Versionamento più sopra)
├── docs/ARCHITECTURE.md                                              architettura del progetto
├── bump_manifest_version.py                                          Sincronizza la versione di hydra-umc.project.json con quella nativa (--sync)
├── pubspec.yaml / pubspec.lock / l10n.yaml / analysis_options.yaml   La definizione del pacchetto Flutter e le sue versioni bloccate, le impostazioni del generatore l10n e le regole di lint
├── build-test.sh                                                     controllo di build senza modifiche
├── hydra-umc.project.json                                            manifesto: versione, maturità, famiglia
└── test.sh                                                           esegue i test
```

</details>

## 🗺️ Roadmap e limiti noti

**Limiti noti oggi**

Lacune reali e verificate che il codice di questa app ha ancora - non TODO vaghi, ognuna riconducibile a un punto preciso del codice o della documentazione sopra:

- **L'interruttore di accesso remoto non è ancora indipendente** - la sezione 1 di `REMOTE_API.md` riconosce solo `suite`, `android` e `ios` come valori di `X-Hydra-Client`; questa app invia `dsi`, un valore non riconosciuto che oggi non viene mai filtrato, quindi le sue richieste di discovery passano senza alcun controllo. Risolverlo richiede di aggiungere un 4° interruttore al tipo `SystemSettings.remoteAccess` di HYDRA-UMC-STUDIO e alla sua scheda Config > Remote Access - una modifica al codice server di un altro repository, fuori dall'ambito di questo. Vedere la sezione 3 di `docs/ARCHITECTURE.md`.
- **La vista 3D non ha un vero renderer 3D nativo** - `ui/three_d_screen.dart` disegna oggi un piccolo indicatore isometrico di posizione X/Y/Z invece di incorporare la vera scena Three.js di STUDIO (`webview_flutter` non ha alcuna implementazione Linux - vedere la sezione 4 di `docs/ARCHITECTURE.md` per il ragionamento completo). Un vero renderer 3D nativo per questa schermata è lavoro futuro, non ancora iniziato.
- **Manca ancora un'esecuzione reale sull'hardware della CM5** - `flutter build linux` in sé è ora verificato (vera toolchain Ubuntu 24.04 su WSL2, binario confermato come effettivamente avviabile - vedere la sezione 7 di `docs/ARCHITECTURE.md`), ma il flusso completo di `build_linux.sh` e l'unità di avvio automatico `kiosk/hydra-umc-dsi.service` non sono comunque mai stati eseguiti contro il CM5 stesso o qualsiasi altra vera macchina Linux (non-WSL2). Chi li esegue lì per la prima volta dovrebbe considerarlo come il vero primo deploy hardware di questa piattaforma, non una formalità - vedere "Esecuzione sul CM5 reale" più sopra.

## 🌍 Lingue

Questo README e i documenti del repository esistono in otto lingue: inglese, spagnolo, tedesco, francese, italiano, giapponese, cinese e portoghese (Portogallo). Sono scritti insieme e la CI verifica che gli otto file abbiano le stesse sezioni e gli stessi link.

## 🔗 Progetti correlati

Questo progetto fa parte dell'ecosistema robotico HYDRA-UMC dello stesso autore (JuanenRac / Electro Hobby 3D). Vale la pena conoscerlo, poiché una richiesta potrebbe in realtà riguardare uno di questi invece di questo repository.

**Progetto Padre**
- **[HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)** — il vero backend headless (REST/WebSocket) con cui parla davvero ogni client di controllo; il server a cui si connette questo pannello tramite il vero contratto `REMOTE_API.md` (scoperta, login, comandi atomici, sincronizzazione WebSocket).

**Progetti Fratelli** — parlano anch'essi con la stessa API di HYDRA-UMC-SERVER, ciascuno come proprio client
- **[HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — dashboard di controllo web con visualizzazione 3D multi-robot in tempo reale.
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** — centro di comando sciame desktop (PySide6) per più server contemporaneamente, pacchettizzato come eseguibile standalone; parla esattamente lo stesso contratto `REMOTE_API.md` di questo pannello.
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** — app di controllo nativa per Android con login biometrico e un companion Wear OS abbinato; parla esattamente lo stesso contratto `REMOTE_API.md` di questo pannello.
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — app di controllo per iOS/iPadOS (Flutter) con sincronizzazione WebSocket in tempo reale; parla esattamente lo stesso contratto `REMOTE_API.md` di questo pannello, ed è da cui è stata portata la vera scoperta mDNS propria di questo pannello.
- **[HYDRA-UMC-BRIDGE-AMR](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-AMR)** — barriera di coordinamento per flotte AGV/AMR tramite un publisher MQTT VDA 5050 (testato solo contro una flotta emulata).
- **[HYDRA-UMC-BRIDGE-CNC](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-CNC)** — coordinatore ad alto livello per celle CNC con accesso a stato/byte di controllo GRBL (testato solo contro un emulatore).
- **[HYDRA-UMC-BRIDGE-DROIDS](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-DROIDS)** — barriera di coordinamento per droidi con zampe/umanoidi, con un mittente di comandi per Boston Dynamics Spot (testato solo contro un emulatore).
- **[HYDRA-UMC-BRIDGE-LASER](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-LASER)** — coordinatore per celle laser che legge 3 segnali GPIO di chiave/involucro/interblocco (testato solo contro un chip simulato; non può armare né far partire un laser).
- **[HYDRA-UMC-BRIDGE-OPENPNP](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-OPENPNP)** — coordinatore ad alto livello sicuro per il flusso schede del pick-and-place OpenPnP.
- **[HYDRA-UMC-BRIDGE-PRINTER3D](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-PRINTER3D)** — barriera di coordinamento sicura per stampanti 3D Moonraker/Klipper, con comandi di lavoro reali e controllati.
- **[HYDRA-UMC-BRIDGE-ROS2](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-ROS2)** — coordinatore con un trasporto ROS 2 rclpy importato in modo lazy (non ancora eseguito contro un'installazione ROS 2).
- **[HYDRA-UMC-BRIDGE-UAV](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-UAV)** — barriera di coordinamento per UAV dotati di fotocamera, con un mittente di comandi MAVLink (testato solo contro un emulatore).

**Direttamente Correlati**
- **[HYDRA-UMC-WATCH](https://github.com/JuanenRac/HYDRA-UMC-WATCH)** — app companion WearOS con schemi di avviso aptico e un relay vocale verso il telefono abbinato (non ancora eseguita su un orologio fisico); il dispositivo di allarme di sicurezza indossabile che completa questo pannello touch, portando gli avvisi al polso dell'operatore oltre allo schermo della scheda.
- **[HYDRA-UMC-COGNITIVE-NODE](https://github.com/JuanenRac/HYDRA-UMC-COGNITIVE-NODE)** — hub di integrazione per la pipeline cognitiva Hailo-10 (orchestrazione LLM/VLA/voce); aggiunge il controllo vocale direttamente su questo pannello touch.
- **[HYDRA-UMC-VOICE-UI](https://github.com/JuanenRac/HYDRA-UMC-VOICE-UI)** — vero front-end vocale (VAD + parser di intenti) con un relay verso Watch limitato e soggetto a conferma; aggiunge il controllo vocale direttamente su questo pannello touch.
- **[HYDRA-UMC-LOCAL-TECHNICIAN](https://github.com/JuanenRac/HYDRA-UMC-LOCAL-TECHNICIAN)** — tecnico di manutenzione IA locale e con cancelli di policy per l'ecosistema stesso - osserva, diagnostica e propone correzioni; i due livelli di rischio più alti non sono deliberatamente ancora implementati.

**Fa Anche Parte dell'Ecosistema**

*Hardware e Piattaforma di Base*
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** — il progetto della scheda madre del braccio robotico: host CM5 + coprocessore STM32H745 dual-core, pensato per coordinare fino a 8 bracci utensile via CAN-OTA/SPI-OTA (firmware in fase iniziale; nessuna scheda assemblata per ora).
- **[HYDRA-UMC-OS](https://github.com/JuanenRac/HYDRA-UMC-OS)** — livello prodotto riproducibile su Raspberry Pi OS per il CM5: agente in sola lettura, config/profili validati, provisioning WiFi al primo contatto.
- **[HYDRA-UMC-SDK](https://github.com/JuanenRac/HYDRA-UMC-SDK)** — il contratto JSON-Schema condiviso e la barriera software di controllo dei job contro cui ogni bridge valida i propri comandi (non è una funzione di sicurezza certificata).
- **[HYDRA-UMC-CONNECTOR-HUB](https://github.com/JuanenRac/HYDRA-UMC-CONNECTOR-HUB)** — registro dichiarativo e validatore di manifesti adattatore per connettori di macchine esterne; estende la propria idea di contratto dell'SDK alle macchine esterne senza sostituire i progetti di gateway industriale.

*Backend Centrale e Client*
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** — creatore/editor grafico desktop di URDF che invia i modelli finiti al catalogo di STUDIO.
- **[HYDRA-UMC-EDITOR-STL](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-STL)** — editor desktop di modelli STL, che trasforma/sostituisce/rimuove/aggiunge veri pezzi nello stesso catalogo di modelli modificato anche da HYDRA-UMC-EDITOR-URDF.

*Piattaforma Strumenti URTC*
- **[URTC](https://github.com/JuanenRac/URTC)** — firmware per la scheda fisica dell'Universal Robot Tool Controller, oltre 25 profili utensile su bus CAN.
- **[URTC-FLASHER](https://github.com/JuanenRac/URTC-FLASHER)** — strumento desktop con GUI per il flashing delle schede URTC, CAN-OTA più SWD/JTAG a chip intero.
- **[URTC-TESTER](https://github.com/JuanenRac/URTC-TESTER)** — strumento desktop di diagnostica CAN-bus dal vivo per schede URTC, un pannello per profilo utensile.
- **[URTC-WEB-STUDIO](https://github.com/JuanenRac/URTC-WEB-STUDIO)** — alternativa basata su browser a URTC-TESTER tramite la Web Serial API, senza installazione locale.
- **[URTC-GATEWAY](https://github.com/JuanenRac/URTC-GATEWAY)** — gateway davanti al bus CAN di URTC: elenco di identificatori consentiti, limite di frequenza e chiave di sessione; software provato su computer, non ancora su un bus reale.

*Nodo IA Visione (Hailo-8)*
- **[HYDRA-UMC-VISION-NODE](https://github.com/JuanenRac/HYDRA-UMC-VISION-NODE)** — hub di integrazione per la pipeline di visione Hailo-8, con un vero controllo di prontezza hardware per fase.
- **[HYDRA-UMC-DETECTION-HEF](https://github.com/JuanenRac/HYDRA-UMC-DETECTION-HEF)** — registro reale di modelli compilati con verifica di caricamento sicuro per architettura Hailo/checksum.
- **[HYDRA-UMC-VISION-STREAMER](https://github.com/JuanenRac/HYDRA-UMC-VISION-STREAMER)** — generatore reale di pipeline GStreamer + config MediaMTX, con una vera barriera di integrazione HailoRT.
- **[HYDRA-UMC-VISUAL-SERVOING-API](https://github.com/JuanenRac/HYDRA-UMC-VISUAL-SERVOING-API)** — legge di correzione Position-Based Visual Servoing con autorizzazione condizionata allo stato di zona; ancora nessuna stima di posa da telecamera.
- **[HYDRA-UMC-SAFETY-ZONES](https://github.com/JuanenRac/HYDRA-UMC-SAFETY-ZONES)** — logica v0 di violazione zona, freschezza di calibrazione e richiesta E-STOP che legge le posizioni degli oggetti da un file; nessun rilevatore la alimenta e nessun E-STOP fisico è ancora collegato.

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
- **[HYDRA-UMC-HIL-BRIDGE](https://github.com/JuanenRac/HYDRA-UMC-HIL-BRIDGE)** — router hardware-in-the-loop con un interblocco software di collisione tra simulazione e hardware reale (testato senza hardware reale).
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
- **[HYDRA-UMC-OPS-AGENT](https://github.com/JuanenRac/HYDRA-UMC-OPS-AGENT)** — coordinatore di incidenti di manutenzione: un ruolo edge a basso privilegio raccoglie uno snapshot di inventario/salute sanificato, un ruolo control-plane lo rende in sola lettura e chiede a un provider di IA di suggerire una diagnosi - non applica mai una patch né distribuisce nulla.
- **[HYDRA-UMC-DEV-SERVER](https://github.com/JuanenRac/HYDRA-UMC-DEV-SERVER)** — host di sviluppo riproducibile (Raspberry Pi 5 / CM5) che conserva il codice sorgente dell'ecosistema ed esegue attività delimitate di build/test tramite una coda durevole; un ruolo di sviluppo dedicato, esplicitamente distinto da un CM5 operativo.

## 📚 Documentazione

Dove leggere di più:

* [Base di sicurezza dell'ecosistema](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/SECURITY_BASELINE.md)
* [Modello delle minacce dell'ecosistema](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/THREAT_MODEL.md)
* [Registro delle modifiche di questo repository](CHANGELOG.md)
* [Licenza di questo repository](LICENSE.md)

## 🤝 Contribuire e comunità

* Prima di una pull request esegui `HYDRA_UMC_CI=1 py -3 tools/ci_validate.py` (oppure `HYDRA_UMC_CI=1 python3 tools/ci_validate.py`): deve stampare `CI_VALIDATION=PASS`. Non eseguire `build.sh` né `build.bat` per questa verifica; compilare non è verificare.
* I otto README sono scritti da un'unica fonte in HYDRA-UMC-DOCS; non modificarli a mano. Cambia la fonte e riscrivili con `tools/make_readmes.py`.
* Non affermare in un README ciò che non è stato eseguito: scrivi «simulato» o «non provato su hardware» quando è la verità.
* Vedi [CONTRIBUTING.md](CONTRIBUTING.md), il [codice di condotta](CODE_OF_CONDUCT.md), [SECURITY.md](SECURITY.md) e [SUPPORT.md](SUPPORT.md).

## 👤 AUTORE

**JuanenRac (Electro Hobby 3D)** · electrohobby3d@gmail.com

## 📜 LICENZA

GPL-3.0-or-later - [LICENSE](LICENSE).
