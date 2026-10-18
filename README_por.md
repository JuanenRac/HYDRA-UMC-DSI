<p align="center">
  <img src="images/HYDRA_UMC_BANNER.svg" alt="HYDRA-UMC-DSI banner" width="100%">
</p>
# 🖥️ HYDRA-UMC DSI

<p align="center">
  <a href="README.md">🇺🇸 English</a> |
  <a href="README_spa.md">🇪🇸 Español</a> |
  <a href="README_fra.md">🇫🇷 Français</a> |
  <a href="README_ita.md">🇮🇹 Italiano</a> |
  <a href="README_deu.md">🇩🇪 Deutsch</a> |
  <a href="README_zho.md">🇨🇳 简体中文</a> |
  <a href="README_jpn.md">🇯🇵 日本語</a> |
  🇵🇹 <b>Português</b>
</p>


<p align="center">
  <img src="https://img.shields.io/badge/License-GPL%203.0--or--later-blue.svg" alt="GPL 3.0 or later">
  <img src="https://img.shields.io/badge/Framework-Flutter%203.x-02569B.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Language-Dart-0175C2.svg" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20CM5-E34F26.svg" alt="Platform">
</p>


Uma interface tátil Flutter nativa (Dart, alvo real de desktop Linux) para o ecrã tátil DSI de 5"/7" do próprio HYDRA-UMC no Compute Module 5 - os dois tamanhos físicos de painel partilham exatamente a mesma resolução de 1280x720 píxeis, pelo que esta aplicação traz um único esquema fixo e não responsivo em vez de se adaptar a dois tamanhos. Fala exatamente o mesmo contrato [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-SERVER/blob/main/docs/REMOTE_API.md) que o [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE), o [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) e o [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) usam - descoberta, início de sessão, comandos atómicos por robô e sincronização WebSocket em direto contra um servidor [HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO) em execução, correndo diretamente na própria placa e não num separador do navegador. Veja [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) para o desenho completo, incluindo porque é Flutter (e não Kivy) e porque é que o ecrã 3D não é uma WebView.

**Esta aplicação é uma de duas superfícies de controlo que coexistem na mesma placa** - o CM5 também alimenta uma saída HDMI para um monitor externo completo que corre a interface do navegador. Esta aplicação DSI complementa esse caminho com uma consola tátil direta e sempre ligada na própria placa; não substitui a interface do navegador.

---

**Verificação de honestidade - o que realmente funciona hoje:** a camada de rede (`lib/network/hydra_api_client.dart`, `hydra_websocket.dart`, `discovery.dart`, `auth_prefs.dart`) e a camada de estado (`lib/state/robot_view_model.dart`, `hydra_error.dart`) são reais e estão testadas (72 testes a passar em `test/*.dart`, incluindo uma volta real de ligação/religação/rejeição de autenticação por WebSocket contra um servidor local genuíno, não um simulado), e o `flutter analyze` não reporta problemas. Os 6 ecrãs do catálogo são interface real e ligada, não marcadores de posição. O que genuinamente não está construído: o ecrã **Vista 3D** é um pequeno indicador isométrico X/Y/Z nativo, não um renderizador 3D real - não embebe a cena Three.js do STUDIO (não existe nenhuma implementação de `webview_flutter` para Linux). O que é real mas não está verificado no hardware de destino: o `flutter build linux --release` foi executado e produz um binário cujo arranque está confirmado, mas apenas em Ubuntu 24.04 WSL2 (x86_64) - nunca no Raspberry Pi OS aarch64 real do CM5 - e a unidade de arranque automático `kiosk/hydra-umc-dsi.service` nunca correu em nenhuma máquina Linux real. Veja "Seguimentos conhecidos" abaixo e o `CHANGELOG.md` para saber exatamente o que foi entregue até agora.

## 📋 Num relance

| | |
|---|---|
| Versão | `0.2.4` |
| Maturidade | Estabelecido |
| Testes | 72 |
| Tecnologia | Flutter 3.x / Dart |
| Destino | O Raspberry Pi CM5 de uma célula HYDRA-UMC |
| Em hardware real | Ainda não: não há registo de execução em hardware real para esta versão |

## 🏗️ O que está implementado

- **Início de sessão** (`lib/ui/login_screen.dart`, `lib/state/robot_view_model.dart`) - campos de IP/porta do servidor pré-preenchidos com um valor de LAN sensato, campos de utilizador/palavra-passe dimensionados para toque e deixados em branco por omissão (nenhuma credencial fixa vem pré-preenchida - o pré-preenchimento inicial `admin`/`admin` foi retirado quando todos os servidores passaram a recusar criar essa conta por omissão no primeiro arranque real de produção), `POST /api/login` contra a conta que o operador introduzir; podem criar-se contas de "operador" com menos privilégios em Config > Users na interface do navegador. O token de sessão fica no armazenamento seguro da plataforma (libsecret no Linux, que exige um serviço de porta-chaves em execução: num painel sem ele a sessão dura até reiniciar a aplicação e o início de sessão volta a ser pedido). Um diálogo "Procurar na rede local" (`lib/network/discovery.dart`) encontra servidores sem ser preciso conhecer já o IP - duplamente útil aqui, já que o CM5 em que esta aplicação corre é muitas vezes o próprio controlador a que se deve ligar.
- **Descoberta de rede** (`lib/network/discovery.dart`) - dois caminhos correm em paralelo a partir do mesmo diálogo "Procurar na rede local": mDNS/Bonjour real (`discoverMdns()`, que consulta a publicação `_hydra._tcp` do próprio `server.ts` através do pacote `multicast_dns`) e uma pesquisa concorrente por força bruta de `GET /api/hydra-info` na(s) sub-rede(s) local(is) real(is) deste dispositivo (`scanSubnets()`), desduplicada por anfitrião:porta - portada do HYDRA-UMC-IOS-CONTROL, o primeiro cliente deste ecossistema a acrescentar descoberta mDNS real.
- **Sincronização atómica de comandos** (o próprio `_sendAtomicCommand()` de `lib/state/robot_view_model.dart`) - cada escrita (ativar/desativar/play/pausa/stop/jog/válvula/bomba/velocidade/visão) usa o endpoint real `POST /api/robot/:id/command`, com propagação correta de robôs combinados (`combinedWith`) e uma reversão para o instantâneo anterior à mutação se o pedido falhar - especialmente importante para um pendente de jog/E-STOP a poucos metros dos robôs reais.
- **Sincronização WebSocket em direto** (`lib/network/hydra_websocket.dart`) - anexa sempre `?token=`, trata os dois tipos de difusão `"settings"` e `"delta"` e volta a ligar-se automaticamente quando cai.
- **Navegação tátil horizontal** (`lib/ui/main_screen.dart`) - uma barra superior persistente de 6 separadores grandes de ícone+etiqueta (Painel/Controlo/Câmara/Vista 3D/Métricas/Definições) ao longo dos 1280px fixos de largura, no espírito do KlipperScreen e não uma barra de navegação inferior ao estilo de telemóvel - de acordo com o catálogo que o dono do projeto pediu, reorganizado para um painel tátil largo em vez de um esquema vertical de telemóvel.
- **Painel** (`lib/ui/dashboard_screen.dart`) - cartões por robô, reativos em tempo real através de `Provider`, convenção de LED (verde a pulsar = ativo, vermelho fixo = inativo), apresentação de robôs combinados e chips de módulo (CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK) - a mesma linguagem visual de todos os outros clientes deste ecossistema.
- **Controlo manual** (`lib/ui/control_screen.dart`, `lib/ui/widgets/joystick_pad.dart`) - esquema lado a lado (teclado de jog à esquerda, telemetria/velocidade/E-S à direita) dimensionado para o quadro de 1280x720 em vez de uma única coluna com deslocação, o **STOP** global (`lib/ui/widgets/stop_all.dart`) na barra superior de cada separador, também no de Controlo e na sobreposição de limpeza do ecrã: um só toque, sem pressão longa nem confirmação, pára todos os robôs (`POST /api/stop-all`), mostra o resultado robô a robô (aviso se um robô falhou ou a paragem não foi guardada, robôs reservados por outra conta assinalados), repete uma vez após um erro de rede, recorre à paragem por robô perante um 429 ou um servidor mais antigo e mantém um aviso permanente «STOP não confirmado» até um STOP posterior obter resposta (o botão redondo de paragem por robô mantém a sua proteção de pressão longa), controlos deslizantes de velocidade/aceleração e interruptores de válvula/bomba.
- **Câmara** (`lib/ui/camera_screen.dart`, `lib/ui/widgets/mjpeg_view.dart`) - o mesmo analisador de fluxo MJPEG feito à mão e sem dependências que o HYDRA-UMC-IOS-CONTROL (sem WebView, sem código específico de plataforma - funciona sem alterações em desktop Linux), um estado claro de "Câmara desativada" e um interruptor para ligar/desligar o sistema de visão de um robô diretamente a partir do servidor.
- **Vista 3D** (`lib/ui/three_d_screen.dart`) - **não** é uma WebView com a cena Three.js real do STUDIO, ao contrário das aplicações iOS/Android - o `webview_flutter` não tem qualquer implementação para desktop Linux, e um motor de navegador completo é uma carga de execução mais pesada do que este painel embebido de baixo consumo precisa. Em vez disso: um pequeno indicador isométrico nativo de posição X/Y/Z (`CustomPainter`, sem motor 3D), com uma nota no ecrã que aponta para a cena 3D real no monitor ligado por HDMI desta mesma placa. Veja `docs/ARCHITECTURE.md`, secção 4, para o raciocínio completo.
- **Métricas do sistema** (`lib/ui/metrics_screen.dart`) - o seu próprio separador dedicado (não integrado no Painel como fazem o iOS/Android) com mosaicos de CPU/memória/temperatura/tempo ativo a partir de `GET /api/system/metrics`, mais nome do anfitrião/número de controladores/número de robôs/versão da aplicação a partir de `GET /api/hydra-info`.
- **Definições** (`lib/ui/settings_screen.dart`) - informação da ligação, identidade do servidor, terminar sessão e a versão desta própria aplicação (veja [Versionamento](#-versionamento) abaixo).
- **Arranque automático em quiosque** (`kiosk/hydra-umc-dsi.service`, `kiosk/install_kiosk.sh`) - unidade systemd que lança a aplicação em ecrã inteiro no `tty1` através do `cage`, com `Restart=always`. Veja "Execução no CM5 real" abaixo.
- **Interface em 8 idiomas** (`lib/l10n/`, pipeline padrão `flutter gen-l10n`) - inglês, espanhol, francês, alemão, italiano, japonês, chinês e português, a par de todos os outros clientes deste ecossistema. Uma substituição persistente em `Definições > Idioma` assume por omissão o idioma do sistema operativo; `RobotViewModel.lastError` é um `HydraError` tipado e não texto inglês já formatado, pelo que as mensagens de erro da lógica de negócio também ficam localizadas, e não apenas o aspeto estático dos ecrãs.

**Estado: estrutura base + os 6 ecrãs do catálogo implementados e ligados ao contrato real do REMOTE_API.md.** `flutter analyze` limpo, `flutter build windows` e `flutter build linux` (via WSL2) produzem ambos um binário que arranca, `flutter test` passa - veja "Compilação" abaixo para saber exatamente o que foi e não foi verificado, incluindo a lacuna que resta entre esta verificação em WSL2 e o hardware CM5 real.

## 🚀 Compilação

Requer o [SDK do Flutter](https://docs.flutter.dev/get-started/install) (canal stable). Este repositório é compilado/verificado com o Flutter 3.47.0. Só `linux/` e `windows/` estão configurados como plataformas neste repositório (sem pastas `android/`, `ios/`, `web/` nem `macos/`) - o Linux é o alvo real (o próprio sistema operativo do CM5); o Windows existe apenas para que a lógica desta aplicação possa ser compilada, executada e testada numa máquina sem cadeia de ferramentas Linux.

### Scripts de compilação

```bash
./build.sh          # Git Bash / WSL, ou build.bat para cmd/PowerShell - flutter pub get + subida de versão + flutter build windows (verificação na máquina de desenvolvimento)
./build_linux.sh    # Tem de correr NUM Linux real (ou no próprio CM5) - flutter pub get + subida de versão + flutter build linux (o alvo de implementação real)
./run_dev.sh         # Git Bash / WSL, ou run_dev.bat para cmd/PowerShell - modo de simulação de desktop (flutter run), sem hardware
```

Os 3 scripts de compilação (`build.sh`/`build.bat`/`build_linux.sh`) sobem primeiro a versão da aplicação - veja [Versionamento](#-versionamento) abaixo. `run_dev.sh`/`run_dev.bat` não o fazem - um `flutter run` do ciclo de desenvolvimento não é uma "compilação real" segundo essa política.

### Compilação manual

```bash
flutter pub get
flutter analyze                  # análise estática - sem necessidade de compilador
flutter test                     # testes de widgets
dart run tool/bump_version.dart  # sobe a versão, tal como o build.sh/build.bat/build_linux.sh fazem
flutter build windows            # teste rápido na máquina de desenvolvimento - produz build/windows/x64/runner/Release/hydra_umc_dsi.exe
flutter build linux              # o alvo REAL - tem de correr num Linux real, produz build/linux/*/release/bundle/
flutter run -d windows           # ou -d linux num Linux real, para um ciclo de desenvolvimento com simulação de desktop em direto
```

**Nota de honestidade sobre a verificação em Linux:** o `flutter build linux --release` foi já realmente executado contra este código, a partir de um ambiente Ubuntu 24.04 WSL2 real com uma cadeia de ferramentas de desktop Linux real (`cmake`, `ninja-build`, `libgtk-3-dev`, `clang`) - compila limpo e produz um `build/linux/x64/release/bundle/hydra_umc_dsi` genuíno, cujo arranque está confirmado (correu sob um ecrã X11 real e manteve-se vivo, não apenas um código de saída a passar), e não apenas o `flutter build windows` como substituto do teste rápido. O que isto **não** cobre: o espaço de utilizador do WSL2 é x86_64, não o Raspberry Pi OS aarch64 real do CM5, e o fluxo de arranque automático de `kiosk/hydra-umc-dsi.service` continua a nunca ter corrido em nenhuma caixa Linux real. Veja `docs/ARCHITECTURE.md`, secção 7, para a lista exata do que foi e não foi verificado, e "Seguimentos conhecidos" abaixo para o que falta.

## 🔢 Versionamento

Este repositório segue uma política válida em todo o ecossistema (partilhada com o
[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL),
implementada lá em paralelo): a versão sobe automaticamente em
**cada compilação real**, sem edição manual da linha `version:` do
`pubspec.yaml`. O `build.sh`/`build.bat`/`build_linux.sh` executam `tool/bump_version.dart`
antes de invocar o `flutter build`, aplicando:

- **Patch, ao estilo conta-quilómetros (base 10):** +1 em cada compilação; quando
  passaria de 9 volta a 0 e o minor sobe +1 em vez disso - por exemplo `0.0.9` ->
  `0.1.0`. O major nunca é tocado automaticamente.
- **Número de compilação** (a parte depois de `+`): um contador monótono simples,
  +1 em cada compilação, sem transporte.

O mesmo script regenera `lib/app_version.dart` (gerado, não
editado à mão - um ficheiro `const` simples, não uma nova dependência de execução como
`package_info_plus`), que a aplicação lê em execução para mostrar a sua própria
versão no ecrã **Definições**. Veja o [CHANGELOG.md](CHANGELOG.md) para o
histórico de versões.

### Execução no CM5 real

Depois de o `build_linux.sh` produzir `build/linux/*/release/bundle/`, copie todo o diretório `bundle/` para o CM5 (depende dos ficheiros `.so` junto ao binário, não apenas do executável) para `/opt/hydra-umc-dsi/bundle/` e depois execute `sudo kiosk/install_kiosk.sh` para instalar e ativar o `kiosk/hydra-umc-dsi.service`, uma unidade systemd que lança a aplicação em ecrã inteiro no `tty1` através do [`cage`](https://github.com/cage-kiosk/cage) (um compositor Wayland de quiosque mínimo que executa exatamente um cliente em ecrã inteiro), com `Restart=always` para que uma falha volte a lançá-la em vez de deixar um ecrã em branco. Escolhido em vez do [`flutter-pi`](https://github.com/ardera/flutter-pi) (um embebedor de motor Flutter de terceiros, direto sobre o hardware, para Raspberry Pi, que corre sem qualquer sistema de janelas) precisamente porque reutiliza sem alterações a saída real do `flutter build linux` do `build_linux.sh` - o flutter-pi compila diretamente contra o motor do Flutter, pelo que precisaria do seu próprio passo de compilação separado, não de um encaixe sobre a compilação que este repositório já produz. **Nota de honestidade:** escrito e revisto, nunca executado contra um CM5 real nem qualquer outra caixa Linux - ao contrário do próprio `flutter build linux`, agora verificado em WSL2 (veja `docs/ARCHITECTURE.md`, secção 7), este fluxo de arranque automático em quiosque continua inteiramente por verificar. Veja o comentário de cabeçalho do próprio `kiosk/hydra-umc-dsi.service` para os pressupostos exatos (utilizador de serviço root, posse do `tty1`) que teriam de ser confirmados contra a imagem de Raspberry Pi OS que o CM5 realmente executa. **O quiosque HDMI real e implementado no CM5 real hoje é o `provisioning/install_kiosk.sh` do próprio HYDRA-UMC-OS** (X11 mínimo + Chromium, verificado em hardware real) - instalar o quiosque baseado em `cage` desta aplicação no mesmo dispositivo disputaria o `tty1` com ele. Ninguém decidiu que esta aplicação nativa substitui o quiosque Chromium; verifique primeiro que esta realmente corre e pare o outro quiosque antes de alguma vez ativar os dois.

## 🗺️ Seguimentos conhecidos

Lacunas reais e verificadas que o código desta aplicação ainda tem - não TODOs vagos, cada uma rastreável a um local concreto do código ou da documentação acima:

- **O interruptor de acesso remoto ainda não é independente** - a secção 1 do `REMOTE_API.md` só reconhece `suite`, `android` e `ios` como valores de `X-Hydra-Client`; esta aplicação envia `dsi`, um valor não reconhecido que nunca é limitado, pelo que os seus pedidos de descoberta passam hoje sem restrições. Corrigir isto exige acrescentar um 4.º interruptor ao próprio tipo `SystemSettings.remoteAccess` do HYDRA-UMC-STUDIO e ao separador Config > Remote Access - uma alteração ao código de servidor desse repositório, fora do âmbito deste. Veja `docs/ARCHITECTURE.md`, secção 3.
- **A Vista 3D não tem um renderizador 3D nativo real** - `ui/three_d_screen.dart` desenha atualmente um pequeno indicador isométrico de posição X/Y/Z em vez de embeber a cena Three.js real do STUDIO (o `webview_flutter` não tem implementação para Linux - veja `docs/ARCHITECTURE.md`, secção 4, para o raciocínio completo). Um renderizador 3D nativo real para este ecrã é trabalho futuro, ainda não iniciado.
- **Falta ainda uma execução em hardware CM5 real** - o próprio `flutter build linux` está agora verificado (cadeia de ferramentas Ubuntu 24.04 WSL2 real, arranque do binário confirmado - veja `docs/ARCHITECTURE.md`, secção 7), mas o fluxo completo do `build_linux.sh` e a unidade de arranque automático `kiosk/hydra-umc-dsi.service` continuam a nunca ter corrido contra o CM5 real nem qualquer outra máquina Linux real (não WSL2). Quem os executar aí pela primeira vez deve tratá-lo como a primeira implementação real em hardware deste alvo de plataforma, não como uma formalidade - veja "Execução no CM5 real" acima.

## 📂 Estrutura do repositório

```text
HYDRA-UMC-DSI/
├── build.bat, build.sh              # flutter pub get + subida de versão + flutter build windows (verificação na máquina de desenvolvimento)
├── build_linux.sh                   # flutter pub get + subida de versão + flutter build linux (o alvo CM5 real - executar num Linux real)
├── run_dev.bat, run_dev.sh          # flutter run - modo de simulação de desktop
├── CHANGELOG.md                      # histórico de versões (veja Versionamento acima)
├── kiosk/
│   ├── hydra-umc-dsi.service        # unidade systemd - arranque automático em ecrã inteiro através do cage
│   └── install_kiosk.sh             # instala e ativa a unidade acima (executar no CM5 real)
├── tool/
│   └── bump_version.dart            # Script de subida de versão que o build.bat/build.sh/build_linux.sh executam antes de cada compilação (veja Versionamento acima)
├── lib/
│   ├── main.dart                    # Ponto de entrada da aplicação, ChangeNotifierProvider + porta de início de sessão, tema escuro fixo
│   ├── app_version.dart             # GERADO - regenerado por tool/bump_version.dart, não editar à mão
│   ├── models/
│   │   ├── server_info.dart         # Entrada de descoberta/ligação - espelha o ServerInfo dos outros 3 clientes
│   │   ├── hydra_state.dart         # RobotView/ControllerView/HydraState - vistas mutáveis finas sobre a árvore bruta do settings.json
│   │   └── stop_all_result.dart    # resposta do STOP global, robô a robô
│   ├── network/
│   │   ├── hydra_api_client.dart    # REST: início de sessão, definições, comando atómico de robô, métricas do sistema - X-Hydra-Client: dsi
│   │   ├── hydra_websocket.dart     # Cliente de sincronização em direto /ws
│   │   ├── discovery.dart           # Pesquisa concorrente da(s) sub-rede(s) local(is) real(is) deste dispositivo
│   │   └── auth_prefs.dart          # Ligação + token persistidos (secure storage + shared_preferences)
│   ├── state/
│   │   ├── robot_view_model.dart    # Único ChangeNotifier que todos os ecrãs escutam
│   │   └── hydra_error.dart         # Superfície de erros tipados do RobotViewModel (sem BuildContext próprio)
│   ├── services/
│   │   └── backlight.dart           # Retroiluminação adaptativa consoante a hora do dia
│   ├── l10n/                        # Localizações geradas reais (8 idiomas) - veja l10n.yaml na raiz do repositório
│   │   ├── app_localizations.dart   # Classe base gerada
│   │   ├── app_localizations_en.dart, _es.dart, _it.dart, _fr.dart, _de.dart, _ja.dart, _zh.dart, _pt.dart
│   │   └── language_prefs.dart      # Substituição de idioma persistida (shared_preferences)
│   └── ui/
│       ├── login_screen.dart        # Campos de anfitrião/porta/utilizador/palavra-passe + "Procurar na rede local"
│       ├── main_screen.dart         # Barra de navegação tátil horizontal (6 separadores) - no espírito do KlipperScreen
│       ├── dashboard_screen.dart    # Cartões por robô + barra de métricas do sistema
│       ├── control_screen.dart      # Controlos de jog/velocidade/válvula/bomba/reprodução, esquema tátil lado a lado
│       ├── camera_screen.dart       # Visualizador MJPEG + interruptor de visão ligada/desligada
│       ├── three_d_screen.dart      # Indicador isométrico X/Y/Z nativo - NÃO é uma WebView (veja docs/ARCHITECTURE.md §4)
│       ├── metrics_screen.dart      # Separador dedicado de métricas do anfitrião CM5 + identidade do servidor
│       ├── settings_screen.dart     # Informação da ligação + terminar sessão + versão da própria aplicação
│       └── widgets/
│           ├── joystick_pad.dart     # D-pad de jog, ampliado para toque
│           ├── stop_all.dart            # botão STOP global e o seu aviso de resultado / «não confirmado»
│           ├── digital_readout.dart, status_led.dart
│           └── mjpeg_view.dart       # Analisador de fluxo MJPEG feito à mão
├── linux/                            # Executor GTK de desktop - o alvo REAL, janela fixa de 1280x720
├── windows/                          # Executor de desktop Windows - apenas verificação na máquina de desenvolvimento
├── docs/ARCHITECTURE.md
├── tools/
│   └── ci_validate.py               # Validação de manifesto/CHANGELOG/documentação usada pelo CI
├── bump_manifest_version.py          # Sincroniza a versão do hydra-umc.project.json com a nativa (--sync)
├── test/                             # widget_test, format_uptime_test, localization_test, robot_view_model_test, robot_view_model_silent_refresh_test, auth_prefs_test, hydra_websocket_test
├── README.md                         # este ficheiro
└── README_spa.md / README_ita.md / README_fra.md / README_deu.md / README_zho.md / README_jpn.md / README_por.md  # traduções
```

---

## 🔗 Projetos relacionados

Este projeto faz parte do ecossistema de robótica HYDRA-UMC do mesmo autor (JuanenRac / Electro Hobby 3D). Vale a pena conhecê-los, porque um pedido pode ser, na verdade, sobre um destes e não sobre este repositório.

**Projeto-mãe**
- **[HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)** — o back-end headless real (REST/WebSocket) com que todos os clientes de controlo realmente comunicam; o servidor a que este painel se liga através do contrato real `REMOTE_API.md` (descoberta, início de sessão, comandos atómicos, sincronização WebSocket).

**Projetos irmãos** — também falam com a API do próprio HYDRA-UMC-SERVER, cada um como cliente próprio
- **[HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — painel web de controlo com visualização 3D em tempo real de vários robôs.
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** — centro de comando de enxame para desktop (PySide6) para vários servidores ao mesmo tempo, empacotado como executável independente; fala exatamente o mesmo contrato `REMOTE_API.md` que este painel.
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** — aplicação Android nativa de controlo, com início de sessão biométrico e um companheiro Wear OS emparelhado; fala exatamente o mesmo contrato `REMOTE_API.md` que este painel.
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — aplicação de controlo para iOS/iPadOS (Flutter) com sincronização WebSocket em tempo real; fala exatamente o mesmo contrato `REMOTE_API.md` que este painel, e é de onde foi portada a descoberta mDNS real deste painel.
- **[HYDRA-UMC-BRIDGE-AMR](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-AMR)** — fronteira de coordenação para frotas AGV/AMR através de um publicador MQTT VDA 5050 real.
- **[HYDRA-UMC-BRIDGE-CNC](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-CNC)** — coordenador de células CNC de alto nível com acesso real ao estado GRBL e aos bytes de controlo.
- **[HYDRA-UMC-BRIDGE-DROIDS](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-DROIDS)** — fronteira de coordenação para droides com patas/humanoides, com um emissor real de comandos para o Boston Dynamics Spot.
- **[HYDRA-UMC-BRIDGE-LASER](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-LASER)** — coordenador de segurança de células laser que lê 3 proteções reais por GPIO (chave, caixa e interlock).
- **[HYDRA-UMC-BRIDGE-OPENPNP](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-OPENPNP)** — coordenador seguro de fluxo de placa de alto nível para pick-and-place com OpenPnP.
- **[HYDRA-UMC-BRIDGE-PRINTER3D](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-PRINTER3D)** — fronteira de coordenação segura para impressoras 3D Moonraker/Klipper, com comandos de trabalho reais protegidos por portas.
- **[HYDRA-UMC-BRIDGE-ROS2](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-ROS2)** — coordenador de segurança com um transporte ROS 2 real baseado em rclpy importado sob demanda.
- **[HYDRA-UMC-BRIDGE-UAV](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-UAV)** — fronteira de coordenação para UAV com câmara, com um emissor real de comandos MAVLink.

**Diretamente relacionados**
- **[HYDRA-UMC-WATCH](https://github.com/JuanenRac/HYDRA-UMC-WATCH)** — aplicação companheira WearOS com alertas hápticos reais e um relé de voz através do telemóvel emparelhado; o dispositivo vestível de alertas de segurança que complementa este painel tátil, levando os avisos ao pulso do operador além do ecrã da própria placa.
- **[HYDRA-UMC-COGNITIVE-NODE](https://github.com/JuanenRac/HYDRA-UMC-COGNITIVE-NODE)** — centro de integração do pipeline cognitivo do Hailo-10 (orquestração de LLM/VLA/voz); acrescenta controlo por voz diretamente neste painel tátil.
- **[HYDRA-UMC-VOICE-UI](https://github.com/JuanenRac/HYDRA-UMC-VOICE-UI)** — front-end de voz real (VAD + analisador de intenções) com um relé para o relógio limitado e protegido por confirmação; acrescenta controlo por voz diretamente neste painel tátil.
- **[HYDRA-UMC-LOCAL-TECHNICIAN](https://github.com/JuanenRac/HYDRA-UMC-LOCAL-TECHNICIAN)** — técnico de manutenção de IA local, protegido por políticas, para o próprio ecossistema: observa, diagnostica e propõe correções; os dois níveis de maior risco não estão implementados de propósito.

**Também fazem parte do ecossistema**

*Hardware e plataforma centrais*
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** — a placa-mãe física do braço robótico: anfitrião CM5 + STM32H745 de dois núcleos, que orquestra até 8 braços de ferramenta por CAN-OTA/SPI-OTA.
- **[HYDRA-UMC-OS](https://github.com/JuanenRac/HYDRA-UMC-OS)** — camada de produto reproduzível do Raspberry Pi OS para o CM5: agente só de leitura, configuração/perfis validados, aprovisionamento Wi-Fi de primeiro contacto.
- **[HYDRA-UMC-SDK](https://github.com/JuanenRac/HYDRA-UMC-SDK)** — o contrato JSON-Schema partilhado e a fronteira de portas de segurança contra a qual cada bridge valida os seus comandos.
- **[HYDRA-UMC-CONNECTOR-HUB](https://github.com/JuanenRac/HYDRA-UMC-CONNECTOR-HUB)** — registo declarativo de manifestos de adaptador e validador para conectores de máquinas externas; estende a ideia de contrato do SDK a máquinas externas sem substituir os projetos de gateway industrial.

*Backend central e clientes*
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** — criador/editor gráfico de URDF para desktop que envia os modelos concluídos para o catálogo do STUDIO.
- **[HYDRA-UMC-EDITOR-STL](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-STL)** — editor de modelos STL para desktop que transforma/substitui/remove/adiciona peças reais no mesmo catálogo de modelos que o HYDRA-UMC-EDITOR-URDF também edita.

*Plataforma de ferramentas URTC*
- **[URTC](https://github.com/JuanenRac/URTC)** — firmware da placa física Universal Robot Tool Controller, mais de 25 perfis de ferramenta por barramento CAN.
- **[URTC-FLASHER](https://github.com/JuanenRac/URTC-FLASHER)** — ferramenta gráfica de gravação para desktop das placas URTC, por CAN-OTA e também SWD/JTAG de chip completo.
- **[URTC-TESTER](https://github.com/JuanenRac/URTC-TESTER)** — ferramenta de diagnóstico CAN em tempo real para desktop das placas URTC, com um painel por perfil de ferramenta.
- **[URTC-WEB-STUDIO](https://github.com/JuanenRac/URTC-WEB-STUDIO)** — alternativa no navegador ao URTC-TESTER através da Web Serial API, sem instalação local.

*Nó de IA de visão (Hailo-8)*
- **[HYDRA-UMC-VISION-NODE](https://github.com/JuanenRac/HYDRA-UMC-VISION-NODE)** — centro de integração do pipeline de visão Hailo-8, com uma verificação real de prontidão de hardware por fase.
- **[HYDRA-UMC-DETECTION-HEF](https://github.com/JuanenRac/HYDRA-UMC-DETECTION-HEF)** — registo real de modelos compilados com verificação segura de carga por arquitetura Hailo e soma de verificação.
- **[HYDRA-UMC-VISION-STREAMER](https://github.com/JuanenRac/HYDRA-UMC-VISION-STREAMER)** — pipeline GStreamer real e gerador de configuração MediaMTX com uma fronteira de integração HailoRT real.
- **[HYDRA-UMC-VISUAL-SERVOING-API](https://github.com/JuanenRac/HYDRA-UMC-VISUAL-SERVOING-API)** — lei de correção real de servovisão baseada em posição, protegida pelo estado da zona a montante.
- **[HYDRA-UMC-SAFETY-ZONES](https://github.com/JuanenRac/HYDRA-UMC-SAFETY-ZONES)** — verificação real de violação de zonas e pedido de E-STOP, com exigência de calibração recente.

*Nó de IA cognitiva (Hailo-10)*
- **[HYDRA-UMC-VLA-ENGINE](https://github.com/JuanenRac/HYDRA-UMC-VLA-ENGINE)** — codificação/descodificação real de tokens de ação e geração de trajetórias para um modelo Visão-Linguagem-Ação.
- **[HYDRA-UMC-SEMANTIC-PLANNER](https://github.com/JuanenRac/HYDRA-UMC-SEMANTIC-PLANNER)** — decomposição real de tarefas baseada em regras e recuperação semântica de erros sobre os códigos de erro do MCU.
- **[HYDRA-UMC-DOCS-QA](https://github.com/JuanenRac/HYDRA-UMC-DOCS-QA)** — pesquisa real de documentos TF-IDF só com a biblioteca padrão sobre a documentação Markdown deste ecossistema.

*Orquestração e enxame*
- **[HYDRA-UMC-ORCHESTRATOR](https://github.com/JuanenRac/HYDRA-UMC-ORCHESTRATOR)** — centro de integração com um contrato real de relatório de saúde gRPC/Protobuf e uma máquina de estados de missões.
- **[HYDRA-UMC-JOB-DISPATCHER](https://github.com/JuanenRac/HYDRA-UMC-JOB-DISPATCHER)** — fila real de trabalhos por prioridade com deduplicação, sobre uma API HTTP real.
- **[HYDRA-UMC-NODE-HEALING](https://github.com/JuanenRac/HYDRA-UMC-NODE-HEALING)** — vigilante real de saúde da frota por gRPC com repetição/recuo e deteção de identidade incoerente.
- **[HYDRA-UMC-PATH-PLANNER-3D](https://github.com/JuanenRac/HYDRA-UMC-PATH-PLANNER-3D)** — planeador real de trajetórias 3D baseado em RRT com validação real de colisões com obstáculos e espaço de trabalho.
- **[HYDRA-UMC-SWARM-SYNC](https://github.com/JuanenRac/HYDRA-UMC-SWARM-SYNC)** — sincronização real de estado CRDT LWW-Element-Map, testada por propriedades para a convergência de várias células.

*Gémeo digital e simulação*
- **[HYDRA-UMC-TWIN](https://github.com/JuanenRac/HYDRA-UMC-TWIN)** — centro de integração do motor de gémeo digital, com um contrato real de sincronização de compatibilidade de versões.
- **[HYDRA-UMC-HIL-BRIDGE](https://github.com/JuanenRac/HYDRA-UMC-HIL-BRIDGE)** — interlock de segurança real de hardware-in-the-loop que encaminha comandos entre a simulação e o hardware real.
- **[HYDRA-UMC-PHYSICS-REPLICA](https://github.com/JuanenRac/HYDRA-UMC-PHYSICS-REPLICA)** — cinemática direta real e validação de limites de juntas sobre um subconjunto real de URDF.
- **[HYDRA-UMC-SYNTHETIC-DATA-GEN](https://github.com/JuanenRac/HYDRA-UMC-SYNTHETIC-DATA-GEN)** — gerador procedural real de cenas 2D com exportação de anotações YOLO/COCO.

*Dados e análise*
- **[HYDRA-UMC-DATALAKE](https://github.com/JuanenRac/HYDRA-UMC-DATALAKE)** — armazém real de séries temporais sobre sqlite3 com uma API HTTP real de ingestão/consulta.
- **[HYDRA-UMC-ANOMALY-DETECTOR](https://github.com/JuanenRac/HYDRA-UMC-ANOMALY-DETECTOR)** — detetor real de anomalias por FFT e linha de base estatística, com monitorização de deriva.
- **[HYDRA-UMC-PRODUCTION-REPORTS](https://github.com/JuanenRac/HYDRA-UMC-PRODUCTION-REPORTS)** — cálculo real de OEE/disponibilidade sobre o histórico do DATALAKE, com exportação CSV reprodutível.
- **[HYDRA-UMC-TELEMETRY-COLLECTOR](https://github.com/JuanenRac/HYDRA-UMC-TELEMETRY-COLLECTOR)** — pipeline real de ingestão CAN/WebSocket para o DATALAKE, com deduplicação por sequência.

*Gateway industrial*
- **[HYDRA-UMC-GATEWAY-INDUSTRIAL](https://github.com/JuanenRac/HYDRA-UMC-GATEWAY-INDUSTRIAL)** — centro de integração que retransmite para protocolos industriais, com uma camada real de lista de comandos permitidos e contrapressão.
- **[HYDRA-UMC-OPCUA-SERVER](https://github.com/JuanenRac/HYDRA-UMC-OPCUA-SERVER)** — espaço de endereços OPC-UA real, verificado com uma sessão de cliente real do protocolo binário.
- **[HYDRA-UMC-MQTT-BROKER](https://github.com/JuanenRac/HYDRA-UMC-MQTT-BROKER)** — broker MQTT real com autenticação opcional por cliente e ACL de tópicos.
- **[HYDRA-UMC-MTCONNECT-ADAPTER](https://github.com/JuanenRac/HYDRA-UMC-MTCONNECT-ADAPTER)** — endpoints XML MTConnect `/probe` e `/current` reais com saída em modo degradado.

*Ferramentas complementares e operações do ecossistema*
- **[HYDRA-UMC-DASHBOARD-AI](https://github.com/JuanenRac/HYDRA-UMC-DASHBOARD-AI)** — painéis de Resumos Inteligentes e Realce de Anomalias sobre o DATALAKE/ANOMALY-DETECTOR, com um recurso estatístico honesto.
- **[HYDRA-UMC-TOOL-CLI](https://github.com/JuanenRac/HYDRA-UMC-TOOL-CLI)** — CLI da frota com um contrato de códigos de saída real e estável, um cliente vivo genuíno da API do HYDRA-UMC-SERVER.
- **[URTC-SMART-RACK](https://github.com/JuanenRac/URTC-SMART-RACK)** — firmware de um rack de montagem de placas com descodificação real do ID da ferramenta e lógica de pré-aquecimento Smart Idle.
- **[URTC-VISION-TOOL](https://github.com/JuanenRac/URTC-VISION-TOOL)** — firmware mais um companheiro de visão em Python real para uma cabeça de ferramenta de inspeção térmica/RGB.
- **[HYDRA-UMC-UPDATER](https://github.com/JuanenRac/HYDRA-UMC-UPDATER)** — ferramenta administrativa de desktop que descobre, clona e atualiza todos os repositórios deste ecossistema.
- **[HYDRA-UMC-OS-REBUILDER](https://github.com/JuanenRac/HYDRA-UMC-OS-REBUILDER)** — ferramenta de desktop para Windows/Linux que constrói uma imagem do CM5 pronta a gravar com as versões mais recentes do ecossistema, com configuração de primeiro arranque de Wi-Fi/utilizador/SSH ao estilo do Raspberry Pi Imager.
- **[HYDRA-UMC-OPS-AGENT](https://github.com/JuanenRac/HYDRA-UMC-OPS-AGENT)** — coordenador de incidentes de manutenção: um papel de borda de poucos privilégios recolhe um inventário/estado higienizado, um papel de plano de controlo mostra-o só de leitura e pede a um fornecedor de IA que sugira um diagnóstico; nunca aplica um patch nem implanta nada.
- **[HYDRA-UMC-DEV-SERVER](https://github.com/JuanenRac/HYDRA-UMC-DEV-SERVER)** — anfitrião de desenvolvimento reproduzível (Raspberry Pi 5 / CM5) que guarda o código-fonte do ecossistema e executa tarefas limitadas de compilação/teste numa fila durável; um papel de desenvolvimento dedicado, explicitamente não um CM5 operacional.

---

## 📚 Documentação e comunidade

- **[CONTRIBUTING.md](CONTRIBUTING.md)** — pilha tecnológica e diretrizes de código para um pull request.
- **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** — as normas de comportamento esperadas nesta comunidade.
- **[SECURITY.md](SECURITY.md)** — como comunicar uma vulnerabilidade e as áreas de segurança em que este projeto se concentra.
- **[SUPPORT.md](SUPPORT.md)** — onde fazer perguntas e comunicar erros.
- **[LICENSE.md](LICENSE.md)** — a licença deste projeto.

## 👤 AUTOR
**JuanenRac** (Electro Hobby 3D)
📧 electrohobby3d@gmail.com
📺 [youtube.com/@electrohobby3d](https://youtube.com/@electrohobby3d)

## 📜 LICENÇA

GNU General Public License v3.0 or later (GPL-3.0-or-later) para o código-fonte - veja [`LICENSE`](LICENSE).

A documentação (este README e as suas próprias traduções - `README_spa.md`, `README_ita.md`, `README_fra.md`, `README_deu.md`, `README_zho.md`, `README_jpn.md`, `README_por.md`) está disponível sob a **Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)**. Texto completo em https://creativecommons.org/licenses/by-sa/4.0/.

