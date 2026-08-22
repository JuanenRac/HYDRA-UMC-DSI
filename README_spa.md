# 🖥️ HYDRA-UMC DSI

<p align="left">
  <img src="https://img.shields.io/badge/Licencia-GPL%203.0-blue.svg" alt="GPL 3.0">
  <img src="https://img.shields.io/badge/Framework-Flutter%203.x-02569B.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Lenguaje-Dart-0175C2.svg" alt="Dart">
  <img src="https://img.shields.io/badge/Plataforma-Linux%20%7C%20CM5-E34F26.svg" alt="Platform">
</p>


Una interfaz táctil nativa en Flutter (Dart, con target real de escritorio Linux) para la pantalla táctil DSI de 5"/7" del propio HYDRA-UMC en la Compute Module 5 - los dos tamaños físicos del panel comparten exactamente la misma resolución de 1280x720 píxeles, así que esta app usa un único layout fijo, no responsive, en vez de adaptarse a dos tamaños. Habla exactamente el mismo contrato [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-STUDIO/blob/main/docs/REMOTE_API.md) que usan [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE), [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) y [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) - descubrimiento, login, comandos atómicos por robot y sincronización en vivo por WebSocket contra un servidor [HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO) en ejecución, corriendo directamente en la propia placa en vez de en una pestaña de navegador. Ver [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) para el diseño completo, incluyendo por qué Flutter (y no Kivy) y por qué la pantalla 3D no usa un WebView.

**Esta app es una de las dos vías de control que coexisten en la misma placa** - la CM5 también lleva una salida HDMI para un monitor externo completo que ejecuta la interfaz web. Esta app DSI complementa esa vía con una consola táctil directa y siempre disponible en la propia placa; no sustituye a la interfaz web.

## 🏗️ Qué está implementado

- **Login** (`lib/ui/login_screen.dart`, `lib/state/robot_view_model.dart`) - campos de IP/puerto del servidor y usuario/contraseña dimensionados para uso táctil, `POST /api/login` contra `admin`/`admin` (precargado - la cuenta por defecto que todo servidor de este ecosistema crea en su primer arranque; se pueden crear cuentas adicionales de menor privilegio "operator" desde Config > Users en la interfaz web), token de sesión persistido entre arranques vía `shared_preferences` - importante en un panel tipo kiosco que debe seguir con la sesión iniciada tras un ciclo de apagado/encendido de la propia CM5, no solo tras reabrir la app. Un diálogo de "Buscar en la red local" (`lib/network/discovery.dart`) encuentra servidores sin necesidad de conocer ya la IP - doblemente útil aquí, ya que la CM5 en la que corre esta app suele ser el propio controlador al que debe conectarse.
- **Descubrimiento de red** (`lib/network/discovery.dart`) - dos vías en paralelo desde el mismo diálogo "Scan local network": mDNS/Bonjour real (`discoverMdns()`, consultando el propio servicio `_hydra._tcp` que publica `server.ts` vía el paquete `multicast_dns`) y un escaneo concurrente por fuerza bruta de `GET /api/hydra-info` en las subredes locales reales de este dispositivo (`scanSubnets()`), deduplicado por host:puerto - portado desde HYDRA-UMC-IOS-CONTROL, el primer cliente del ecosistema en añadir mDNS real.
- **Sincronización atómica de comandos** (`lib/state/robot_view_model.dart`, su propio `_sendAtomicCommand()`) - cada escritura (enable/disable/play/pause/stop/jog/valve/pump/speed/vision) usa el endpoint real `POST /api/robot/:id/command`, con la propagación correcta a robots combinados (`combinedWith`) y una reversión al estado previo si la petición falla - especialmente importante para un mando de jog/E-STOP situado a pocos metros de los robots reales.
- **Sincronización en vivo por WebSocket** (`lib/network/hydra_websocket.dart`) - siempre añade `?token=`, gestiona los tipos de difusión `"settings"` y `"delta"`, reconecta automáticamente si se cae la conexión.
- **Navegación táctil horizontal** (`lib/ui/main_screen.dart`) - una barra superior persistente con 6 pestañas grandes de icono+etiqueta (Dashboard/Control/Cámara/Vista 3D/Métricas/Ajustes) a lo ancho del marco fijo de 1280px, en el espíritu de KlipperScreen en vez de una barra inferior estilo móvil - siguiendo el catálogo que pidió el dueño del proyecto, reorganizado para un panel táctil ancho en vez de un layout vertical de móvil.
- **Dashboard** (`lib/ui/dashboard_screen.dart`) - tarjetas por robot, reactivas en tiempo real vía `Provider`, convención de LED (verde parpadeante = activo, rojo fijo = inactivo), indicación de robots combinados y chips de módulos (CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK) - el mismo lenguaje visual que el resto de clientes de este ecosistema.
- **Control Manual** (`lib/ui/control_screen.dart`, `lib/ui/widgets/joystick_pad.dart`) - layout lado a lado (mando de jog a la izquierda, telemetría/velocidad/E-S a la derecha) dimensionado para el marco de 1280x720 en vez de una única columna con scroll, protección real de pulsación larga en E-STOP/STOP (un toque rápido no hace nada más que una vibración + aviso visual, solo una pulsación sostenida real envía el comando), deslizadores de velocidad/aceleración, interruptores de válvulas/bombas.
- **Cámara** (`lib/ui/camera_screen.dart`, `lib/ui/widgets/mjpeg_view.dart`) - el mismo parser de MJPEG hecho a mano y sin dependencias que usa HYDRA-UMC-IOS-CONTROL (sin WebView, sin código específico de plataforma - funciona en escritorio Linux sin cambios), un estado claro de "Cámara Desactivada" y un interruptor para activar/desactivar la visión de un robot directamente desde el servidor.
- **Vista 3D** (`lib/ui/three_d_screen.dart`) - **no** es un WebView incrustando la escena real Three.js de STUDIO, a diferencia de las apps de iOS/Android - `webview_flutter` no tiene ninguna implementación para escritorio Linux, y un motor de navegador completo supone una carga en tiempo de ejecución mayor de la que necesita este panel empotrado de bajo consumo. En su lugar: un pequeño indicador nativo isométrico de posición X/Y/Z (`CustomPainter`, sin motor 3D), con un aviso en pantalla que señala la escena 3D real en el monitor conectado por HDMI a esta misma placa. Ver la sección 4 de `docs/ARCHITECTURE.md` para el razonamiento completo.
- **Métricas del Sistema** (`lib/ui/metrics_screen.dart`) - su propia pestaña dedicada (no integrada en el Dashboard como hacen iOS/Android) con paneles de CPU/memoria/temperatura/tiempo activo desde `GET /api/system/metrics`, más nombre de host/número de controladores/número de robots/versión de la app desde `GET /api/hydra-info`.
- **Ajustes** (`lib/ui/settings_screen.dart`) - información de conexión, identidad del servidor, cierre de sesión y la propia versión de esta app (ver [Versionado](#-versionado) más abajo).
- **Arranque automático en kiosco** (`kiosk/hydra-umc-dsi.service`, `kiosk/install_kiosk.sh`) - unidad systemd que lanza la app a pantalla completa en `tty1` vía `cage`, con `Restart=always`. Ver "Ejecución en la CM5 real" más abajo.

**Estado: scaffold + las 6 pantallas del catálogo implementadas y conectadas al contrato real REMOTE_API.md.** `flutter analyze` limpio, `flutter build windows` produce un binario en ejecución, `flutter test` pasa - ver "Compilación" más abajo para lo que sí y lo que no se pudo verificar desde este entorno de trabajo Windows, dado que el target real es Linux.

## 🚀 Compilación

Requiere el [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal stable). Este repositorio se compila/verifica contra Flutter 3.47.0. Solo `linux/` y `windows/` están configurados como plataformas en este repositorio (sin carpetas `android/`, `ios/`, `web/` ni `macos/`) - Linux es el target real (el propio sistema operativo de la CM5); Windows existe únicamente para poder compilar, ejecutar y probar la lógica de esta app en una máquina sin toolchain de Linux.

### Scripts de compilación

```bash
./build.sh          # Git Bash / WSL, o build.bat para cmd/PowerShell - flutter pub get + incremento de versión + flutter build windows (verificación en máquina de desarrollo)
./build_linux.sh    # Debe ejecutarse EN una máquina Linux real (o la propia CM5) - flutter pub get + incremento de versión + flutter build linux (el target real de despliegue)
./run_dev.sh         # Git Bash / WSL, o run_dev.bat para cmd/PowerShell - modo de simulación de escritorio (flutter run), sin necesitar el hardware
```

Los 3 scripts de compilación (`build.sh`/`build.bat`/`build_linux.sh`) incrementan primero la versión de la app - ver [Versionado](#-versionado) más abajo. `run_dev.sh`/`run_dev.bat` no lo hacen - un `flutter run` de ciclo de desarrollo no es una "compilación real" bajo esa política.

### Compilación manual

```bash
flutter pub get
flutter analyze                  # análisis estático - no necesita compilador
flutter test                     # pruebas de widgets
dart run tool/bump_version.dart  # incrementa la versión, igual que build.sh/build.bat/build_linux.sh
flutter build windows            # prueba de humo en la máquina de desarrollo - produce build/windows/x64/runner/Release/hydra_umc_dsi.exe
flutter build linux              # el target REAL - debe ejecutarse en una máquina Linux real, produce build/linux/*/release/bundle/
flutter run -d windows           # o -d linux en una máquina Linux real, para un ciclo de desarrollo en vivo con simulación de escritorio
```

**Nota de honestidad sobre la verificación en Linux:** este repositorio se ha escrito en una máquina Windows sin toolchain de compilación de Linux disponible (confirmado con `wsl --status` - no hay ninguna distribución de WSL instalada). `flutter build linux` nunca se ha ejecutado realmente contra este código desde este entorno de trabajo; `flutter build windows` se ha usado como sustituto de prueba de humo, tal como permite explícitamente el encargo. Ver la sección 7 de `docs/ARCHITECTURE.md` para la lista exacta de lo verificado y lo no verificado, y `mejoras_futuras.txt` para el seguimiento pendiente.

## 🔢 Versionado

Este repositorio sigue una política ecosistema-wide (compartida con
[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL),
implementada allí en paralelo): la versión sube automáticamente en **cada
compilación real**, sin edición manual de la línea `version:` de
`pubspec.yaml`. `build.sh`/`build.bat`/`build_linux.sh` ejecutan
`tool/bump_version.dart` antes de invocar `flutter build`, aplicando:

- **Patch, estilo cuentakilómetros (base 10):** +1 en cada compilación; si
  superaría 9, se resetea a 0 y la minor sube +1 en su lugar - ejemplo:
  `1.0.9` -> `1.1.0`. La major nunca se toca automáticamente.
- **Build-number** (la parte tras el `+`): un contador monótono simple, +1
  en cada compilación, sin acarreo.

El mismo script regenera `lib/app_version.dart` (generado, no editado a
mano - un simple archivo `const`, no una nueva dependencia en tiempo de
ejecución como `package_info_plus`), que la app lee en tiempo de ejecución
para mostrar su propia versión en la pantalla de **Ajustes**. Ver
[CHANGELOG.md](CHANGELOG.md) para el historial de versiones.

### Ejecución en la CM5 real

Después de que `build_linux.sh` genere `build/linux/*/release/bundle/`, copia todo el directorio `bundle/` a la CM5 (depende de los archivos `.so` que están junto al binario, no solo del propio ejecutable) a `/opt/hydra-umc-dsi/bundle/`, y luego ejecuta `sudo kiosk/install_kiosk.sh` para instalar y activar `kiosk/hydra-umc-dsi.service`, una unidad systemd que lanza la app a pantalla completa en `tty1` vía [`cage`](https://github.com/cage-kiosk/cage) (un compositor kiosco Wayland mínimo que ejecuta exactamente un cliente a pantalla completa), con `Restart=always` para que un fallo relance la app en vez de dejar la pantalla en negro. Elegido frente a [`flutter-pi`](https://github.com/ardera/flutter-pi) (un embebedor de motor Flutter de terceros para Raspberry Pi que corre sin ningún gestor de ventanas) precisamente porque reutiliza sin modificar la salida real de `flutter build linux` que ya genera `build_linux.sh` - flutter-pi en cambio compila directamente contra el motor de Flutter, así que necesitaría su propio paso de compilación separado, no es un sustituto directo. **Nota de honestidad:** escrito y revisado, pero nunca ejecutado de verdad contra una CM5 real ni ninguna otra máquina Linux - mismo estado sin verificar que el propio `flutter build linux` (ver `docs/ARCHITECTURE.md` sección 7). Ver el propio comentario de cabecera de `kiosk/hydra-umc-dsi.service` para las asunciones exactas (usuario root del servicio, propiedad de `tty1`) que habría que comprobar contra la imagen de Raspberry Pi OS real que use la CM5.

## 📂 Estructura del Repositorio

```text
HYDRA-UMC-DSI/
├── build.bat, build.sh              # flutter pub get + incremento de versión + flutter build windows (verificación en máquina de desarrollo)
├── build_linux.sh                   # flutter pub get + incremento de versión + flutter build linux (el target real de la CM5 - ejecutar en Linux real)
├── CHANGELOG.md                      # historial de versiones (ver Versionado más arriba)
├── kiosk/
│   ├── hydra-umc-dsi.service        # unidad systemd - arranque automático a pantalla completa vía cage
│   └── install_kiosk.sh             # instala y activa la unidad anterior (ejecutar en la CM5 real)
├── tool/
│   └── bump_version.dart            # Script de incremento de versión que build.bat/build.sh/build_linux.sh ejecutan antes de cada compilación (ver Versionado más arriba)
├── run_dev.bat, run_dev.sh          # flutter run - modo de simulación de escritorio
├── lib/
│   ├── main.dart                    # Punto de entrada, ChangeNotifierProvider + puerta de login, tema oscuro fijo
│   ├── app_version.dart             # GENERADO - regenerado por tool/bump_version.dart, no editar a mano
│   ├── models/
│   │   ├── server_info.dart         # Entrada de descubrimiento/conexión - refleja ServerInfo de los otros 3 clientes
│   │   └── hydra_state.dart         # RobotView/ControllerView/HydraState - vistas mutables ligeras sobre el árbol bruto de settings.json
│   ├── network/
│   │   ├── hydra_api_client.dart    # REST: login, settings, comando atómico de robot, métricas de sistema - X-Hydra-Client: dsi
│   │   ├── hydra_websocket.dart     # Cliente de sincronización en vivo /ws
│   │   ├── discovery.dart           # Escaneo concurrente de las subredes locales reales de este dispositivo
│   │   └── auth_prefs.dart          # Conexión y token persistidos (shared_preferences)
│   ├── state/
│   │   └── robot_view_model.dart    # Único ChangeNotifier que escucha cada pantalla
│   └── ui/
│       ├── login_screen.dart        # Campos de host/puerto/usuario/contraseña + "Buscar en la red local"
│       ├── main_screen.dart         # Barra de navegación táctil horizontal (6 pestañas) - en el espíritu de KlipperScreen
│       ├── dashboard_screen.dart    # Tarjetas por robot + barra de métricas de sistema
│       ├── control_screen.dart      # Controles de jog/velocidad/válvulas/bombas/reproducción, layout táctil lado a lado
│       ├── camera_screen.dart       # Visor MJPEG + interruptor de visión
│       ├── three_d_screen.dart      # Indicador isométrico nativo X/Y/Z - NO es un WebView (ver docs/ARCHITECTURE.md §4)
│       ├── metrics_screen.dart      # Pestaña dedicada a métricas del host CM5 + identidad del servidor
│       ├── settings_screen.dart     # Información de conexión + cierre de sesión + versión propia de la app
│       └── widgets/
│           ├── joystick_pad.dart     # Mando direccional de jog, agrandado para uso táctil
│           ├── digital_readout.dart, status_led.dart
│           └── mjpeg_view.dart       # Parser de flujo MJPEG hecho a mano
├── linux/                            # Runner de escritorio GTK - el target REAL, ventana fija 1280x720
├── windows/                          # Runner de escritorio Windows - solo verificación en máquina de desarrollo
├── docs/ARCHITECTURE.md
├── test/widget_test.dart
├── README.md                         # documento original (inglés)
└── README_spa.md / README_ita.md / README_fra.md / README_deu.md  # traducciones
```

## 🔗 Proyectos Relacionados

Este proyecto forma parte de un ecosistema de robótica más amplio del mismo autor (JuanenRac / Electro Hobby 3D). Vale la pena conocerlos, ya que una petición podría en realidad referirse a uno de ellos en vez de a este repositorio:

**Plataforma HYDRA-UMC** — la célula de microfábrica multi-robot
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** — la placa base en sí: host Raspberry Pi CM5 + coprocesador de tiempo real STM32H745 de doble núcleo, orquestando hasta 8 brazos robóticos distribuidos por CAN-OTA/SPI-OTA. Hardware y firmware propios, GPL-3.0/CERN-OHL-S v2/CC BY-SA 4.0.
- **[HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — panel de control web para HYDRA-UMC: visualización 3D multi-robot, grabación de cinemática/trayectorias, flasheo y pruebas CAN-OTA para toda la plataforma. React + Vite + Three.js.
- **[HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)** — el backend headless (Node/Express/WebSocket) que antes venía integrado dentro del propio proceso de HYDRA-UMC-STUDIO. Aloja la API REST/WS de control de robots, la persistencia de settings.json, la autenticación JWT y el descubrimiento mDNS. HYDRA-UMC-STUDIO es ahora un cliente frontend estático puro que se comunica con él por red.
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** — app de control Android para HYDRA-UMC por Wi-Fi/Bluetooth. App real y funcional - conjunto completo de funciones de control remoto, autenticación JWT, almacenamiento cifrado de credenciales.
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — app de control iOS/iPadOS para HYDRA-UMC por Wi-Fi, hecha en Flutter (multiplataforma, verificable en Windows sin necesitar un Mac; el empaquetado final del `.ipa` sigue necesitando Xcode). App real y funcional - mismo conjunto de funciones que la app Android.
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** — centro de mando de escritorio (Python/PySide6) para el enjambre: descubrimiento de red multi-controlador, sincronización bidireccional en vivo, visor 3D real de robots, espacio de trabajo acoplable estilo Photoshop. Real y funcional, no un placeholder.
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** — creador/editor gráfico de URDF de escritorio (Python/PySide6) para el catálogo de modelos de este proyecto: obtiene archivos fuente desde GitHub o una carpeta local, valida la viabilidad de los grados de libertad, edita color/escala/cinemática con vista previa 3D en vivo, y envía el resultado final a un servidor STUDIO en ejecución. Real y funcional, no un placeholder.
- **HYDRA-UMC-DSI** *(este repositorio)* — interfaz táctil nativa en Flutter para la pantalla táctil DSI de 5"/7" del propio HYDRA-UMC (1280×720, misma resolución en ambos tamaños) en la Compute Module 5, controlando este mismo servidor directamente desde la placa. Scaffold real y funcional con las 6 pantallas del catálogo conectadas al servidor en vivo; compilación real del target Linux aún no ejecutada en hardware real (entorno de trabajo solo Windows - ver la sección "Compilación" del README).

**Plataforma URTC** — el controlador de cabezal de herramienta que lleva cada brazo robótico HYDRA-UMC
- **[URTC](https://github.com/JuanenRac/URTC)** — Universal Robot Tool Controller: controlador de cabezal de herramienta por bus CAN basado en STM32F303, 25 perfiles de herramienta totalmente implementados, actualización de firmware CAN-OTA.
- **[URTC Flasher](https://github.com/JuanenRac/URTC-FLASHER)** — herramienta de escritorio de flasheo CAN-OTA + chip completo SWD/JTAG para placas URTC (Windows/Linux).
- **[URTC Tester](https://github.com/JuanenRac/URTC-TESTER)** — herramienta de escritorio de diagnóstico en vivo por bus CAN para placas URTC, un panel por perfil de herramienta (Windows/Linux).
- **[URTC Web Studio](https://github.com/JuanenRac/URTC-WEB-STUDIO)** — alternativa basada en navegador a las 2 herramientas de escritorio anteriores (Web Serial API + SLCAN), sin instalación local necesaria.

---

## 👤 Autor

**JuanenRac** (Electro Hobby 3D)
📧 electrohobby3d@gmail.com
📺 youtube.com/@electrohobby3d

---

## 📜 Licencia

Licencia Pública General de GNU v3.0 (GPL-3.0) para el código fuente - ver [`LICENSE`](LICENSE).

La documentación (este README y sus traducciones - `README_spa.md`, `README_ita.md`, `README_fra.md`, `README_deu.md`) está disponible bajo **Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)**. Texto completo en https://creativecommons.org/licenses/by-sa/4.0/.
