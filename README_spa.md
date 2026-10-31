<!-- =============================================================================
HYDRA-UMC-DSI - Native touch UI for the CM5 DSI screen
Copyright (C) JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
GPL-3.0-or-later - see LICENSE
============================================================================= -->

<p align="center">
  <img src="images/HYDRA_UMC_BANNER.svg" alt="HYDRA-UMC-DSI banner" width="100%">
</p>

# 🖥️ HYDRA-UMC-DSI

<p align="center"><a href="README.md">🇺🇸 English</a> | 🇪🇸 <b>Español</b> | <a href="README_fra.md">🇫🇷 Français</a> | <a href="README_ita.md">🇮🇹 Italiano</a> | <a href="README_deu.md">🇩🇪 Deutsch</a> | <a href="README_zho.md">🇨🇳 简体中文</a> | <a href="README_jpn.md">🇯🇵 日本語</a> | <a href="README_por.md">🇵🇹 Português</a></p>

### Una interfaz táctil nativa para la pantalla DSI del Compute Module 5

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

Una interfaz táctil nativa en Flutter (Dart, con target real de escritorio Linux) para la pantalla táctil DSI de 5"/7" del propio HYDRA-UMC en la Compute Module 5 - los dos tamaños físicos del panel comparten exactamente la misma resolución de 1280x720 píxeles, así que esta app usa un único layout fijo, no responsive, en vez de adaptarse a dos tamaños. Habla exactamente el mismo contrato [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-SERVER/blob/main/docs/REMOTE_API.md) que usan [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE), [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) y [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) - descubrimiento, login, comandos atómicos por robot y sincronización en vivo por WebSocket contra un servidor [HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER) en ejecución, corriendo directamente en la propia placa en vez de en una pestaña de navegador. Ver [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) para el diseño completo, incluyendo por qué Flutter (y no Kivy) y por qué la pantalla 3D no usa un WebView.

**Esta app es una de las dos vías de control que coexisten en la misma placa** - la CM5 también lleva una salida HDMI para un monitor externo completo que ejecuta la interfaz web. Esta app DSI complementa esa vía con una consola táctil directa y siempre disponible en la propia placa; no sustituye a la interfaz web.

---

**Comprobación de honestidad - qué funciona realmente hoy:** la capa de red (`lib/network/hydra_api_client.dart`, `hydra_websocket.dart`, `discovery.dart`, `auth_prefs.dart`) y la capa de estado (`lib/state/robot_view_model.dart`, `hydra_error.dart`) son reales y están testeadas (208 tests pasando en `test/*.dart`, incluyendo un round-trip real de conexión/reconexión/rechazo de autenticación por WebSocket contra un servidor local genuino, no un mock), y `flutter analyze` no reporta ningún problema. Las 6 pantallas del catálogo son UI real y cableada, no placeholders. Lo que genuinamente no está construido: la pantalla **3D View** es un pequeño indicador isométrico nativo X/Y/Z, no un renderizador 3D real - no incrusta la escena Three.js de STUDIO (no existe implementación de `webview_flutter` para Linux). Lo que es real pero no verificado en el hardware objetivo: `flutter build linux --release` se ha ejecutado y produce un binario confirmado que arranca, pero solo bajo Ubuntu 24.04 WSL2 (x86_64) - nunca en el aarch64 real de Raspberry Pi OS de la CM5 - y la unidad de autoarranque `kiosk/hydra-umc-dsi.service` nunca se ha ejecutado en ninguna máquina Linux real. Ver "Known Follow-ups" más abajo y `CHANGELOG.md` para lo que se ha entregado exactamente hasta ahora.

> **Estado de seguridad física y de ciberseguridad:** este ecosistema no es un sistema de seguridad certificado. Todavía no existe una ruta de E-STOP por hardware, ni límites ni enclavamientos aplicados por el firmware, ni un comando de movimiento verificado; las imágenes de firmware se comprueban con CRC-32 y una firma Ed25519, y una compilación de versión rechaza las claves de desarrollo publicadas (los cabezales de herramienta y las placas de expansión detrás del relé siguen con cargadores de URTC, que usan un HMAC-SHA256 de clave compartida en lugar de una firma); TLS y TLS mutuo son opcionales y están desactivados por defecto; aún no se ha poblado ni probado ninguna placa propia. Lee la [línea base de seguridad](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/SECURITY_BASELINE.md) y el [modelo de amenazas](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/THREAT_MODEL.md) antes de fiarte de cualquier afirmación de aquí para la seguridad de una persona.

---

## 📋 De un vistazo

| | |
|---|---|
| Versión | `0.2.8` |
| Madurez | Funcional |
| Tests | 208 (`flutter test`) |
| Tecnología | Flutter 3.x / Dart |
| Destino | La Raspberry Pi CM5 de una celda HYDRA-UMC |
| En hardware real | Todavía no: no consta ninguna ejecución en hardware real para esta versión |

**Ir a:** [Resumen](#-resumen) · [Arquitectura](#-arquitectura) · [Inicio rápido](#-inicio-rápido) · [Pruebas](#-pruebas) · [Estructura del repositorio](#-estructura-del-repositorio) · [Proyectos relacionados](#-proyectos-relacionados)

## 🚦 Estado del proyecto

Cada línea es una parte de este repositorio y la luz dice hasta dónde llega hoy. Se escribe con lo que el repositorio puede demostrar (pruebas, compilaciones, ejecuciones), no con lo previsto.

🟢 Hecho y verificado · 🟡 Funciona, con límites conocidos · 🟠 Hecho a medias o sin verificar · 🔴 Sin hacer o sin funcionar

| Área | Estado | Qué significa aquí |
|---|---|---|
| Software | 🟡 | Funciona para su propósito principal; la comprobación de honestidad de arriba lista lo que aún falta |
| Pruebas | 🟢 | 208 pruebas automáticas, ejecutadas en cada cambio |
| Hardware real | 🔴 | Todavía no: no consta ninguna ejecución en hardware real para esta versión |
| Documentación | 🟢 | README en ocho idiomas, comprobado contra el manifiesto en cada cambio |

## 🎯 Resumen

- **Login** (`lib/ui/login_screen.dart`, `lib/state/robot_view_model.dart`) - campos de IP/puerto del servidor precargados con un valor de LAN razonable, campos de usuario/contraseña dimensionados para uso táctil y vacíos por defecto (sin ninguna credencial precargada - el precargado inicial `admin`/`admin` se eliminó cuando todos los servidores dejaron de crear esa cuenta por defecto en un primer arranque de producción real), `POST /api/login` contra la cuenta que introduzca el operador; se pueden crear cuentas adicionales de menor privilegio "operator" desde Config > Users en la interfaz web. El token de sesión se guarda en el almacén seguro de la plataforma (libsecret en Linux, que necesita un servicio de llavero en marcha: en un panel sin él la sesión dura hasta reiniciar la app y se vuelve a pedir el inicio de sesión). Un diálogo de "Buscar en la red local" (`lib/network/discovery.dart`) encuentra servidores sin necesidad de conocer ya la IP - doblemente útil aquí, ya que la CM5 en la que corre esta app suele ser el propio controlador al que debe conectarse.
- **Descubrimiento de red** (`lib/network/discovery.dart`) - dos vías en paralelo desde el mismo diálogo "Scan local network": mDNS/Bonjour real (`discoverMdns()`, consultando el propio servicio `_hydra._tcp` que publica `server.ts` vía el paquete `multicast_dns`) y un escaneo concurrente por fuerza bruta de `GET /api/hydra-info` en las subredes locales reales de este dispositivo (`scanSubnets()`), deduplicado por host:puerto - portado desde HYDRA-UMC-IOS-CONTROL, el primer cliente del ecosistema en añadir mDNS real.
- **Sincronización atómica de comandos** (`lib/state/robot_view_model.dart`, su propio `_sendAtomicCommand()`) - cada escritura (play/pause/stop/jog/valve/pump/speed/vision) usa el endpoint real `POST /api/robot/:id/command`, con la propagación correcta a robots combinados (`combinedWith`) y una reversión al estado previo si la petición falla - especialmente importante para un mando de jog/E-STOP situado a pocos metros de los robots reales.
- **Sincronización en vivo por WebSocket** (`lib/network/hydra_websocket.dart`) - envía el token como subprotocolo `hydra.bearer` y nunca en la dirección, gestiona los tipos de difusión `"settings"` y `"delta"`, reconecta automáticamente si se cae la conexión.
- **Navegación táctil horizontal** (`lib/ui/main_screen.dart`) - una barra superior persistente con 6 pestañas grandes de icono+etiqueta (Dashboard/Control/Cámara/Vista 3D/Métricas/Ajustes) a lo ancho del marco fijo de 1280px, en el espíritu de KlipperScreen en vez de una barra inferior estilo móvil - siguiendo el catálogo que pidió el dueño del proyecto, reorganizado para un panel táctil ancho en vez de un layout vertical de móvil.
- **Dashboard** (`lib/ui/dashboard_screen.dart`) - tarjetas por robot, reactivas en tiempo real vía `Provider`, convención de LED (verde parpadeante = activo, rojo fijo = inactivo), indicación de robots combinados y chips de módulos (CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK) - el mismo lenguaje visual que el resto de clientes de este ecosistema.
- **Control Manual** (`lib/ui/control_screen.dart`, `lib/ui/widgets/joystick_pad.dart`) - layout lado a lado (mando de jog a la izquierda, telemetría/velocidad/E-S a la derecha) dimensionado para el marco de 1280x720 en vez de una única columna con scroll, el **STOP** global (`lib/ui/widgets/stop_all.dart`) en la barra superior de cada pestaña, también en la de Control y en la superposición de limpieza de pantalla: una pulsación, sin pulsación larga ni confirmación, para todos los robots (`POST /api/stop-all`), muestra el resultado robot a robot (aviso si un robot falló o la parada no se guardó, robots reservados por otra cuenta marcados), reintenta una vez ante un error de red, recurre a la parada por robot ante un 429 o un servidor antiguo, y mantiene un aviso permanente «STOP no confirmado» hasta que un STOP posterior obtenga respuesta (el botón redondo de parada por robot conserva su protección de pulsación larga), deslizadores de velocidad/aceleración, interruptores de válvulas/bombas.
- **Reservas y límites de seguridad** (`lib/ui/widgets/access_panel.dart`, `lib/models/access.dart`, `lib/network/hydra_api_client.dart`, `lib/state/robot_view_model.dart`) - La pantalla de Control muestra quién tiene el robot seleccionado (nadie, este dispositivo, la misma cuenta en otro dispositivo u otra cuenta) y ofrece **Reservar** y **Liberar**, además de la lista de todas las reservas del servidor (`GET /api/claims`). El dispositivo guarda un identificador de controlador por instalación y lo envía con cada reserva, liberación, armado del jog y comando (en el cuerpo y en la cabecera `X-Controller-Id`), de modo que la reserva pertenece a la cuenta y a este dispositivo, no a toda la cuenta. Las negativas del servidor se distinguen: reservado por otra cuenta, por tu cuenta en otro dispositivo o ventana, falta el identificador de controlador y jog sin armar. Los límites del modelo del robot se leen de `GET /api/safety-limits`: un paso de jog por encima del límite no se envía y se muestran los avisos del servidor. Cuando el administrador lo exige, hay que pulsar **Armar jog** (con cuenta atrás) antes de que el joystick mueva el robot; el armado termina solo, con STOP o al liberar. Las reservas son opcionales: un robot que nadie reservó se controla como antes. Solo para un **administrador**, aparece un botón **Tomar el control** sobre un robot que tiene otra persona; pide confirmación y luego reserva el robot con `force: true` (el servidor solo lo admite de administradores y vuelve a comprobar el rol). Las escrituras son condicionales: cada una lleva la revisión del robot que esta app vio por última vez (`If-Match`, `lib/models/contract_v2.dart`) y, si otra persona cambió el robot entretanto, el servidor responde 412, no se aplica nada, el robot se vuelve a leer y el mensaje lo dice (Estándar comprueba reservas, mesa y comandos puntuales; Estricto comprueba todo salvo STOP; Desactivado no comprueba nada; la elección está en la lista de reservas; STOP nunca se comprueba). El jog de la mesa XY es un único comando atómico `table` (un servidor antiguo recibe los jogs que entiende), el servidor empuja las reservas por el WebSocket para que la pantalla Control deje de consultar mientras llegan, y los administradores leen el registro de auditoría (`lib/ui/widgets/audit_dialog.dart`) con su cadena SHA-256 verificada dos veces, por el servidor y en el equipo, y pueden copiar sus líneas como `.jsonl`.
- **Preguntar antes de PLAY** - activado por defecto, se desactiva en Ajustes: antes de empezar una trayectoria la app muestra el robot, sus puntos grabados, la velocidad y quién lo tiene reservado (un robot reservado por otra persona avisa de que el servidor rechazará la orden). Un robot que ya está reproduciendo no vuelve a preguntar. La elección se conserva.
- **Cámara** (`lib/ui/camera_screen.dart`, `lib/ui/widgets/mjpeg_view.dart`) - el mismo parser de MJPEG hecho a mano y sin dependencias que usa HYDRA-UMC-IOS-CONTROL (sin WebView, sin código específico de plataforma - funciona en escritorio Linux sin cambios), un estado claro de "Cámara Desactivada" y un interruptor para activar/desactivar la visión de un robot directamente desde el servidor.
- **Vista 3D** (`lib/ui/three_d_screen.dart`) - **no** es un WebView incrustando la escena real Three.js de STUDIO, a diferencia de las apps de iOS/Android - `webview_flutter` no tiene ninguna implementación para escritorio Linux, y un motor de navegador completo supone una carga en tiempo de ejecución mayor de la que necesita este panel empotrado de bajo consumo. En su lugar: un pequeño indicador nativo isométrico de posición X/Y/Z (`CustomPainter`, sin motor 3D), con un aviso en pantalla que señala la escena 3D real en el monitor conectado por HDMI a esta misma placa. Ver la sección 4 de `docs/ARCHITECTURE.md` para el razonamiento completo.
- **Métricas del Sistema** (`lib/ui/metrics_screen.dart`) - su propia pestaña dedicada (no integrada en el Dashboard como hacen iOS/Android) con paneles de CPU/memoria/temperatura/tiempo activo desde `GET /api/system/metrics`, más nombre de host/número de controladores/número de robots/versión de la app desde `GET /api/hydra-info`.
- **Ajustes** (`lib/ui/settings_screen.dart`) - información de conexión, identidad del servidor, cierre de sesión y la propia versión de esta app (ver [Versionado](#versionado) más abajo).
- **Arranque automático en kiosco** (`kiosk/hydra-umc-dsi.service`, `kiosk/install_kiosk.sh`) - unidad systemd que lanza la app a pantalla completa en `tty1` vía `cage`, con `Restart=always`. Ver "Ejecución en la CM5 real" más abajo. Una sola pantalla local a la vez: el instalador instala la app solo cuando el ajuste `HYDRA_LOCAL_SCREEN` vale `dsi` (`sudo kiosk/install_kiosk.sh --screen dsi` lo guarda en `/etc/hydra-umc/local-screen.conf`); el valor por defecto es `hdmi`, el kiosco HDMI de HYDRA-UMC-OS, y `none` no deja `tty1` a nadie, de modo que los dos kioscos nunca reclaman `tty1` a la vez. Aún no se ha ejecutado en una CM5 real.
- **UI en 8 idiomas** (`lib/l10n/`, pipeline estándar `flutter gen-l10n`) - inglés, español, francés, alemán, italiano, japonés, chino y portugués, igualando al resto de clientes de este ecosistema. Un ajuste persistido en `Ajustes > Idioma` usa por defecto el idioma del sistema; `RobotViewModel.lastError` es un `HydraError` tipado en lugar de texto en inglés ya formateado, así que los mensajes de error de la lógica de negocio también se traducen correctamente, no solo el texto estático de las pantallas.

**Estado: scaffold + las 6 pantallas del catálogo implementadas y conectadas al contrato real REMOTE_API.md.** `flutter analyze` limpio, `flutter build windows` y `flutter build linux` (vía WSL2) producen ambos un binario en ejecución, `flutter test` pasa - ver "Compilación" más abajo para lo que sí se ha verificado y lo que no, incluyendo la brecha que queda entre esta verificación en WSL2 y el hardware real de la CM5.

## 🧩 Papel en HYDRA-UMC

**HYDRA-UMC-DSI** es la pantalla táctil de la propia CM5: una aplicación nativa de Flutter para el panel DSI de 5"/7" que habla con `HYDRA-UMC-SERVER` por su interfaz REST y WebSocket, junto a la interfaz de navegador de `HYDRA-UMC-STUDIO`. No tiene lógica de robots propia; el servidor decide qué se permite.

## 🏛️ Arquitectura

<p align="center">
  <img src="images/architecture.svg" alt="HYDRA-UMC-DSI architecture" width="100%">
</p>

## 🚀 Inicio rápido

Requiere el SDK estable de Flutter (3.x) con soporte de escritorio Linux.

```bash
flutter pub get
./run_dev.sh      # desktop simulation, no hardware (run_dev.bat on Windows)
./build_linux.sh  # on a Linux machine or the CM5: the real target
```

## 🧪 Pruebas

208 pruebas automáticas se ejecutan con `flutter test`. No necesitan hardware ni nada fuera de esta máquina.

El CI ejecuta `HYDRA_UMC_CI=1 python tools/ci_validate.py`, que comprueba el manifiesto, los documentos, los ocho README y las imágenes.

## 🏗️ Compilación y publicación

Requiere el [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal stable). Este repositorio se compila/verifica contra Flutter 3.47.0. Solo `linux/` y `windows/` están configurados como plataformas en este repositorio (sin carpetas `android/`, `ios/`, `web/` ni `macos/`) - Linux es el target real (el propio sistema operativo de la CM5); Windows existe únicamente para poder compilar, ejecutar y probar la lógica de esta app en una máquina sin toolchain de Linux.

### Scripts de compilación

```bash
./build.sh          # Git Bash / WSL, o build.bat para cmd/PowerShell - flutter pub get + flutter build windows (verificación en máquina de desarrollo)
./build_linux.sh    # Debe ejecutarse EN una máquina Linux real (o la propia CM5) - flutter pub get + flutter build linux (el target real de despliegue)
./run_dev.sh         # Git Bash / WSL, o run_dev.bat para cmd/PowerShell - modo de simulación de escritorio (flutter run), sin necesitar el hardware
```

Los 3 scripts de compilación (`build.sh`/`build.bat`/`build_linux.sh`) no cambian la versión de la app - ver [Versionado](#versionado) más abajo. `run_dev.sh`/`run_dev.bat` no lo hacen - un `flutter run` de ciclo de desarrollo no es una "compilación real" bajo esa política.

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

### Versionado

Este repositorio sigue una política a nivel de ecosistema: compilar nunca cambia la versión. El comando `bump` explícito (`python tools/hydra_project_tool.py bump`) ejecuta `bump_manifest_version.py`, que sube la versión de `pubspec.yaml` (el número de compilación tras `+` es un contador monotónico simple, +1 en cada bump, sin acarreo) y mantiene el manifiesto sincronizado. También regenera `lib/app_version.dart` (generado, no editado a mano), que la app lee en tiempo real para mostrar su propia versión en la pantalla de **Ajustes**. Ver [CHANGELOG.md](CHANGELOG.md) para el historial de versiones.

## 📂 Estructura del repositorio

<p align="center">
  <img src="images/repository-structure.svg" alt="Repository structure of HYDRA-UMC-DSI" width="100%">
</p>

<details>
<summary>Versión en texto del árbol</summary>

```text
HYDRA-UMC-DSI/
├── lib/                                                              código fuente
│   ├── main.dart                                                     Punto de entrada, ChangeNotifierProvider + puerta de login, tema oscuro fijo
│   ├── app_version.dart                                              GENERADO - regenerado por bump_manifest_version.py, no editar a mano
│   ├── models/                                                       modelos de datos y reglas puras
│   ├── network/                                                      cliente REST, WebSocket y descubrimiento
│   ├── state/                                                        el estado que escucha cada pantalla
│   ├── services/                                                     servicios de la aplicación (retroiluminación)
│   ├── l10n/                                                         localizaciones en ocho idiomas
│   ├── util/                                                         Utilidades sin pantalla propia
│   └── ui/                                                           pantallas y widgets
├── kiosk/                                                            unidad de quiosco y su instalador
├── linux/                                                            Runner de escritorio GTK - el target REAL, ventana fija 1280x720
├── windows/                                                          Runner de escritorio Windows - solo verificación en máquina de desarrollo
├── tools/                                                            herramientas del proyecto y comprobaciones del CI
├── test/                                                             widget_test, format_uptime_test, localization_test, robot_view_model_test, robot_view_model_silent_refresh_test, auth_prefs_test, hydra_websocket_test, hostile_answers_test, hydra_error_test, play_confirmation_test, stop_long_press_test
├── .github/                                                          flujo de CI y plantillas de incidencias
├── images/                                                           banner e imágenes del README
├── build.bat / build.sh                                              flutter pub get + incremento de versión + flutter build windows (verificación en máquina de desarrollo)
├── build_linux.sh                                                    flutter pub get + flutter build linux (el target real de la CM5 - ejecutar en Linux real)
├── run_dev.bat / run_dev.sh                                          flutter run - modo de simulación de escritorio
├── CHANGELOG.md                                                      qué cambió en cada versión
├── docs/ARCHITECTURE.md                                              arquitectura del proyecto
├── bump_manifest_version.py                                          Sincroniza la versión de hydra-umc.project.json con la nativa (--sync)
├── pubspec.yaml / pubspec.lock / l10n.yaml / analysis_options.yaml   La definición del paquete Flutter y sus versiones fijadas, los ajustes del generador de l10n y las reglas de lint
├── build-test.sh                                                     comprobación de compilación sin cambios
├── hydra-umc.project.json                                            manifiesto: versión, madurez, familia
└── test.sh                                                           ejecuta las pruebas
```

</details>

## 🗺️ Hoja de ruta y límites conocidos

**Límites conocidos hoy**

Carencias reales y verificadas que el código de esta app todavía tiene - no son TODOs vagos, cada una se puede rastrear a un punto concreto del código o de la documentación anterior:

- **El interruptor de acceso remoto todavía no es independiente** - la sección 1 de `REMOTE_API.md` solo reconoce `suite`, `android` e `ios` como valores de `X-Hydra-Client`; esta app envía `dsi`, un valor no reconocido que hoy no se filtra nunca, así que sus peticiones de descubrimiento pasan sin control alguno. Arreglarlo requiere añadir un 4º interruptor al propio tipo `SystemSettings.remoteAccess` de HYDRA-UMC-STUDIO y a su pestaña Config > Remote Access - un cambio en el código de servidor de otro repositorio, fuera del alcance de este. Ver la sección 3 de `docs/ARCHITECTURE.md`.
- **La vista 3D no tiene un renderizador 3D nativo real** - `ui/three_d_screen.dart` dibuja hoy un pequeño indicador isométrico de posición X/Y/Z en lugar de incrustar la escena real de Three.js de STUDIO (`webview_flutter` no tiene implementación en Linux - ver la sección 4 de `docs/ARCHITECTURE.md` para el razonamiento completo). Un renderizador 3D nativo real para esta pantalla es trabajo futuro, aún no iniciado.
- **Aún falta una ejecución real en hardware de la CM5** - el propio `flutter build linux` ya está verificado (toolchain real de Ubuntu 24.04 en WSL2, binario confirmado que arranca de verdad - ver la sección 7 de `docs/ARCHITECTURE.md`), pero el flujo completo de `build_linux.sh` y la unidad de autoarranque `kiosk/hydra-umc-dsi.service` siguen sin haberse ejecutado nunca contra la propia CM5 ni contra ninguna otra máquina Linux real (no-WSL2). Quien las ejecute allí por primera vez debería tratarlo como el primer despliegue real en hardware de esta plataforma, no como un formalismo - ver "Ejecución en la CM5 real" más arriba.

## 🌍 Idiomas

Este README y los documentos del repositorio existen en ocho idiomas: inglés, español, alemán, francés, italiano, japonés, chino y portugués (Portugal). Se escriben a la vez y el CI comprueba que los ocho ficheros tengan las mismas secciones y los mismos enlaces.

## 🔗 Proyectos relacionados

Este proyecto es parte del ecosistema de robótica HYDRA-UMC del mismo autor (JuanenRac / Electro Hobby 3D). Vale la pena conocerlo, ya que una petición podría en realidad ser sobre alguno de estos en vez de sobre este repositorio.

**Proyecto Padre**
- **[HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)** — el backend headless real (REST/WebSocket) con el que habla de verdad cada cliente de control; el servidor con el que conecta este panel mediante el contrato real `REMOTE_API.md` (descubrimiento, inicio de sesión, comandos atómicos, sincronización WebSocket).

**Proyectos Hermanos** — también hablan con la propia API de HYDRA-UMC-SERVER, cada uno como su propio cliente
- **[HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — panel de control web con visualización 3D multi-robot en tiempo real.
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** — centro de mando de enjambre de escritorio (PySide6) para varios servidores a la vez, empaquetado como ejecutable independiente; habla exactamente el mismo contrato `REMOTE_API.md` que este panel.
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** — app nativa de control para Android con inicio de sesión biométrico y un compañero Wear OS emparejado; habla exactamente el mismo contrato `REMOTE_API.md` que este panel.
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — app de control para iOS/iPadOS (Flutter) con sincronización en tiempo real por WebSocket; habla exactamente el mismo contrato `REMOTE_API.md` que este panel, y de ella se portó el propio descubrimiento mDNS real de este panel.
- **[HYDRA-UMC-BRIDGE-AMR](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-AMR)** — barrera de coordinación para flotas AGV/AMR mediante un publicador MQTT VDA 5050 (probado solo contra una flota emulada).
- **[HYDRA-UMC-BRIDGE-CNC](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-CNC)** — coordinador de alto nivel para celdas CNC con acceso a estado/bytes de control GRBL (probado solo contra un emulador).
- **[HYDRA-UMC-BRIDGE-DROIDS](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-DROIDS)** — barrera de coordinación para droides con patas/humanoides, con un emisor de comandos para Boston Dynamics Spot (probado solo contra un emulador).
- **[HYDRA-UMC-BRIDGE-LASER](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-LASER)** — coordinador de celdas láser que lee 3 señales GPIO de llave/carcasa/enclavamiento (probado solo contra un chip simulado; no puede armar ni disparar un láser).
- **[HYDRA-UMC-BRIDGE-OPENPNP](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-OPENPNP)** — coordinador de alto nivel seguro para el flujo de placas de pick-and-place OpenPnP.
- **[HYDRA-UMC-BRIDGE-PRINTER3D](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-PRINTER3D)** — barrera de coordinación segura para impresoras 3D Moonraker/Klipper, con comandos de trabajo reales y controlados.
- **[HYDRA-UMC-BRIDGE-ROS2](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-ROS2)** — coordinador con un transporte ROS 2 rclpy importado de forma perezosa (todavía no ejecutado contra una instalación de ROS 2).
- **[HYDRA-UMC-BRIDGE-UAV](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-UAV)** — barrera de coordinación para UAV equipados con cámara, con un emisor de comandos MAVLink (probado solo contra un emulador).

**Directamente Relacionados**
- **[HYDRA-UMC-WATCH](https://github.com/JuanenRac/HYDRA-UMC-WATCH)** — app compañera de WearOS con patrones de alerta háptica y un relé de voz al teléfono emparejado (todavía no ejecutada en un reloj físico); el dispositivo de alerta de seguridad vestible que complementa a este panel táctil, llevando avisos a la muñeca del operador además de la propia pantalla de la placa.
- **[HYDRA-UMC-COGNITIVE-NODE](https://github.com/JuanenRac/HYDRA-UMC-COGNITIVE-NODE)** — nodo de integración para el pipeline cognitivo Hailo-10 (orquestación de LLM/VLA/voz); añade control por voz directamente en este panel táctil.
- **[HYDRA-UMC-VOICE-UI](https://github.com/JuanenRac/HYDRA-UMC-VOICE-UI)** — front-end de voz real (VAD + analizador de intención) con un relé a Watch acotado y con confirmación; añade control por voz directamente en este panel táctil.
- **[HYDRA-UMC-LOCAL-TECHNICIAN](https://github.com/JuanenRac/HYDRA-UMC-LOCAL-TECHNICIAN)** — técnico de mantenimiento con IA local y con puertas de política para el propio ecosistema - observa, diagnostica y propone arreglos; los dos niveles de riesgo más altos están deliberadamente sin implementar todavía.

**También Forma Parte del Ecosistema**

*Hardware y Plataforma Base*
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** — el diseño de la placa madre del brazo robótico: host CM5 + coprocesador STM32H745 de doble núcleo, pensado para coordinar hasta 8 brazos herramienta por CAN-OTA/SPI-OTA (firmware en fase temprana; todavía no hay ninguna placa poblada).
- **[HYDRA-UMC-OS](https://github.com/JuanenRac/HYDRA-UMC-OS)** — capa de producto reproducible sobre Raspberry Pi OS para el CM5: agente de solo lectura, config/perfiles validados, aprovisionamiento WiFi de primer contacto.
- **[HYDRA-UMC-SDK](https://github.com/JuanenRac/HYDRA-UMC-SDK)** — el contrato JSON-Schema compartido y la barrera de software de puerta de trabajos contra la que cada bridge valida sus comandos (no es una función de seguridad certificada).
- **[HYDRA-UMC-CONNECTOR-HUB](https://github.com/JuanenRac/HYDRA-UMC-CONNECTOR-HUB)** — registro declarativo y validador de manifiestos de adaptador para conectores de máquinas externas; extiende la propia idea de contrato del SDK a máquinas externas sin sustituir a los proyectos de pasarela industrial.

*Backend Central y Clientes*
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** — creador/editor gráfico de URDF de escritorio que envía los modelos terminados al propio catálogo de STUDIO.
- **[HYDRA-UMC-EDITOR-STL](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-STL)** — editor de escritorio de modelos STL, que transforma/reemplaza/quita/añade piezas reales en el mismo catálogo de modelos que también edita HYDRA-UMC-EDITOR-URDF.

*Plataforma de Herramientas URTC*
- **[URTC](https://github.com/JuanenRac/URTC)** — firmware para la placa física del Universal Robot Tool Controller, más de 25 perfiles de herramienta por bus CAN.
- **[URTC-FLASHER](https://github.com/JuanenRac/URTC-FLASHER)** — herramienta de escritorio con GUI para flashear placas URTC, CAN-OTA más SWD/JTAG de chip completo.
- **[URTC-TESTER](https://github.com/JuanenRac/URTC-TESTER)** — herramienta de escritorio de diagnóstico CAN-bus en vivo para placas URTC, un panel por perfil de herramienta.
- **[URTC-WEB-STUDIO](https://github.com/JuanenRac/URTC-WEB-STUDIO)** — alternativa basada en navegador a URTC-TESTER mediante la Web Serial API, sin instalación local.
- **[URTC-GATEWAY](https://github.com/JuanenRac/URTC-GATEWAY)** — pasarela delante del bus CAN de URTC: lista de identificadores permitidos, límite de tasa y clave de sesión; software probado en ordenador, aún no en un bus real.

*Nodo IA de Visión (Hailo-8)*
- **[HYDRA-UMC-VISION-NODE](https://github.com/JuanenRac/HYDRA-UMC-VISION-NODE)** — nodo de integración para el pipeline de visión Hailo-8, con una comprobación real de disponibilidad de hardware por etapa.
- **[HYDRA-UMC-DETECTION-HEF](https://github.com/JuanenRac/HYDRA-UMC-DETECTION-HEF)** — registro real de modelos compilados con verificación de carga segura por arquitectura Hailo/checksum.
- **[HYDRA-UMC-VISION-STREAMER](https://github.com/JuanenRac/HYDRA-UMC-VISION-STREAMER)** — generador real de pipeline GStreamer + config MediaMTX, con una frontera de integración HailoRT real.
- **[HYDRA-UMC-VISUAL-SERVOING-API](https://github.com/JuanenRac/HYDRA-UMC-VISUAL-SERVOING-API)** — ley de corrección Position-Based Visual Servoing con autorización condicionada al estado de zona; todavía sin estimación de pose por cámara.
- **[HYDRA-UMC-SAFETY-ZONES](https://github.com/JuanenRac/HYDRA-UMC-SAFETY-ZONES)** — lógica v0 de invasión de zona, vigencia de calibración y solicitud de E-STOP que toma las posiciones de los objetos de un fichero; ningún detector la alimenta y todavía no hay un E-STOP físico conectado.

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
- **[HYDRA-UMC-HIL-BRIDGE](https://github.com/JuanenRac/HYDRA-UMC-HIL-BRIDGE)** — enrutador hardware-in-the-loop con un enclavamiento de software por colisión entre simulación y hardware real (probado sin hardware real).
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
- **[HYDRA-UMC-OPS-AGENT](https://github.com/JuanenRac/HYDRA-UMC-OPS-AGENT)** — coordinador de incidencias de mantenimiento: un rol edge de bajo privilegio recopila un snapshot de inventario/salud saneado, un rol control-plane lo renderiza de solo lectura y pide a un proveedor de IA que sugiera un diagnóstico - nunca aplica un parche ni despliega nada.
- **[HYDRA-UMC-DEV-SERVER](https://github.com/JuanenRac/HYDRA-UMC-DEV-SERVER)** — host de desarrollo reproducible (Raspberry Pi 5 / CM5) que almacena el código del ecosistema y ejecuta tareas acotadas de compilación/pruebas bajo una cola duradera; un rol de desarrollo dedicado, explícitamente distinto de un CM5 operativo.

## 📚 Documentación

Dónde leer más:

* [Base de seguridad del ecosistema](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/SECURITY_BASELINE.md)
* [Modelo de amenazas del ecosistema](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/THREAT_MODEL.md)
* [Historial de cambios de este repositorio](CHANGELOG.md)
* [Licencia de este repositorio](LICENSE.md)

## 🤝 Contribuir y comunidad

* Antes de un pull request ejecuta `HYDRA_UMC_CI=1 py -3 tools/ci_validate.py` (o `HYDRA_UMC_CI=1 python3 tools/ci_validate.py`): debe imprimir `CI_VALIDATION=PASS`. No ejecutes `build.sh` ni `build.bat` para esta comprobación; compilar no es comprobar.
* Los ocho README se escriben desde una sola fuente en HYDRA-UMC-DOCS; no los edites a mano. Cambia la fuente y vuelve a escribirlos con `tools/make_readmes.py`.
* No afirmes en un README lo que no se ha ejecutado: di «simulado» o «sin probar en hardware» cuando esa sea la verdad.
* Mira [CONTRIBUTING.md](CONTRIBUTING.md), el [código de conducta](CODE_OF_CONDUCT.md), [SECURITY.md](SECURITY.md) y [SUPPORT.md](SUPPORT.md).

## 👤 AUTOR

**JuanenRac (Electro Hobby 3D)** · electrohobby3d@gmail.com

## 📜 LICENCIA

GPL-3.0-or-later - [LICENSE](LICENSE).
