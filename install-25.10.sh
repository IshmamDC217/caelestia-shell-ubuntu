#!/usr/bin/env bash
#
# Caelestia Shell installer for Ubuntu 25.10
# https://github.com/caelestia-dots/shell
#
# Prerequisites: Hyprland already installed (e.g. via JaKooLit/Ubuntu-Hyprland)
#

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }
step()  { echo -e "\n${CYAN}${BOLD}── $* ──${NC}"; }

die() { err "$@"; exit 1; }

# ── Sanity checks ────────────────────────────────────────────────────────────
[[ "$(id -u)" -eq 0 ]] && die "Do not run this script as root."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$HOME/caelestia-build"

# ── Helper ───────────────────────────────────────────────────────────────────
confirm() {
    echo -e "${YELLOW}$1${NC}"
    read -rp "Continue? [Y/n] " ans
    [[ -z "$ans" || "$ans" =~ ^[Yy] ]] && return 0
    return 1
}

# ── Step 1: APT dependencies ────────────────────────────────────────────────
step "Step 1/7: Installing APT dependencies"

sudo apt update
sudo apt install -y \
    build-essential cmake ninja-build git pkg-config meson \
    qt6-base-dev qt6-declarative-dev qt6-svg-dev qt6-wayland-dev \
    qt6-wayland qt6-shader-baker libqt6svg6 \
    libwayland-dev wayland-protocols libjemalloc-dev \
    libpipewire-0.3-dev libxcb1-dev libdrm-dev \
    python3-pip python3-build python3-hatchling \
    libnotify-bin grim slurp wl-clipboard \
    fish brightnessctl ddcutil lm-sensors swappy \
    libqalculate-dev libaubio-dev

ok "APT dependencies installed"

# ── Step 2: Nerd Fonts ──────────────────────────────────────────────────────
step "Step 2/7: Installing Nerd Fonts (CascadiaCode)"

if fc-list | grep -qi "CaskaydiaCove"; then
    ok "CascadiaCode Nerd Font already installed, skipping"
else
    mkdir -p ~/.local/share/fonts
    FONT_TMP="$(mktemp -d)"
    wget -q --show-progress -O "$FONT_TMP/CascadiaCode.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/CascadiaCode.zip
    unzip -qo "$FONT_TMP/CascadiaCode.zip" -d "$FONT_TMP/CascadiaCode"
    cp "$FONT_TMP"/CascadiaCode/*.ttf ~/.local/share/fonts/
    fc-cache -f
    rm -rf "$FONT_TMP"
    ok "Nerd Fonts installed"
fi

# ── Step 3: Build Quickshell ────────────────────────────────────────────────
step "Step 3/7: Building Quickshell"

mkdir -p "$BUILD_DIR"

if command -v quickshell &>/dev/null; then
    warn "Quickshell binary found. Rebuilding anyway."
fi

cd "$BUILD_DIR"
if [[ -d quickshell ]]; then
    info "Quickshell source already cloned, pulling latest..."
    cd quickshell && git pull
else
    git clone https://git.outfoxxed.me/quickshell/quickshell.git
    cd quickshell
fi

cmake -GNinja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCRASH_REPORTER=OFF \
    -DINSTALL_QML_PREFIX=lib/qt6/qml

cmake --build build
sudo cmake --install build

ok "Quickshell installed"

# ── Step 4: Build libcava ───────────────────────────────────────────────────
step "Step 4/7: Building libcava (LukashonakV fork)"

cd "$BUILD_DIR"
if [[ -d libcava ]]; then
    info "libcava source already cloned, pulling latest..."
    cd libcava && git pull
else
    git clone https://github.com/LukashonakV/cava.git libcava
    cd libcava
fi

meson setup build --buildtype=release -Ddefault_library=shared --wipe 2>/dev/null \
    || meson setup build --buildtype=release -Ddefault_library=shared
meson compile -C build
sudo meson install -C build

# Library path
echo "/usr/local/lib/x86_64-linux-gnu" | sudo tee /etc/ld.so.conf.d/libcava.conf >/dev/null
sudo ldconfig

ok "libcava installed"

# ── Step 5: Install Caelestia CLI ───────────────────────────────────────────
step "Step 5/7: Installing Caelestia CLI"

cd "$BUILD_DIR"
if [[ -d caelestia-cli ]]; then
    info "caelestia-cli source already cloned, pulling latest..."
    cd caelestia-cli && git pull
else
    git clone https://github.com/caelestia-dots/cli.git caelestia-cli
    cd caelestia-cli
fi

python3 -m build --wheel
sudo pip3 install dist/*.whl --break-system-packages --force-reinstall

ok "Caelestia CLI installed"

# ── Step 6: Build Caelestia Shell ───────────────────────────────────────────
step "Step 6/7: Building Caelestia Shell"

mkdir -p ~/.config/quickshell

SHELL_DIR="$HOME/.config/quickshell/caelestia"
if [[ -d "$SHELL_DIR" ]]; then
    info "Caelestia Shell source already cloned, pulling latest..."
    cd "$SHELL_DIR" && git pull
else
    git clone https://github.com/caelestia-dots/shell.git "$SHELL_DIR"
    cd "$SHELL_DIR"
fi

PKG_CONFIG_PATH="/usr/local/lib/x86_64-linux-gnu/pkgconfig:${PKG_CONFIG_PATH:-}" \
cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/

cmake --build build
sudo cmake --install build

ok "Caelestia Shell installed"

# ── Step 7: Configuration ──────────────────────────────────────────────────
step "Step 7/7: Setting up configuration"

# QML_IMPORT_PATH in bashrc
if ! grep -q 'QML_IMPORT_PATH=/usr/lib/qt6/qml' ~/.bashrc 2>/dev/null; then
    echo 'export QML_IMPORT_PATH=/usr/lib/qt6/qml' >> ~/.bashrc
    ok "Added QML_IMPORT_PATH to ~/.bashrc"
else
    ok "QML_IMPORT_PATH already in ~/.bashrc"
fi

# Copy config files from this repo
if [[ -f "$SCRIPT_DIR/config/shell.json" ]]; then
    mkdir -p ~/.config/caelestia
    cp -n "$SCRIPT_DIR/config/shell.json" ~/.config/caelestia/shell.json 2>/dev/null \
        && ok "Copied shell.json to ~/.config/caelestia/" \
        || warn "~/.config/caelestia/shell.json already exists, skipping (delete it first to overwrite)"
fi

if [[ -f "$SCRIPT_DIR/config/quickshell/qml_color.json" ]]; then
    cp -n "$SCRIPT_DIR/config/quickshell/qml_color.json" ~/.config/quickshell/qml_color.json 2>/dev/null \
        && ok "Copied qml_color.json to ~/.config/quickshell/" \
        || warn "~/.config/quickshell/qml_color.json already exists, skipping"
fi

# Wallpaper directory
mkdir -p ~/Pictures/Wallpapers

# Hint about hyprland env
if [[ -f ~/.config/hypr/hyprland.conf ]]; then
    if ! grep -q 'QML_IMPORT_PATH' ~/.config/hypr/hyprland.conf 2>/dev/null; then
        warn "Add this line to ~/.config/hypr/hyprland.conf:"
        echo "  env = QML_IMPORT_PATH,/usr/lib/qt6/qml"
    else
        ok "QML_IMPORT_PATH already set in hyprland.conf"
    fi
fi

ok "Configuration complete"

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Caelestia Shell installation complete!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "To start the shell manually:"
echo -e "  ${CYAN}caelestia shell -d${NC}"
echo ""
echo -e "To auto-start with Hyprland, add to ${BOLD}~/.config/hypr/hyprland.conf${NC}:"
echo -e "  ${CYAN}exec-once = caelestia shell -d${NC}"
echo ""
echo -e "Add wallpapers to ${BOLD}~/Pictures/Wallpapers/${NC}"
echo -e "Edit shell config at ${BOLD}~/.config/caelestia/shell.json${NC}"
echo ""
echo -e "${YELLOW}NOTE: Open a new terminal or run 'source ~/.bashrc' to load QML_IMPORT_PATH.${NC}"
