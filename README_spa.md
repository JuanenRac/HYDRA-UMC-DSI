<p align="center">
  <img src="images/HYDRA_UMC_BANNER.svg" alt="HYDRA-UMC-DSI banner" width="100%">
</p>
# 🖥️ HYDRA-UMC DSI

<p align="center">
  <a href="README.md">🇺🇸 English</a> |
  🇪🇸 <b>Español</b> |
  <a href="README_fra.md">🇫🇷 Français</a> |
  <a href="README_ita.md">🇮🇹 Italiano</a> |
  <a href="README_deu.md">🇩🇪 Deutsch</a> |
  <a href="README_zho.md">🇨🇳 简体中文</a> |
  <a href="README_jpn.md">🇯🇵 日本語</a>
</p>


<p align="left">
  <img src="https://img.shields.io/badge/Licencia-GPL%203.0-blue.svg" alt="GPL 3.0">
  <img src="https://img.shields.io/badge/Framework-Flutter%203.x-02569B.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Lenguaje-Dart-0175C2.svg" alt="Dart">
  <img src="https://img.shields.io/badge/Plataforma-Linux%20%7C%20CM5-E34F26.svg" alt="Platform">
</p>


Una interfaz táctil nativa en Flutter (Dart, con target real de escritorio Linux) para la pantalla táctil DSI de 5"/7" del propio HYDRA-UMC en la Compute Module 5 - los dos tamaños físicos del panel comparten exactamente la misma resolución de 1280x720 píxeles, así que esta app usa un único layout fijo, no responsive, en vez de adaptarse a dos tamaños. Habla exactamente el mismo contrato [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-STUDIO/blob/main/docs/REMOTE_API.md) que usan [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE), [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) y [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) - descubrimiento, login, comandos atómicos por robot y sincronización en vivo por WebSocket contra un servidor [HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO) en ejecución, corriendo directamente en la propia placa en vez de en una pestaña de navegador. Ver [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) para el diseño completo, incluyendo por qué Flutter (y no Kivy) y por qué la pantalla 3D no usa un WebView.

**Esta app es una de las dos vías de control que coexisten en la misma placa** - la CM5 también lleva una salida HDMI para un monitor externo completo que ejecuta la interfaz web. Esta app DSI complementa esa vía con una consola táctil directa y siempre disponible en la propia placa; no sustituye a la interfaz web.

## 🏗️ Qué está implementado

- **Login** (`lib/ui/login_screen.dart`, `lib/state/robot_view_model.dart`) - campos de IP/puerto del servidor precargados con un valor de LAN razonable, campos de usuario/contraseña dimensionados para uso táctil y vacíos por defecto (sin ninguna credencial precargada - el precargado inicial `admin`/`admin` se eliminó cuando todos los servidores dejaron de crear esa cuenta por defecto en un primer arranque de producción real), `POST /api/login` contra la cuenta que introduzca el operador; se pueden crear cuentas adicionales de menor privilegio "operator" desde Config > Users en la interfaz web. Token de sesión persistido entre arranques vía `shared_preferences` - importante en un panel tipo kiosco que debe seguir con la sesión iniciada tras un ciclo de apagado/encendido de la propia CM5, no solo tras reabrir la app. Un diálogo de "Buscar en la red local" (`lib/network/discovery.dart`) encuentra servidores sin necesidad de conocer ya la IP - doblemente útil aquí, ya que la CM5 en la que corre esta app suele ser el propio controlador al que debe conectarse.
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
- **UI en 7 idiomas** (`lib/l10n/`, pipeline estándar `flutter gen-l10n`) - inglés, español, francés, alemán, italiano, japonés y chino, igualando al resto de clientes de este ecosistema. Un ajuste persistido en `Ajustes > Idioma` usa por defecto el idioma del sistema; `RobotViewModel.lastError` es un `HydraError` tipado en lugar de texto en inglés ya formateado, así que los mensajes de error de la lógica de negocio también se traducen correctamente, no solo el texto estático de las pantallas.

**Estado: scaffold + las 6 pantallas del catálogo implementadas y conectadas al contrato real REMOTE_API.md.** `flutter analyze` limpio, `flutter build windows` y `flutter build linux` (vía WSL2) producen ambos un binario en ejecución, `flutter test` pasa - ver "Compilación" más abajo para lo que sí se ha verificado y lo que no, incluyendo la brecha que queda entre esta verificación en WSL2 y el hardware real de la CM5.

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

**Nota de honestidad sobre la verificación en Linux:** `flutter build linux --release` ya se ha ejecutado de verdad contra este código, desde un entorno real de Ubuntu 24.04 en WSL2 con un toolchain de escritorio Linux real (`cmake`, `ninja-build`, `libgtk-3-dev`, `clang`) - compila limpio y produce un `build/linux/x64/release/bundle/hydra_umc_dsi` genuino, confirmado que realmente arranca (se ejecutó bajo una pantalla X11 real y se mantuvo vivo, no solo un código de salida en 0), no solo `flutter build windows` como sustituto de prueba de humo. Lo que esto **no** cubre: el userspace de WSL2 es x86_64, no el aarch64 real de la Raspberry Pi OS de la CM5, y el flujo de autoarranque de `kiosk/hydra-umc-dsi.service` sigue sin haberse ejecutado nunca en ninguna máquina Linux real. Ver la sección 7 de `docs/ARCHITECTURE.md` para la lista exacta de lo verificado y lo no verificado, y "Próximos Pasos Conocidos" más abajo para lo que queda pendiente.

## 🔢 Versionado

Este repositorio sigue una política ecosistema-wide (compartida con
[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL),
implementada allí en paralelo): la versión sube automáticamente en **cada
compilación real**, sin edición manual de la línea `version:` de
`pubspec.yaml`. `build.sh`/`build.bat`/`build_linux.sh` ejecutan
`tool/bump_version.dart` antes de invocar `flutter build`, aplicando:

- **Patch, estilo cuentakilómetros (base 10):** +1 en cada compilación; si
  superaría 9, se resetea a 0 y la minor sube +1 en su lugar - ejemplo:
  `0.0.9` -> `0.1.0`. La major nunca se toca automáticamente.
- **Build-number** (la parte tras el `+`): un contador monótono simple, +1
  en cada compilación, sin acarreo.

El mismo script regenera `lib/app_version.dart` (generado, no editado a
mano - un simple archivo `const`, no una nueva dependencia en tiempo de
ejecución como `package_info_plus`), que la app lee en tiempo de ejecución
para mostrar su propia versión en la pantalla de **Ajustes**. Ver
[CHANGELOG.md](CHANGELOG.md) para el historial de versiones.

### Ejecución en la CM5 real

Después de que `build_linux.sh` genere `build/linux/*/release/bundle/`, copia todo el directorio `bundle/` a la CM5 (depende de los archivos `.so` que están junto al binario, no solo del propio ejecutable) a `/opt/hydra-umc-dsi/bundle/`, y luego ejecuta `sudo kiosk/install_kiosk.sh` para instalar y activar `kiosk/hydra-umc-dsi.service`, una unidad systemd que lanza la app a pantalla completa en `tty1` vía [`cage`](https://github.com/cage-kiosk/cage) (un compositor kiosco Wayland mínimo que ejecuta exactamente un cliente a pantalla completa), con `Restart=always` para que un fallo relance la app en vez de dejar la pantalla en negro. Elegido frente a [`flutter-pi`](https://github.com/ardera/flutter-pi) (un embebedor de motor Flutter de terceros para Raspberry Pi que corre sin ningún gestor de ventanas) precisamente porque reutiliza sin modificar la salida real de `flutter build linux` que ya genera `build_linux.sh` - flutter-pi en cambio compila directamente contra el motor de Flutter, así que necesitaría su propio paso de compilación separado, no es un sustituto directo. **Nota de honestidad:** escrito y revisado, pero nunca ejecutado de verdad contra una CM5 real ni ninguna otra máquina Linux - a diferencia del propio `flutter build linux`, que ya está verificado bajo WSL2 (ver `docs/ARCHITECTURE.md` sección 7), este flujo de autoarranque del kiosco sigue completamente sin verificar. Ver el propio comentario de cabecera de `kiosk/hydra-umc-dsi.service` para las asunciones exactas (usuario root del servicio, propiedad de `tty1`) que habría que comprobar contra la imagen de Raspberry Pi OS real que use la CM5.

## 🗺️ Próximos Pasos Conocidos

Carencias reales y verificadas que el código de esta app todavía tiene - no son TODOs vagos, cada una se puede rastrear a un punto concreto del código o de la documentación anterior:

- **El interruptor de acceso remoto todavía no es independiente** - la sección 1 de `REMOTE_API.md` solo reconoce `suite`, `android` e `ios` como valores de `X-Hydra-Client`; esta app envía `dsi`, un valor no reconocido que hoy no se filtra nunca, así que sus peticiones de descubrimiento pasan sin control alguno. Arreglarlo requiere añadir un 4º interruptor al propio tipo `SystemSettings.remoteAccess` de HYDRA-UMC-STUDIO y a su pestaña Config > Remote Access - un cambio en el código de servidor de otro repositorio, fuera del alcance de este. Ver la sección 3 de `docs/ARCHITECTURE.md`.
- **La vista 3D no tiene un renderizador 3D nativo real** - `ui/three_d_screen.dart` dibuja hoy un pequeño indicador isométrico de posición X/Y/Z en lugar de incrustar la escena real de Three.js de STUDIO (`webview_flutter` no tiene implementación en Linux - ver la sección 4 de `docs/ARCHITECTURE.md` para el razonamiento completo). Un renderizador 3D nativo real para esta pantalla es trabajo futuro, aún no iniciado.
- **Aún falta una ejecución real en hardware de la CM5** - el propio `flutter build linux` ya está verificado (toolchain real de Ubuntu 24.04 en WSL2, binario confirmado que arranca de verdad - ver la sección 7 de `docs/ARCHITECTURE.md`), pero el flujo completo de `build_linux.sh` y la unidad de autoarranque `kiosk/hydra-umc-dsi.service` siguen sin haberse ejecutado nunca contra la propia CM5 ni contra ninguna otra máquina Linux real (no-WSL2). Quien las ejecute allí por primera vez debería tratarlo como el primer despliegue real en hardware de esta plataforma, no como un formalismo - ver "Ejecución en la CM5 real" más arriba.

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
│   │   ├── robot_view_model.dart    # Único ChangeNotifier que escucha cada pantalla
│   │   └── hydra_error.dart         # Superficie de error tipada para RobotViewModel (sin BuildContext propio)
│   ├── services/
│   │   └── backlight.dart           # Retroiluminación adaptativa según la hora del día
│   ├── l10n/                        # Localizaciones reales generadas (7 idiomas) - ver l10n.yaml en la raíz del repo
│   │   ├── app_localizations.dart   # Clase base generada
│   │   ├── app_localizations_en.dart, _es.dart, _it.dart, _fr.dart, _de.dart, _ja.dart, _zh.dart
│   │   └── language_prefs.dart      # Override de idioma persistido (shared_preferences)
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
├── tools/
│   └── ci_validate.py               # Validación de manifiesto/CHANGELOG/docs usada por CI
├── bump_manifest_version.py          # Sincroniza la versión de hydra-umc.project.json con la nativa (--sync)
├── test/                             # widget_test, format_uptime_test, localization_test, robot_view_model_test
├── README.md                         # documento original (inglés)
└── README_spa.md / README_ita.md / README_fra.md / README_deu.md / README_zho.md / README_jpn.md  # traducciones
```

## 🔗 Proyectos Relacionados

Este proyecto es parte del ecosistema de robótica HYDRA-UMC del mismo autor (JuanenRac / Electro Hobby 3D). Vale la pena conocerlo, ya que una petición podría en realidad ser sobre alguno de estos en vez de sobre este repositorio.

**Proyecto Padre**
- **[HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)** — el backend headless real (REST/WebSocket) con el que habla de verdad cada cliente de control; el servidor con el que conecta este panel mediante el contrato real `REMOTE_API.md` (descubrimiento, inicio de sesión, comandos atómicos, sincronización WebSocket).

**Proyectos Hermanos** — también hablan con la propia API de HYDRA-UMC-SERVER, cada uno como su propio cliente
- **[HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — panel de control web con visualización 3D multi-robot en tiempo real.
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** — centro de mando de enjambre de escritorio (PySide6) para varios servidores a la vez, empaquetado como ejecutable independiente; habla exactamente el mismo contrato `REMOTE_API.md` que este panel.
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** — app nativa de control para Android con inicio de sesión biométrico y un compañero Wear OS emparejado; habla exactamente el mismo contrato `REMOTE_API.md` que este panel.
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — app de control para iOS/iPadOS (Flutter) con sincronización en tiempo real por WebSocket; habla exactamente el mismo contrato `REMOTE_API.md` que este panel, y de ella se portó el propio descubrimiento mDNS real de este panel.
- **[HYDRA-UMC-BRIDGE-AMR](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-AMR)** — barrera de coordinación para flotas AGV/AMR mediante un publicador MQTT VDA 5050 real.
- **[HYDRA-UMC-BRIDGE-CNC](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-CNC)** — coordinador de alto nivel para celdas CNC con acceso real a estado/bytes de control GRBL.
- **[HYDRA-UMC-BRIDGE-DROIDS](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-DROIDS)** — barrera de coordinación para droides con patas/humanoides, con un emisor de comandos real para Boston Dynamics Spot.
- **[HYDRA-UMC-BRIDGE-LASER](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-LASER)** — coordinador de seguridad para celdas láser que lee 3 salvaguardas GPIO reales de llave/carcasa/enclavamiento.
- **[HYDRA-UMC-BRIDGE-OPENPNP](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-OPENPNP)** — coordinador de alto nivel seguro para el flujo de placas de pick-and-place OpenPnP.
- **[HYDRA-UMC-BRIDGE-PRINTER3D](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-PRINTER3D)** — barrera de coordinación segura para impresoras 3D Moonraker/Klipper, con comandos de trabajo reales y controlados.
- **[HYDRA-UMC-BRIDGE-ROS2](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-ROS2)** — coordinador de seguridad con un transporte ROS 2 rclpy real, importado de forma perezosa.
- **[HYDRA-UMC-BRIDGE-UAV](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-UAV)** — barrera de coordinación para UAV equipados con cámara, con un emisor de comandos MAVLink real.

**Directamente Relacionados**
- **[HYDRA-UMC-WATCH](https://github.com/JuanenRac/HYDRA-UMC-WATCH)** — app compañera de WearOS con alertas hápticas reales y un relé de voz al teléfono emparejado; el dispositivo de alerta de seguridad vestible que complementa a este panel táctil, llevando avisos a la muñeca del operador además de la propia pantalla de la placa.
- **[HYDRA-UMC-COGNITIVE-NODE](https://github.com/JuanenRac/HYDRA-UMC-COGNITIVE-NODE)** — nodo de integración para el pipeline cognitivo Hailo-10 (orquestación de LLM/VLA/voz); añade control por voz directamente en este panel táctil.
- **[HYDRA-UMC-VOICE-UI](https://github.com/JuanenRac/HYDRA-UMC-VOICE-UI)** — front-end de voz real (VAD + analizador de intención) con un relé a Watch acotado y con confirmación; añade control por voz directamente en este panel táctil.

**También Forma Parte del Ecosistema**

*Hardware y Plataforma Base*
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** — la placa madre física del brazo robótico: host CM5 + coprocesador STM32H745 de doble núcleo, coordinando hasta 8 brazos herramienta por CAN-OTA/SPI-OTA.
- **[HYDRA-UMC-OS](https://github.com/JuanenRac/HYDRA-UMC-OS)** — capa de producto reproducible sobre Raspberry Pi OS para el CM5: agente de solo lectura, config/perfiles validados, aprovisionamiento WiFi de primer contacto.
- **[HYDRA-UMC-SDK](https://github.com/JuanenRac/HYDRA-UMC-SDK)** — el contrato JSON-Schema compartido y la barrera de seguridad contra la que cada bridge valida sus comandos.

*Backend Central y Clientes*
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** — creador/editor gráfico de URDF de escritorio que envía los modelos terminados al propio catálogo de STUDIO.

*Plataforma de Herramientas URTC*
- **[URTC](https://github.com/JuanenRac/URTC)** — firmware para la placa física del Universal Robot Tool Controller, más de 25 perfiles de herramienta por bus CAN.
- **[URTC-FLASHER](https://github.com/JuanenRac/URTC-FLASHER)** — herramienta de escritorio con GUI para flashear placas URTC, CAN-OTA más SWD/JTAG de chip completo.
- **[URTC-TESTER](https://github.com/JuanenRac/URTC-TESTER)** — herramienta de escritorio de diagnóstico CAN-bus en vivo para placas URTC, un panel por perfil de herramienta.
- **[URTC-WEB-STUDIO](https://github.com/JuanenRac/URTC-WEB-STUDIO)** — alternativa basada en navegador a URTC-TESTER mediante la Web Serial API, sin instalación local.

*Nodo IA de Visión (Hailo-8)*
- **[HYDRA-UMC-VISION-NODE](https://github.com/JuanenRac/HYDRA-UMC-VISION-NODE)** — nodo de integración para el pipeline de visión Hailo-8, con una comprobación real de disponibilidad de hardware por etapa.
- **[HYDRA-UMC-DETECTION-HEF](https://github.com/JuanenRac/HYDRA-UMC-DETECTION-HEF)** — registro real de modelos compilados con verificación de carga segura por arquitectura Hailo/checksum.
- **[HYDRA-UMC-VISION-STREAMER](https://github.com/JuanenRac/HYDRA-UMC-VISION-STREAMER)** — generador real de pipeline GStreamer + config MediaMTX, con una frontera de integración HailoRT real.
- **[HYDRA-UMC-VISUAL-SERVOING-API](https://github.com/JuanenRac/HYDRA-UMC-VISUAL-SERVOING-API)** — ley de corrección real de Position-Based Visual Servoing, con puerta de seguridad según el estado de zona previo.
- **[HYDRA-UMC-SAFETY-ZONES](https://github.com/JuanenRac/HYDRA-UMC-SAFETY-ZONES)** — comprobación real de invasión de zona y solicitud de E-STOP, con exigencia de vigencia de calibración.

*Nodo IA Cognitivo (Hailo-10)*
- **[HYDRA-UMC-VLA-ENGINE](https://github.com/JuanenRac/HYDRA-UMC-VLA-ENGINE)** — codificación/decodificación real de tokens de acción y generación de trayectoria para un modelo Vision-Language-Action.
- **[HYDRA-UMC-SEMANTIC-PLANNER](https://github.com/JuanenRac/HYDRA-UMC-SEMANTIC-PLANNER)** — descomposición real de tareas basada en reglas y recuperación semántica de errores sobre códigos de error del MCU.
- **[HYDRA-UMC-DOCS-QA](https://github.com/JuanenRac/HYDRA-UMC-DOCS-QA)** — búsqueda real de documentos TF-IDF (solo librería estándar) sobre los propios documentos Markdown de este ecosistema.

*Orquestación y Enjambre*
- **[HYDRA-UMC-ORCHESTRATOR](https://github.com/JuanenRac/HYDRA-UMC-ORCHESTRATOR)** — nodo de integración con un contrato real de informe de salud gRPC/Protobuf y una máquina de estados de misión.
- **[HYDRA-UMC-JOB-DISPATCHER](https://github.com/JuanenRac/HYDRA-UMC-JOB-DISPATCHER)** — cola de trabajos real basada en prioridad con deduplicación, sobre una API HTTP real.
- **[HYDRA-UMC-NODE-HEALING](https://github.com/JuanenRac/HYDRA-UMC-NODE-HEALING)** — watchdog de salud de flota real basado en gRPC, con reintento/backoff y detección de discrepancia de identidad.
- **[HYDRA-UMC-PATH-PLANNER-3D](https://github.com/JuanenRac/HYDRA-UMC-PATH-PLANNER-3D)** — planificador de rutas 3D real basado en RRT, con validación real de colisión de obstáculos/espacio de trabajo.
- **[HYDRA-UMC-SWARM-SYNC](https://github.com/JuanenRac/HYDRA-UMC-SWARM-SYNC)** — sincronización de estado real mediante CRDT LWW-Element-Map, con pruebas de propiedades para convergencia multi-celda.

*Gemelo Digital y Simulación*
- **[HYDRA-UMC-TWIN](https://github.com/JuanenRac/HYDRA-UMC-TWIN)** — nodo de integración para el motor de gemelo digital, con un contrato real de sincronización por compatibilidad de versión.
- **[HYDRA-UMC-HIL-BRIDGE](https://github.com/JuanenRac/HYDRA-UMC-HIL-BRIDGE)** — enclavamiento de seguridad real hardware-in-the-loop que enruta comandos entre simulación y hardware real.
- **[HYDRA-UMC-PHYSICS-REPLICA](https://github.com/JuanenRac/HYDRA-UMC-PHYSICS-REPLICA)** — cinemática directa real y validación de límites articulares sobre un subconjunto real de URDF.
- **[HYDRA-UMC-SYNTHETIC-DATA-GEN](https://github.com/JuanenRac/HYDRA-UMC-SYNTHETIC-DATA-GEN)** — generador real de escenas 2D procedurales con exportación de anotaciones YOLO/COCO.

*Datos y Analítica*
- **[HYDRA-UMC-DATALAKE](https://github.com/JuanenRac/HYDRA-UMC-DATALAKE)** — almacén de series temporales real respaldado por sqlite3, con una API HTTP real de ingesta/consulta.
- **[HYDRA-UMC-ANOMALY-DETECTOR](https://github.com/JuanenRac/HYDRA-UMC-ANOMALY-DETECTOR)** — detector de anomalías real basado en FFT + línea base estadística, con monitorización de deriva.
- **[HYDRA-UMC-PRODUCTION-REPORTS](https://github.com/JuanenRac/HYDRA-UMC-PRODUCTION-REPORTS)** — cálculo real de OEE/disponibilidad sobre el histórico de DATALAKE, con exportación CSV reproducible.
- **[HYDRA-UMC-TELEMETRY-COLLECTOR](https://github.com/JuanenRac/HYDRA-UMC-TELEMETRY-COLLECTOR)** — pipeline real de ingesta CAN/WebSocket hacia DATALAKE, con deduplicación por secuencia.

*Pasarela Industrial*
- **[HYDRA-UMC-GATEWAY-INDUSTRIAL](https://github.com/JuanenRac/HYDRA-UMC-GATEWAY-INDUSTRIAL)** — nodo de integración que retransmite a protocolos industriales, con una capa real de lista blanca de comandos/contrapresión.
- **[HYDRA-UMC-OPCUA-SERVER](https://github.com/JuanenRac/HYDRA-UMC-OPCUA-SERVER)** — espacio de direcciones OPC-UA real, verificado con una sesión de cliente real del protocolo binario.
- **[HYDRA-UMC-MQTT-BROKER](https://github.com/JuanenRac/HYDRA-UMC-MQTT-BROKER)** — broker MQTT real con autenticación por cliente opcional y ACL de tópicos.
- **[HYDRA-UMC-MTCONNECT-ADAPTER](https://github.com/JuanenRac/HYDRA-UMC-MTCONNECT-ADAPTER)** — endpoints XML reales `/probe` y `/current` de MTConnect, con salida en modo degradado.

*Herramientas Complementarias y Operaciones del Ecosistema*
- **[HYDRA-UMC-DASHBOARD-AI](https://github.com/JuanenRac/HYDRA-UMC-DASHBOARD-AI)** — paneles de Resúmenes Inteligentes y Resaltado de Anomalías sobre DATALAKE/ANOMALY-DETECTOR, con un respaldo estadístico honesto.
- **[HYDRA-UMC-TOOL-CLI](https://github.com/JuanenRac/HYDRA-UMC-TOOL-CLI)** — CLI de flota con un contrato real y estable de códigos de salida, cliente real y en vivo de la propia API de HYDRA-UMC-SERVER.
- **[URTC-SMART-RACK](https://github.com/JuanenRac/URTC-SMART-RACK)** — firmware para un rack de montaje de placas con decodificación real de ID de herramienta y lógica de precalentamiento Smart Idle.
- **[URTC-VISION-TOOL](https://github.com/JuanenRac/URTC-VISION-TOOL)** — firmware más un compañero de visión real en Python para un cabezal de inspección térmica/RGB.
- **[HYDRA-UMC-UPDATER](https://github.com/JuanenRac/HYDRA-UMC-UPDATER)** — herramienta administrativa de escritorio que descubre, clona y actualiza cada repositorio de este ecosistema.
- **[HYDRA-UMC-OS-REBUILDER](https://github.com/JuanenRac/HYDRA-UMC-OS-REBUILDER)** — herramienta de escritorio Windows/Linux que construye una imagen de la CM5 lista para grabar, precargada con las versiones más actuales del ecosistema, con configuración de primer arranque de Wi-Fi/usuario/SSH al estilo de Raspberry Pi Imager.

---

## 📚 Documentación y Comunidad

- **[CONTRIBUTING.md](CONTRIBUTING.md)** — stack tecnológico y pautas de codificación para un pull request.
- **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** — los estándares de comportamiento esperados en esta comunidad.
- **[SECURITY.md](SECURITY.md)** — cómo reportar una vulnerabilidad, y las áreas reales de enfoque en seguridad de este proyecto.
- **[SUPPORT.md](SUPPORT.md)** — dónde hacer preguntas y reportar errores.
- **[LICENSE.md](LICENSE.md)** — la licencia propia de este proyecto.

## 👤 AUTOR
**JuanenRac** (Electro Hobby 3D)
📧 electrohobby3d@gmail.com
📺 [youtube.com/@electrohobby3d](https://youtube.com/@electrohobby3d)

## 📜 LICENCIA

Licencia Pública General de GNU v3.0 (GPL-3.0) para el código fuente - ver [`LICENSE`](LICENSE).

La documentación (este README y sus traducciones - `README_spa.md`, `README_ita.md`, `README_fra.md`, `README_deu.md`, `README_zho.md`, `README_jpn.md`) está disponible bajo **Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)**. Texto completo en https://creativecommons.org/licenses/by-sa/4.0/.
