<p align="center">
  <img src="images/HYDRA_UMC_BANNER.svg" alt="HYDRA-UMC-DSI banner" width="100%">
</p>
# 🖥️ HYDRA-UMC DSI

<p align="center">
  <a href="README.md">🇺🇸 English</a> |
  <a href="README_spa.md">🇪🇸 Español</a> |
  🇫🇷 <b>Français</b> |
  <a href="README_ita.md">🇮🇹 Italiano</a> |
  <a href="README_deu.md">🇩🇪 Deutsch</a> |
  <a href="README_zho.md">🇨🇳 简体中文</a> |
  <a href="README_jpn.md">🇯🇵 日本語</a>
</p>


<p align="left">
  <img src="https://img.shields.io/badge/Licence-GPL%203.0-blue.svg" alt="GPL 3.0">
  <img src="https://img.shields.io/badge/Framework-Flutter%203.x-02569B.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Langage-Dart-0175C2.svg" alt="Dart">
  <img src="https://img.shields.io/badge/Plateforme-Linux%20%7C%20CM5-E34F26.svg" alt="Platform">
</p>


Une interface tactile native en Flutter (Dart, avec une vraie cible desktop Linux) pour l'écran tactile DSI 5"/7" propre à HYDRA-UMC sur le Compute Module 5 - les deux tailles physiques de l'écran partagent exactement la même résolution de 1280x720 pixels, donc cette application utilise une mise en page unique et fixe, non responsive, plutôt que de s'adapter à deux tailles. Elle parle exactement le même contrat [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-STUDIO/blob/main/docs/REMOTE_API.md) qu'utilisent [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE), [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) et [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) - découverte, connexion, commandes atomiques par robot et synchronisation en direct par WebSocket avec un serveur [HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO) en cours d'exécution, lancée directement sur la carte elle-même plutôt que dans un onglet de navigateur. Voir [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) pour la conception complète, y compris pourquoi Flutter (et non Kivy) et pourquoi l'écran 3D n'utilise pas de WebView.

**Cette application est l'une des deux voies de contrôle coexistant sur la même carte** - le CM5 pilote également une sortie HDMI pour un moniteur externe complet exécutant l'interface web. Cette application DSI complète cette voie avec une console tactile directe et toujours disponible sur la carte elle-même ; elle ne remplace pas l'interface web.

## 🏗️ Ce qui est implémenté

- **Connexion** (`lib/ui/login_screen.dart`, `lib/state/robot_view_model.dart`) - champs IP/port du serveur pré-remplis avec une valeur LAN raisonnable, champs nom d'utilisateur/mot de passe dimensionnés pour le tactile et laissés vides par défaut (aucun identifiant n'est pré-rempli - le pré-remplissage initial `admin`/`admin` a été supprimé lorsque chaque serveur a cessé de créer ce compte par défaut lors d'un premier démarrage de production réel), `POST /api/login` avec le compte saisi par l'opérateur ; des comptes supplémentaires à privilège réduit "operator" peuvent être créés depuis Config > Users dans l'interface web. Jeton de session persisté entre les lancements via `shared_preferences` - important sur un panneau de type kiosque censé rester connecté même après un cycle d'extinction/allumage du CM5 lui-même, pas seulement après une relance de l'application. Une boîte de dialogue "Scan local network" (`lib/network/discovery.dart`) trouve les serveurs sans avoir besoin de connaître déjà l'IP - doublement utile ici, puisque le CM5 sur lequel tourne cette application est souvent le contrôleur même auquel elle doit se connecter.
- **Découverte réseau** (`lib/network/discovery.dart`) - deux voies en parallèle depuis la même boîte de dialogue « Scan local network » : mDNS/Bonjour réel (`discoverMdns()`, interrogeant le service `_hydra._tcp` publié par `server.ts` via le paquet `multicast_dns`) et un balayage concurrent par force brute de `GET /api/hydra-info` sur les sous-réseaux locaux réels de cet appareil (`scanSubnets()`), dédupliqué par host:port - porté depuis HYDRA-UMC-IOS-CONTROL, le premier client de l'écosystème à ajouter du vrai mDNS.
- **Synchronisation atomique des commandes** (`lib/state/robot_view_model.dart`, son propre `_sendAtomicCommand()`) - chaque écriture (enable/disable/play/pause/stop/jog/valve/pump/speed/vision) utilise le vrai point de terminaison `POST /api/robot/:id/command`, avec la propagation correcte vers les robots combinés (`combinedWith`) et un retour à l'état précédent si la requête échoue - particulièrement important pour un pendentif de jog/E-STOP situé à quelques mètres des robots réels.
- **Synchronisation en direct par WebSocket** (`lib/network/hydra_websocket.dart`) - joint toujours `?token=`, gère les types de diffusion `"settings"` et `"delta"`, se reconnecte automatiquement en cas de coupure.
- **Navigation tactile horizontale** (`lib/ui/main_screen.dart`) - une barre supérieure persistante de 6 grands onglets icône+libellé (Dashboard/Control/Caméra/Vue 3D/Métriques/Réglages) sur toute la largeur fixe de 1280px, dans l'esprit de KlipperScreen plutôt qu'une barre de navigation inférieure façon téléphone - suivant le catalogue demandé par le propriétaire du projet, réorganisé pour un large panneau tactile plutôt qu'une mise en page verticale de téléphone.
- **Dashboard** (`lib/ui/dashboard_screen.dart`) - cartes par robot, réactives en temps réel via `Provider`, convention de LED (vert clignotant = actif, rouge fixe = inactif), affichage des robots combinés et puces de modules (CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK) - le même langage visuel que tous les autres clients de cet écosystème.
- **Contrôle Manuel** (`lib/ui/control_screen.dart`, `lib/ui/widgets/joystick_pad.dart`) - mise en page côte à côte (pavé de jog à gauche, télémétrie/vitesse/E-S à droite) dimensionnée pour le cadre 1280x720 plutôt qu'une colonne unique défilante, vraie protection par appui long sur E-STOP/STOP (un tap rapide ne fait rien de plus qu'une vibration + un indice visuel, seul un appui long réel envoie la commande), curseurs de vitesse/accélération, interrupteurs de vannes/pompes.
- **Caméra** (`lib/ui/camera_screen.dart`, `lib/ui/widgets/mjpeg_view.dart`) - le même analyseur MJPEG écrit à la main et sans dépendance qu'utilise HYDRA-UMC-IOS-CONTROL (pas de WebView, pas de code spécifique à la plateforme - fonctionne sur le bureau Linux sans modification), un état clair "Caméra Désactivée" et un interrupteur pour activer/désactiver la vision d'un robot directement depuis le serveur.
- **Vue 3D** (`lib/ui/three_d_screen.dart`) - **ce n'est pas** une WebView intégrant la vraie scène Three.js de STUDIO, contrairement aux applications iOS/Android - `webview_flutter` n'a aucune implémentation pour le bureau Linux, et un moteur de navigateur complet représente une charge d'exécution plus lourde que ce qu'il faut à ce panneau embarqué à faible consommation. À la place : un petit indicateur natif isométrique de position X/Y/Z (`CustomPainter`, sans moteur 3D), avec une note à l'écran renvoyant vers la vraie scène 3D sur le moniteur connecté en HDMI à cette même carte. Voir la section 4 de `docs/ARCHITECTURE.md` pour le raisonnement complet.
- **Métriques Système** (`lib/ui/metrics_screen.dart`) - son propre onglet dédié (pas intégré au Dashboard comme le font iOS/Android) avec des tuiles CPU/mémoire/température/temps de fonctionnement depuis `GET /api/system/metrics`, plus le nom d'hôte/nombre de contrôleurs/nombre de robots/version de l'application depuis `GET /api/hydra-info`.
- **Réglages** (`lib/ui/settings_screen.dart`) - informations de connexion, identité du serveur, déconnexion et la propre version de cette application (voir [Versionnement](#-versionnement) ci-dessous).
- **Démarrage automatique kiosque** (`kiosk/hydra-umc-dsi.service`, `kiosk/install_kiosk.sh`) - unité systemd lançant l'app en plein écran sur `tty1` via `cage`, avec `Restart=always`. Voir « Exécution sur le CM5 réel » ci-dessous.
- **Interface en 7 langues** (`lib/l10n/`, pipeline standard `flutter gen-l10n`) - anglais, espagnol, français, allemand, italien, japonais et chinois, comme le reste des clients de cet écosystème. Un réglage persistant dans `Réglages > Langue` utilise par défaut la langue du système ; `RobotViewModel.lastError` est un `HydraError` typé plutôt qu'un texte anglais déjà formaté, donc les messages d'erreur de la logique métier sont eux aussi correctement traduits, pas seulement le texte statique des écrans.

**État : scaffold + les 6 écrans du catalogue implémentés et connectés au vrai contrat REMOTE_API.md.** `flutter analyze` sans avertissement, `flutter build windows` produit un binaire fonctionnel, `flutter test` passe - voir « Compilation » ci-dessous pour ce qui a pu ou non être vérifié depuis cet environnement de travail Windows, puisque la vraie cible est Linux.

## 🚀 Compilation

Nécessite le [SDK Flutter](https://docs.flutter.dev/get-started/install) (canal stable). Ce dépôt est compilé/vérifié avec Flutter 3.47.0. Seuls `linux/` et `windows/` sont configurés comme plateformes dans ce dépôt (pas de dossiers `android/`, `ios/`, `web/` ni `macos/`) - Linux est la vraie cible (le système d'exploitation même du CM5) ; Windows existe uniquement pour pouvoir compiler, exécuter et tester la logique de cette application sur une machine sans chaîne d'outils Linux.

### Scripts de compilation

```bash
./build.sh          # Git Bash / WSL, ou build.bat pour cmd/PowerShell - flutter pub get + incrément de version + flutter build windows (vérification sur machine de développement)
./build_linux.sh    # Doit s'exécuter SUR une vraie machine Linux (ou le CM5 lui-même) - flutter pub get + incrément de version + flutter build linux (la vraie cible de déploiement)
./run_dev.sh         # Git Bash / WSL, ou run_dev.bat pour cmd/PowerShell - mode simulation bureau (flutter run), sans besoin du matériel
```

Les 3 scripts de compilation (`build.sh`/`build.bat`/`build_linux.sh`) incrémentent d'abord la version de l'application - voir [Versionnement](#-versionnement) ci-dessous. `run_dev.sh`/`run_dev.bat` ne le font pas - un `flutter run` de boucle de développement n'est pas une « vraie compilation » au sens de cette politique.

### Compilation manuelle

```bash
flutter pub get
flutter analyze                  # analyse statique - aucun compilateur nécessaire
flutter test                     # tests de widgets
dart run tool/bump_version.dart  # incrémente la version, comme le font build.sh/build.bat/build_linux.sh
flutter build windows            # test de fumée sur machine de développement - produit build/windows/x64/runner/Release/hydra_umc_dsi.exe
flutter build linux              # la cible RÉELLE - doit s'exécuter sur une vraie machine Linux, produit build/linux/*/release/bundle/
flutter run -d windows           # ou -d linux sur une vraie machine Linux, pour une boucle de développement en direct en simulation bureau
```

**Note d'honnêteté sur la vérification Linux :** ce dépôt a été rédigé sur une machine Windows sans aucune chaîne d'outils de compilation Linux disponible (confirmé via `wsl --status` - aucune distribution WSL installée). `flutter build linux` n'a jamais réellement été exécuté sur ce code depuis cet environnement de travail ; `flutter build windows` a été utilisé comme substitut de test de fumée, comme le permet explicitement la mission. Voir la section 7 de `docs/ARCHITECTURE.md` pour la liste exacte de ce qui a été vérifié ou non, et « Suites Connues » ci-dessous pour le suivi à faire.

## 🔢 Versionnement

Ce dépôt suit une politique à l'échelle de l'écosystème (partagée avec
[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL),
implémentée là-bas en parallèle) : la version s'incrémente
automatiquement à **chaque compilation réelle**, sans édition manuelle de
la ligne `version:` de `pubspec.yaml`. `build.sh`/`build.bat`/
`build_linux.sh` exécutent `tool/bump_version.dart` avant d'appeler
`flutter build`, en appliquant :

- **Patch, façon compteur kilométrique (base 10) :** +1 à chaque
  compilation ; si cela dépasserait 9, il revient à 0 et le minor
  s'incrémente de +1 à la place - exemple : `0.0.9` -> `0.1.0`. Le major
  n'est jamais modifié automatiquement.
- **Numéro de build** (la partie après le `+`) : un simple compteur
  monotone, +1 à chaque compilation, sans report.

Le même script régénère `lib/app_version.dart` (généré, non modifié à la
main - un simple fichier `const`, pas une nouvelle dépendance à
l'exécution comme `package_info_plus`), que l'application lit à
l'exécution pour afficher sa propre version sur l'écran **Réglages**.
Voir [CHANGELOG.md](CHANGELOG.md) pour l'historique des versions.

### Exécution sur le vrai CM5

Une fois que `build_linux.sh` produit `build/linux/*/release/bundle/`, copiez tout le répertoire `bundle/` sur le CM5 (il dépend des fichiers `.so` situés à côté du binaire, pas seulement de l'exécutable lui-même) vers `/opt/hydra-umc-dsi/bundle/`, puis exécutez `sudo kiosk/install_kiosk.sh` pour installer et activer `kiosk/hydra-umc-dsi.service`, une unité systemd qui lance l'app en plein écran sur `tty1` via [`cage`](https://github.com/cage-kiosk/cage) (un compositeur kiosque Wayland minimal exécutant exactement un client plein écran), avec `Restart=always` pour qu'un plantage relance l'app plutôt que de laisser un écran noir. Choisi plutôt que [`flutter-pi`](https://github.com/ardera/flutter-pi) (un intégrateur de moteur Flutter tiers pour Raspberry Pi, s'exécutant sans aucun système de fenêtrage) précisément parce qu'il réutilise sans modification la vraie sortie de `flutter build linux` déjà produite par `build_linux.sh` - flutter-pi compile au contraire directement contre le moteur Flutter, il nécessiterait donc sa propre étape de compilation séparée, ce n'est pas un remplacement direct. **Note d'honnêteté :** écrit et relu, mais jamais réellement exécuté sur un CM5 réel ni sur aucune autre machine Linux - même statut non vérifié que `flutter build linux` lui-même (voir `docs/ARCHITECTURE.md` section 7). Voir le commentaire d'en-tête de `kiosk/hydra-umc-dsi.service` pour les hypothèses exactes (utilisateur root du service, possession de `tty1`) à vérifier contre l'image Raspberry Pi OS réellement utilisée par le CM5.

## 🗺️ Suites Connues

Des lacunes réelles et vérifiées que le code de cette application a encore - pas de vagues TODO, chacune traçable jusqu'à un endroit précis du code ou de la documentation ci-dessus :

- **Le basculement d'accès distant n'est pas encore indépendant** - la section 1 de `REMOTE_API.md` ne reconnaît que `suite`, `android` et `ios` comme valeurs de `X-Hydra-Client` ; cette application envoie `dsi`, une valeur non reconnue qui n'est aujourd'hui jamais filtrée, donc ses requêtes de découverte passent sans condition. Corriger cela nécessite d'ajouter un 4ᵉ interrupteur au type `SystemSettings.remoteAccess` de HYDRA-UMC-STUDIO et à son onglet Config > Remote Access - un changement dans le code serveur d'un autre dépôt, hors périmètre de celui-ci. Voir la section 3 de `docs/ARCHITECTURE.md`.
- **La vue 3D n'a pas de vrai moteur de rendu 3D natif** - `ui/three_d_screen.dart` dessine aujourd'hui un petit indicateur isométrique de position X/Y/Z au lieu d'intégrer la vraie scène Three.js de STUDIO (`webview_flutter` n'a aucune implémentation Linux - voir la section 4 de `docs/ARCHITECTURE.md` pour le raisonnement complet). Un vrai moteur de rendu 3D natif pour cet écran est un travail futur, pas encore commencé.
- **Une exécution réelle sur matériel Linux/CM5 reste en attente** - `flutter build linux`, `build_linux.sh` et l'unité de démarrage automatique `kiosk/hydra-umc-dsi.service` ont été écrits et relus, mais jamais réellement exécutés sur une vraie machine Linux ni sur le CM5 lui-même depuis cet environnement de travail (une machine Windows sans aucune distribution WSL installée). Quiconque les exécute pour la première fois devrait considérer cela comme le premier vrai build/déploiement de cette plateforme, pas une formalité - voir la section 7 de `docs/ARCHITECTURE.md` et « Exécution sur le vrai CM5 » ci-dessus.

## 📂 Structure du Dépôt

```text
HYDRA-UMC-DSI/
├── build.bat, build.sh              # flutter pub get + incrément de version + flutter build windows (vérification sur machine de développement)
├── build_linux.sh                   # flutter pub get + incrément de version + flutter build linux (la vraie cible CM5 - à exécuter sur Linux réel)
├── CHANGELOG.md                      # historique des versions (voir Versionnement ci-dessus)
├── kiosk/
│   ├── hydra-umc-dsi.service        # unité systemd - démarrage automatique plein écran via cage
│   └── install_kiosk.sh             # installe et active l'unité ci-dessus (à exécuter sur le CM5 réel)
├── tool/
│   └── bump_version.dart            # Script d'incrément de version exécuté par build.bat/build.sh/build_linux.sh avant chaque compilation (voir Versionnement ci-dessus)
├── run_dev.bat, run_dev.sh          # flutter run - mode simulation bureau
├── lib/
│   ├── main.dart                    # Point d'entrée de l'app, ChangeNotifierProvider + porte de connexion, thème sombre fixe
│   ├── app_version.dart             # GÉNÉRÉ - régénéré par tool/bump_version.dart, à ne pas modifier à la main
│   ├── models/
│   │   ├── server_info.dart         # Entrée de découverte/connexion - reflète ServerInfo des 3 autres clients
│   │   └── hydra_state.dart         # RobotView/ControllerView/HydraState - vues mutables légères sur l'arbre brut settings.json
│   ├── network/
│   │   ├── hydra_api_client.dart    # REST : login, settings, commande atomique de robot, métriques système - X-Hydra-Client: dsi
│   │   ├── hydra_websocket.dart     # Client de synchronisation en direct /ws
│   │   ├── discovery.dart           # Balayage concurrent des sous-réseaux locaux réels de cet appareil
│   │   └── auth_prefs.dart          # Connexion et jeton persistés (shared_preferences)
│   ├── state/
│   │   ├── robot_view_model.dart    # Unique ChangeNotifier écouté par chaque écran
│   │   └── hydra_error.dart         # Surface d'erreur typée pour RobotViewModel (sans BuildContext propre)
│   ├── services/
│   │   └── backlight.dart           # Rétroéclairage adaptatif selon l'heure de la journée
│   ├── l10n/                        # Vraies localisations générées (7 langues) - voir l10n.yaml à la racine du dépôt
│   │   ├── app_localizations.dart   # Classe de base générée
│   │   ├── app_localizations_en.dart, _es.dart, _it.dart, _fr.dart, _de.dart, _ja.dart, _zh.dart
│   │   └── language_prefs.dart      # Préférence de langue persistée (shared_preferences)
│   └── ui/
│       ├── login_screen.dart        # Champs hôte/port/utilisateur/mot de passe + "Scan local network"
│       ├── main_screen.dart         # Barre de navigation tactile horizontale (6 onglets) - dans l'esprit de KlipperScreen
│       ├── dashboard_screen.dart    # Cartes par robot + barre de métriques système
│       ├── control_screen.dart      # Contrôles de jog/vitesse/vannes/pompes/lecture, mise en page tactile côte à côte
│       ├── camera_screen.dart       # Visionneuse MJPEG + interrupteur de vision
│       ├── three_d_screen.dart      # Indicateur isométrique natif X/Y/Z - PAS une WebView (voir docs/ARCHITECTURE.md §4)
│       ├── metrics_screen.dart      # Onglet dédié aux métriques hôte CM5 + identité du serveur
│       ├── settings_screen.dart     # Informations de connexion + déconnexion + propre version de l'app
│       └── widgets/
│           ├── joystick_pad.dart     # Pavé directionnel de jog, agrandi pour le tactile
│           ├── digital_readout.dart, status_led.dart
│           └── mjpeg_view.dart       # Analyseur de flux MJPEG écrit à la main
├── linux/                            # Runner bureau GTK - la cible RÉELLE, fenêtre fixe 1280x720
├── windows/                          # Runner bureau Windows - vérification sur machine de développement uniquement
├── docs/ARCHITECTURE.md
├── tools/
│   └── ci_validate.py               # Validation manifeste/CHANGELOG/docs utilisée par CI
├── bump_manifest_version.py          # Synchronise la version de hydra-umc.project.json avec la version native (--sync)
├── test/                             # widget_test, format_uptime_test, localization_test, robot_view_model_test
├── README.md                         # document original (anglais)
└── README_spa.md / README_ita.md / README_fra.md / README_deu.md / README_zho.md / README_jpn.md  # traductions
```

## 🔗 Projets Liés

Ce projet fait partie de l'écosystème robotique HYDRA-UMC du même auteur (JuanenRac / Electro Hobby 3D). Bon à savoir, car une demande pourrait en réalité concerner l'un de ceux-ci plutôt que ce dépôt.

**Projet Parent**
- **[HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)** — le vrai backend headless (REST/WebSocket) auquel parle réellement chaque client de contrôle ; le serveur auquel se connecte ce panneau via le vrai contrat `REMOTE_API.md` (découverte, connexion, commandes atomiques, synchronisation WebSocket).

**Projets Frères** — parlent également à la propre API de HYDRA-UMC-SERVER, chacun en tant que son propre client
- **[HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — tableau de bord de contrôle web avec visualisation 3D multi-robot en temps réel.
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** — centre de commande d'essaim de bureau (PySide6) pour plusieurs serveurs à la fois, empaqueté en exécutable autonome ; parle exactement le même contrat `REMOTE_API.md` que ce panneau.
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** — application de contrôle Android native avec connexion biométrique et un compagnon Wear OS jumelé ; parle exactement le même contrat `REMOTE_API.md` que ce panneau.
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — application de contrôle iOS/iPadOS (Flutter) avec synchronisation WebSocket en temps réel ; parle exactement le même contrat `REMOTE_API.md` que ce panneau, et c'est d'elle que la propre découverte mDNS réelle de ce panneau a été portée.
- **[HYDRA-UMC-BRIDGE-AMR](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-AMR)** — frontière de coordination pour les flottes AGV/AMR via un éditeur MQTT VDA 5050 réel.
- **[HYDRA-UMC-BRIDGE-CNC](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-CNC)** — coordinateur haut niveau pour cellules CNC avec accès réel au statut/octets de contrôle GRBL.
- **[HYDRA-UMC-BRIDGE-DROIDS](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-DROIDS)** — frontière de coordination pour droïdes à pattes/humanoïdes, avec un véritable émetteur de commandes Boston Dynamics Spot.
- **[HYDRA-UMC-BRIDGE-LASER](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-LASER)** — coordinateur de sécurité pour cellules laser lisant 3 vraies sécurités GPIO de clé/enceinte/verrouillage.
- **[HYDRA-UMC-BRIDGE-OPENPNP](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-OPENPNP)** — coordinateur haut niveau sûr pour le flux de cartes du pick-and-place OpenPnP.
- **[HYDRA-UMC-BRIDGE-PRINTER3D](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-PRINTER3D)** — frontière de coordination sûre pour imprimantes 3D Moonraker/Klipper, avec de vraies commandes de tâche contrôlées.
- **[HYDRA-UMC-BRIDGE-ROS2](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-ROS2)** — coordinateur de sécurité avec un vrai transport ROS 2 rclpy à importation paresseuse.
- **[HYDRA-UMC-BRIDGE-UAV](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-UAV)** — frontière de coordination pour UAV équipés de caméra, avec un véritable émetteur de commandes MAVLink.

**Directement Liés**
- **[HYDRA-UMC-WATCH](https://github.com/JuanenRac/HYDRA-UMC-WATCH)** — application compagnon WearOS avec de vraies alertes haptiques et un relais vocal vers le téléphone jumelé ; le dispositif d'alerte de sécurité portable qui complète ce panneau tactile, portant les avertissements au poignet de l'opérateur en plus de l'écran propre de la carte.
- **[HYDRA-UMC-COGNITIVE-NODE](https://github.com/JuanenRac/HYDRA-UMC-COGNITIVE-NODE)** — hub d'intégration pour le pipeline cognitif Hailo-10 (orchestration LLM/VLA/voix) ; ajoute un contrôle vocal directement sur ce panneau tactile.
- **[HYDRA-UMC-VOICE-UI](https://github.com/JuanenRac/HYDRA-UMC-VOICE-UI)** — vrai front-end vocal (VAD + analyseur d'intention) avec un relais Watch borné et soumis à confirmation ; ajoute un contrôle vocal directement sur ce panneau tactile.

**Fait Également Partie de l'Écosystème**

*Matériel & Plateforme de Base*
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** — la carte mère physique du bras robotique : hôte CM5 + coprocesseur STM32H745 double cœur, coordonnant jusqu'à 8 bras-outils via CAN-OTA/SPI-OTA.
- **[HYDRA-UMC-OS](https://github.com/JuanenRac/HYDRA-UMC-OS)** — couche produit reproductible sur Raspberry Pi OS pour le CM5 : agent en lecture seule, config/profils validés, provisionnement WiFi de premier contact.
- **[HYDRA-UMC-SDK](https://github.com/JuanenRac/HYDRA-UMC-SDK)** — le contrat JSON-Schema partagé et la barrière de sécurité contre laquelle chaque bridge valide ses commandes.

*Backend Central & Clients*
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** — créateur/éditeur graphique de bureau pour URDF qui envoie les modèles terminés vers le propre catalogue de STUDIO.

*Plateforme d'Outils URTC*
- **[URTC](https://github.com/JuanenRac/URTC)** — firmware pour la carte physique Universal Robot Tool Controller, plus de 25 profils d'outil sur bus CAN.
- **[URTC-FLASHER](https://github.com/JuanenRac/URTC-FLASHER)** — outil de bureau à interface graphique pour flasher les cartes URTC, CAN-OTA plus SWD/JTAG puce complète.
- **[URTC-TESTER](https://github.com/JuanenRac/URTC-TESTER)** — outil de bureau de diagnostic CAN-bus en direct pour cartes URTC, un panneau par profil d'outil.
- **[URTC-WEB-STUDIO](https://github.com/JuanenRac/URTC-WEB-STUDIO)** — alternative basée navigateur à URTC-TESTER via la Web Serial API, sans installation locale.

*Nœud IA de Vision (Hailo-8)*
- **[HYDRA-UMC-VISION-NODE](https://github.com/JuanenRac/HYDRA-UMC-VISION-NODE)** — hub d'intégration pour le pipeline de vision Hailo-8, avec une vraie vérification de disponibilité matérielle par étape.
- **[HYDRA-UMC-DETECTION-HEF](https://github.com/JuanenRac/HYDRA-UMC-DETECTION-HEF)** — registre réel de modèles compilés avec vérification de chargement sécurisé par architecture Hailo/checksum.
- **[HYDRA-UMC-VISION-STREAMER](https://github.com/JuanenRac/HYDRA-UMC-VISION-STREAMER)** — générateur réel de pipeline GStreamer + config MediaMTX, avec une vraie frontière d'intégration HailoRT.
- **[HYDRA-UMC-VISUAL-SERVOING-API](https://github.com/JuanenRac/HYDRA-UMC-VISUAL-SERVOING-API)** — vraie loi de correction Position-Based Visual Servoing, verrouillée sur l'état de zone en amont.
- **[HYDRA-UMC-SAFETY-ZONES](https://github.com/JuanenRac/HYDRA-UMC-SAFETY-ZONES)** — vraie vérification de violation de zone et demande d'E-STOP, avec application de la fraîcheur de calibration.

*Nœud IA Cognitif (Hailo-10)*
- **[HYDRA-UMC-VLA-ENGINE](https://github.com/JuanenRac/HYDRA-UMC-VLA-ENGINE)** — vrai encodage/décodage de jetons d'action et génération de trajectoire pour un modèle Vision-Language-Action.
- **[HYDRA-UMC-SEMANTIC-PLANNER](https://github.com/JuanenRac/HYDRA-UMC-SEMANTIC-PLANNER)** — vraie décomposition de tâches basée sur des règles et récupération sémantique d'erreurs sur les codes d'erreur MCU.
- **[HYDRA-UMC-DOCS-QA](https://github.com/JuanenRac/HYDRA-UMC-DOCS-QA)** — vraie recherche documentaire TF-IDF (bibliothèque standard uniquement) sur les propres documents Markdown de cet écosystème.

*Orchestration & Essaim*
- **[HYDRA-UMC-ORCHESTRATOR](https://github.com/JuanenRac/HYDRA-UMC-ORCHESTRATOR)** — hub d'intégration avec un vrai contrat de rapport de santé gRPC/Protobuf et une machine à états de mission.
- **[HYDRA-UMC-JOB-DISPATCHER](https://github.com/JuanenRac/HYDRA-UMC-JOB-DISPATCHER)** — vraie file de tâches basée sur la priorité avec déduplication, via une vraie API HTTP.
- **[HYDRA-UMC-NODE-HEALING](https://github.com/JuanenRac/HYDRA-UMC-NODE-HEALING)** — vrai chien de garde de santé de flotte basé sur gRPC, avec retry/backoff et détection d'incohérence d'identité.
- **[HYDRA-UMC-PATH-PLANNER-3D](https://github.com/JuanenRac/HYDRA-UMC-PATH-PLANNER-3D)** — vrai planificateur de trajectoire 3D basé sur RRT, avec vraie validation des collisions obstacle/espace de travail.
- **[HYDRA-UMC-SWARM-SYNC](https://github.com/JuanenRac/HYDRA-UMC-SWARM-SYNC)** — vraie synchronisation d'état CRDT LWW-Element-Map, testée par propriétés pour la convergence multi-cellule.

*Jumeau Numérique & Simulation*
- **[HYDRA-UMC-TWIN](https://github.com/JuanenRac/HYDRA-UMC-TWIN)** — hub d'intégration pour le moteur de jumeau numérique, avec un vrai contrat de synchronisation par compatibilité de version.
- **[HYDRA-UMC-HIL-BRIDGE](https://github.com/JuanenRac/HYDRA-UMC-HIL-BRIDGE)** — vrai verrouillage de sécurité hardware-in-the-loop routant les commandes entre simulation et matériel réel.
- **[HYDRA-UMC-PHYSICS-REPLICA](https://github.com/JuanenRac/HYDRA-UMC-PHYSICS-REPLICA)** — vraie cinématique directe et validation des limites articulaires sur un vrai sous-ensemble URDF.
- **[HYDRA-UMC-SYNTHETIC-DATA-GEN](https://github.com/JuanenRac/HYDRA-UMC-SYNTHETIC-DATA-GEN)** — vrai générateur procédural de scènes 2D avec export d'annotations YOLO/COCO.

*Données & Analytique*
- **[HYDRA-UMC-DATALAKE](https://github.com/JuanenRac/HYDRA-UMC-DATALAKE)** — vrai magasin de séries temporelles basé sur sqlite3, avec une vraie API HTTP d'ingestion/requête.
- **[HYDRA-UMC-ANOMALY-DETECTOR](https://github.com/JuanenRac/HYDRA-UMC-ANOMALY-DETECTOR)** — vrai détecteur d'anomalies FFT + ligne de base statistique, avec surveillance de dérive.
- **[HYDRA-UMC-PRODUCTION-REPORTS](https://github.com/JuanenRac/HYDRA-UMC-PRODUCTION-REPORTS)** — vrai calcul OEE/disponibilité sur l'historique de DATALAKE, avec export CSV reproductible.
- **[HYDRA-UMC-TELEMETRY-COLLECTOR](https://github.com/JuanenRac/HYDRA-UMC-TELEMETRY-COLLECTOR)** — vrai pipeline d'ingestion CAN/WebSocket vers DATALAKE, avec déduplication par séquence.

*Passerelle Industrielle*
- **[HYDRA-UMC-GATEWAY-INDUSTRIAL](https://github.com/JuanenRac/HYDRA-UMC-GATEWAY-INDUSTRIAL)** — hub d'intégration relayant vers les protocoles industriels, avec une vraie couche de liste blanche de commandes/contre-pression.
- **[HYDRA-UMC-OPCUA-SERVER](https://github.com/JuanenRac/HYDRA-UMC-OPCUA-SERVER)** — vrai espace d'adressage OPC-UA, vérifié avec une vraie session client du protocole binaire.
- **[HYDRA-UMC-MQTT-BROKER](https://github.com/JuanenRac/HYDRA-UMC-MQTT-BROKER)** — vrai broker MQTT avec authentification par client optionnelle et ACL de sujets.
- **[HYDRA-UMC-MTCONNECT-ADAPTER](https://github.com/JuanenRac/HYDRA-UMC-MTCONNECT-ADAPTER)** — vrais points de terminaison XML MTConnect `/probe` et `/current`, avec sortie en mode dégradé.

*Outils Complémentaires & Opérations de l'Écosystème*
- **[HYDRA-UMC-DASHBOARD-AI](https://github.com/JuanenRac/HYDRA-UMC-DASHBOARD-AI)** — panneaux Smart Summaries et Anomaly Highlighting sur DATALAKE/ANOMALY-DETECTOR, avec un repli statistique honnête.
- **[HYDRA-UMC-TOOL-CLI](https://github.com/JuanenRac/HYDRA-UMC-TOOL-CLI)** — CLI de flotte avec un vrai contrat de codes de sortie stable, un vrai client en direct de la propre API de HYDRA-UMC-SERVER.
- **[URTC-SMART-RACK](https://github.com/JuanenRac/URTC-SMART-RACK)** — firmware pour un rack de montage de cartes avec décodage réel d'ID d'outil et logique de préchauffage Smart Idle.
- **[URTC-VISION-TOOL](https://github.com/JuanenRac/URTC-VISION-TOOL)** — firmware plus un vrai compagnon de vision Python pour une tête d'outil d'inspection thermique/RGB.
- **[HYDRA-UMC-UPDATER](https://github.com/JuanenRac/HYDRA-UMC-UPDATER)** — outil administratif de bureau qui découvre, clone et met à jour chaque dépôt de cet écosystème.
- **[HYDRA-UMC-OS-REBUILDER](https://github.com/JuanenRac/HYDRA-UMC-OS-REBUILDER)** — outil de bureau Windows/Linux qui construit une image de la CM5 prête à graver, préchargée avec les versions les plus actuelles de l'écosystème, avec une configuration de premier démarrage Wi-Fi/utilisateur/SSH façon Raspberry Pi Imager.

---

## 📚 Documentation & Communauté

- **[CONTRIBUTING.md](CONTRIBUTING.md)** — pile technologique et lignes directrices de codage pour une pull request.
- **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** — les normes de comportement attendues dans cette communauté.
- **[SECURITY.md](SECURITY.md)** — comment signaler une vulnérabilité, et les véritables axes de sécurité de ce projet.
- **[SUPPORT.md](SUPPORT.md)** — où poser des questions et signaler des bugs.
- **[LICENSE.md](LICENSE.md)** — la licence propre de ce projet.

## 👤 AUTEUR
**JuanenRac** (Electro Hobby 3D)
📧 electrohobby3d@gmail.com
📺 [youtube.com/@electrohobby3d](https://youtube.com/@electrohobby3d)

## 📜 LICENCE

GNU General Public License v3.0 (GPL-3.0) pour le code source - voir [`LICENSE`](LICENSE).

La documentation (ce README et ses traductions - `README_spa.md`, `README_ita.md`, `README_fra.md`, `README_deu.md`, `README_zho.md`, `README_jpn.md`) est disponible sous **Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)**. Texte complet sur https://creativecommons.org/licenses/by-sa/4.0/.
