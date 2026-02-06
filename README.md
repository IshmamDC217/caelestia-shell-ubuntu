# Caelestia Shell on Ubuntu

[![Ubuntu](https://img.shields.io/badge/Ubuntu-25.10-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=for-the-badge&logo=wayland&logoColor=black)](https://hyprland.org/)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue?style=for-the-badge)](LICENSE)

A complete guide to installing [Caelestia Shell](https://github.com/caelestia-dots/shell) on Ubuntu 25.10. Caelestia is a beautiful, feature-rich desktop shell built with Quickshell for Hyprland.

> **Note**: Caelestia was designed for Arch Linux (AUR packages). This guide covers building everything from source on Ubuntu.

## Quick Install

**Prerequisites:** Ubuntu 25.10 with Hyprland already installed (see [Step 1](#step-1-install-hyprland) below).

```bash
git clone https://github.com/YOUR_USERNAME/caelestia-ubuntu-guide.git
cd caelestia-ubuntu-guide
./install.sh
```

The script will:
- Install all APT dependencies in one go
- Download and install CascadiaCode Nerd Font
- Build and install Quickshell, libcava, Caelestia CLI, and Caelestia Shell
- Set up library paths and environment variables
- Copy included config files to the right locations

Build sources are kept in `~/caelestia-build/` and can be removed after installation.

## Files Included

| File | Destination | Description |
|------|-------------|-------------|
| `config/shell.json` | `~/.config/caelestia/shell.json` | Caelestia shell configuration |
| `config/quickshell/qml_color.json` | `~/.config/quickshell/qml_color.json` | Quickshell color theme |
| `config/hypr/hyprland.conf` | `~/.config/hypr/hyprland.conf` | Hyprland config (reference only) |
| `config/bashrc.snippet` | append to `~/.bashrc` | QML_IMPORT_PATH environment variable |
| `install.sh` | — | Automated installer script |

### Environment Setup

The QML import path must be set for Caelestia to find its modules:

**In `~/.bashrc`** (for terminal/CLI usage):
```bash
export QML_IMPORT_PATH=/usr/lib/qt6/qml
```

**In `~/.config/hypr/hyprland.conf`** (for Hyprland session):
```bash
env = QML_IMPORT_PATH,/usr/lib/qt6/qml
```

The install script handles the bashrc entry automatically. The hyprland.conf line must be added manually if not already present.

---

## Manual Installation

### Prerequisites

- Ubuntu 25.10 (may work on 24.04 with adjustments)
- A working Wayland session
- ~2GB free disk space for building

### Step 1: Install Hyprland

Use [JaKooLit's Ubuntu-Hyprland](https://github.com/JaKooLit/Ubuntu-Hyprland) installer:
```bash
git clone -b 25.10 --depth=1 https://github.com/JaKooLit/Ubuntu-Hyprland.git ~/Ubuntu-Hyprland-25.10
cd ~/Ubuntu-Hyprland-25.10
chmod +x install.sh
./install.sh
```

**Recommended options:**
| Prompt | Recommended |
|--------|-------------|
| Monitor resolution | Option 2 (>= 1440p) |
| GTK Themes | Yes |
| Thunar | Yes |
| SDDM | No (keep GDM) |
| XDG-Desktop-Portal-Hyprland | Yes |
| Preconfigured Dotfiles | Yes |
| Add to input group | Yes |

Reboot and select "Hyprland" from GDM.

### Step 2: Install Dependencies

#### Base Build Tools
```bash
sudo apt update
sudo apt install -y build-essential cmake ninja-build git pkg-config meson
```

#### Qt6 Dependencies
```bash
sudo apt install -y \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-svg-dev \
    qt6-wayland-dev \
    qt6-wayland \
    qt6-shader-baker \
    libqt6svg6 \
    libwayland-dev \
    wayland-protocols \
    libjemalloc-dev \
    libpipewire-0.3-dev \
    libxcb1-dev \
    libdrm-dev
```

#### Caelestia Dependencies
```bash
sudo apt install -y \
    python3-pip \
    python3-build \
    python3-hatchling \
    libnotify-bin \
    grim \
    slurp \
    wl-clipboard \
    fish \
    brightnessctl \
    ddcutil \
    lm-sensors \
    swappy \
    libqalculate-dev \
    libaubio-dev
```

### Step 3: Install Nerd Fonts
```bash
mkdir -p ~/.local/share/fonts
cd /tmp
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/CascadiaCode.zip
unzip CascadiaCode.zip -d CascadiaCode
cp CascadiaCode/*.ttf ~/.local/share/fonts/
fc-cache -fv
```

### Step 4: Build Quickshell
```bash
cd ~
git clone https://git.outfoxxed.me/quickshell/quickshell.git
cd quickshell

cmake -GNinja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCRASH_REPORTER=OFF \
    -DINSTALL_QML_PREFIX=lib/qt6/qml

cmake --build build
sudo cmake --install build
```

### Step 5: Build libcava

> **Important**: Use [LukashonakV/cava](https://github.com/LukashonakV/cava) fork, NOT karlstav/cava.
```bash
cd ~
git clone https://github.com/LukashonakV/cava.git libcava
cd libcava

meson setup build --buildtype=release -Ddefault_library=shared
meson compile -C build
sudo meson install -C build
```

Configure library path:
```bash
echo "/usr/local/lib/x86_64-linux-gnu" | sudo tee /etc/ld.so.conf.d/libcava.conf
sudo ldconfig
```

### Step 6: Install Caelestia CLI
```bash
cd ~
git clone https://github.com/caelestia-dots/cli.git caelestia-cli
cd caelestia-cli

python3 -m build --wheel
sudo pip3 install dist/*.whl --break-system-packages
```

### Step 7: Build Caelestia Shell
```bash
mkdir -p ~/.config/quickshell
cd ~/.config/quickshell
git clone https://github.com/caelestia-dots/shell.git caelestia
cd caelestia

PKG_CONFIG_PATH="/usr/local/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH" \
cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/

cmake --build build
sudo cmake --install build
```

Verify:
```bash
ls -la /usr/lib/qt6/qml/Caelestia/Services/
```

### Step 8: Configuration

#### Environment Variables

Add to `~/.bashrc`:
```bash
export QML_IMPORT_PATH=/usr/lib/qt6/qml
```

Add to `~/.config/hypr/hyprland.conf`:
```bash
env = QML_IMPORT_PATH,/usr/lib/qt6/qml
```

#### Wallpapers
```bash
mkdir -p ~/Pictures/Wallpapers
# Add wallpapers to this directory
```

#### Shell Config

Copy `config/shell.json` from this repo to `~/.config/caelestia/shell.json`, or create your own.

Key settings:
- `services.useFahrenheit`: `false` for Celsius
- `services.gpuType`: `"intel"`, `"amd"`, or `"nvidia"`
- `background.visualiser.enabled`: `false` to disable audio visualizer

#### Color Theme

Copy `config/quickshell/qml_color.json` from this repo to `~/.config/quickshell/qml_color.json`. This controls the Quickshell color scheme. Caelestia will regenerate this file when you change themes.

## Running the Shell

### Manual
```bash
caelestia shell -d
```

### Auto-start

Add to `~/.config/hypr/hyprland.conf`:
```bash
exec-once = caelestia shell -d
```

## Troubleshooting

### "CavaProvider is not a type"

Rebuild both Quickshell and caelestia-shell with `PKG_CONFIG_PATH` set:
```bash
export PKG_CONFIG_PATH="/usr/local/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
```

### Files installing to /usr/usr/lib/

Use `-DCMAKE_INSTALL_PREFIX=/` (not `/usr`).

### QML module not found
```bash
export QML_IMPORT_PATH=/usr/lib/qt6/qml
```

## Credits

- [Caelestia Dots](https://github.com/caelestia-dots) - Original shell
- [Quickshell](https://quickshell.outfoxxed.me/) by [@outfoxxed](https://github.com/outfoxxed)
- [JaKooLit](https://github.com/JaKooLit) - Ubuntu Hyprland installer
- [LukashonakV](https://github.com/LukashonakV) - libcava fork

## License

GPL-3.0
# caelestia-ubuntu-guide
