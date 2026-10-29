// =============================================================================
// HYDRA-UMC DSI (Flutter) - util/panel_defaults.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// The panel is fixed to the Compute Module that runs HYDRA-UMC-SERVER, so
// the address it offers on the sign-in screen is that machine itself. A
// panel that is meant to reach another server types or scans for it; it is
// never pre-filled with an address that belongs to somebody else's network.
// =============================================================================

/// The server address pre-filled on the sign-in screen: the machine the panel is mounted on.
const String panelDefaultHost = '127.0.0.1';

/// The port HYDRA-UMC-SERVER listens on by default.
const int panelDefaultPort = 3000;
