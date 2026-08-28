set -euo pipefail
# HYDRA_UMC_SCRIPT_STANDARD_HEADER_BEGIN
# *****************************************************************************
# Project   : HYDRA-UMC-DSI
# Script    : run_dev.sh
# Purpose   : Development runtime workflow for the local project entry point.
# Author    : JuanenRac (Electro Hobby 3D)
# Email     : electrohobby3d@gmail.com
# Copyright : (C) 2026 JuanenRac
# License   : GPL-3.0 - see LICENSE
# *****************************************************************************
# HYDRA_UMC_SCRIPT_STANDARD_HEADER_END
# HYDRA_UMC_SCRIPT_STANDARD_BANNER_BEGIN
printf '\n*******************************************************************************\n'
printf '%s\n' "* HYDRA-UMC-DSI - run_dev.sh"
printf '%s\n' "* Mode      : RUN WORKFLOW"
printf '%s\n' "* Author    : JuanenRac (Electro Hobby 3D)"
printf '%s\n' "* Email     : electrohobby3d@gmail.com"
printf '%s\n' "* Copyright : (C) 2026 JuanenRac"
printf '%s\n' "* License   : GPL-3.0 - see LICENSE"
printf '%s\n' "* ------------------------------------------------------------------------- *"
printf '%s\n' "* 1. Resolve the runtime prerequisites declared by this script."
printf '%s\n' "* 2. Start the project entry point and forward user arguments unchanged."
printf '%s\n' "* 3. Preserve its result and keep an interactive terminal open."
printf '%s\n' "*******************************************************************************"
printf '\n'
# HYDRA_UMC_SCRIPT_STANDARD_BANNER_END

if ! command -v flutter >/dev/null 2>&1; then
    echo "[ERROR] flutter was not found on PATH. Install the Flutter SDK" >&2
    echo "        (https://docs.flutter.dev/get-started/install) and add its" >&2
    echo "        bin/ directory to PATH, then re-run this script." >&2
    read -p "Press Enter to close this window..."
    exit 1
fi

# -d windows on a Windows dev machine, -d linux on a real Linux machine -
# `flutter devices` lists what's actually available; this picks whichever
# desktop target this OS supports, since this app has no android/ios/web
# platform folder to accidentally target instead.
if [[ "$(uname -s)" == "Linux" ]]; then
    TARGET="linux"
else
    TARGET="windows"
fi

echo "Starting HYDRA-UMC DSI in desktop simulation mode (-d $TARGET)..."
echo "Point it at a real or local HYDRA-UMC STUDIO server from the login screen"
echo "(cd HYDRA-UMC-STUDIO && npm run dev, then 127.0.0.1:3000 here)."
flutter run -d "$TARGET"
