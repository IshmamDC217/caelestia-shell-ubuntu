# Hyprland + Caelestia Shell on Ubuntu 26.04 LTS

[![Ubuntu](https://img.shields.io/badge/Ubuntu-26.04_LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Hyprland](https://img.shields.io/badge/Hyprland-0.53.3-58E1FF?style=for-the-badge&logo=wayland&logoColor=black)](https://hyprland.org/)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue?style=for-the-badge)](../LICENSE)

Everything here was run end to end on a clean Ubuntu 26.04.1 install
(ThinkPad T480s, Intel UHD 620). Versions and error messages are the real
ones, not reconstructed from memory.

> **Coming from the 25.10 guide?** The big change is that **Ubuntu 26.04
> packages Hyprland**, so the JaKooLit prerequisite is gone. The painful
> change is that 26.04 ships **Qt 6.10.2** while current Caelestia targets
> **Qt 6.11** - see [The Qt 6.10 problem](#the-qt-610-problem).

## Contents

- [What changed since 25.10](#what-changed-since-2510)
- [Quick install](#quick-install)
- [Manual installation](#manual-installation)
- [The Qt 6.10 problem](#the-qt-610-problem)
- [Hyprland 0.53 config changes](#hyprland-053-config-changes)
- [HiDPI scaling](#hidpi-scaling)
- [Configuring the shell](#configuring-the-shell)
- [Troubleshooting](#troubleshooting)
- [Credits](#credits)

## What changed since 25.10

| | Ubuntu 25.10 | Ubuntu 26.04 |
|---|---|---|
| Hyprland | JaKooLit's third-party installer | `apt install hyprland` (0.53.3) |
| `hyprlang`, `hyprcursor` | built from source | `libhyprlang-dev`, `libhyprcursor-dev` |
| Ecosystem | mostly manual | `hypridle`, `hyprlock`, `hyprpicker`, `hyprpolkitagent`, `hyprland-qtutils`, 9 plugins |
| `waybar`, `fuzzel`, `wlogout`, `swayosd`, `nwg-displays` | mixed | all packaged |
| Quickshell | source build | **still a source build** |
| libcava | source build | **still a source build** |
| `swww` | available | **not packaged** - use `hyprpaper` or `swaybg` |
| Qt | 6.9 | 6.10.2 - **too old for current Caelestia**, see below |
| Python | 3.13 | 3.14 |

## Quick install

```bash
git clone https://github.com/IshmamDC217/caelestia-shell-ubuntu.git
cd caelestia-shell-ubuntu
./install-26.04.sh
```

Then log out and choose **Hyprland** at the login screen.

Build sources land in `~/caelestia-build/` and can be deleted afterwards.

---

## Manual installation

### Step 1: Hyprland and desktop components

No third-party installer needed on 26.04:

```bash
sudo apt update
sudo apt install -y \
    hyprland hyprland-protocols hyprland-qtutils hyprwayland-scanner \
    hypridle hyprlock hyprpaper hyprpicker hyprpolkitagent \
    xdg-desktop-portal-hyprland uwsm \
    waybar dunst fuzzel kitty wlogout swayosd nwg-displays nwg-look \
    qt5ct qt6ct pavucontrol
```

> **Do not skip `uwsm`.** The `hyprland` package installs a
> `hyprland-uwsm.desktop` session file but neither Depends nor Recommends
> `uwsm`. Pick "Hyprland (uwsm-managed)" at the login screen without it and
> the session dies immediately. This is a packaging bug in 26.04; installing
> `uwsm` fixes it, or just use the plain "Hyprland" session.

If you are upgrading from 24.04 where you built Hyprland from source, **remove
the old `/usr/local` build first.** `/usr/local/bin` precedes `/usr/bin` on
`PATH`, so a stale binary silently shadows the packaged one.

### Step 2: Build dependencies

```bash
sudo apt install -y \
    build-essential cmake ninja-build git pkg-config meson \
    qt6-base-dev qt6-declarative-dev qt6-svg-dev qt6-wayland-dev qt6-wayland \
    qt6-shader-baker qt6-shadertools-dev libqt6svg6 qt6-image-formats-plugins \
    qt6-base-private-dev qt6-declarative-private-dev qt6-wayland-private-dev \
    libwayland-dev wayland-protocols libjemalloc-dev \
    libpipewire-0.3-dev libxcb1-dev libdrm-dev \
    libcli11-dev libgbm-dev libegl-dev libegl1-mesa-dev \
    libpolkit-agent-1-dev libpolkit-gobject-1-dev libpam0g-dev \
    libsensors-dev libqalculate-dev libaubio-dev \
    libiniparser-dev libfftw3-dev libasound2-dev libpulse-dev \
    python3-pip python3-build python3-hatchling \
    libnotify-bin grim slurp wl-clipboard fish brightnessctl ddcutil \
    lm-sensors swappy unzip wget
```

Seven of these are **not** in the 25.10 guide, and each one stops the build
dead:

| Package | Without it |
|---|---|
| `qt6-shadertools-dev` | `Failed to find required Qt component "ShaderTools"` - `qt6-shader-baker` ships the binary but not the CMake config |
| `qt6-base-private-dev`, `qt6-declarative-private-dev` | `Failed to find required Qt component "QuickPrivate"` |
| `libcli11-dev` | `Could not find a package configuration file provided by "CLI11"` |
| `libgbm-dev`, `libegl-dev` | `The following required packages were not found: gbm, egl` |
| `libpolkit-agent-1-dev` | `Package 'polkit-agent-1' not found` |
| `libsensors-dev` | `Could not find SENSORS_LIBRARY` - `lm-sensors` is tools only |
| `libiniparser-dev` | `iniparser library is required` (libcava) |
| `qt6-image-formats-plugins` | `Failed to decode source: wallpaper.webp` - Ubuntu ships only gif/ico/jpeg/svg decoders, and Caelestia's default wallpaper is webp |

### Step 3: Fonts

**Caelestia needs three font families, and getting this wrong is the single
most confusing failure in the whole setup.**

| Font | Used for |
|---|---|
| `Material Symbols Rounded` | every icon in the shell |
| `Rubik` | clock and workspace labels |
| `CaskaydiaCove NF` | monospace |

```bash
mkdir -p ~/.local/share/fonts && cd /tmp

# Nerd Font (monospace)
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/CascadiaCode.zip
unzip CascadiaCode.zip -d CascadiaCode
cp CascadiaCode/*.ttf ~/.local/share/fonts/

# Material Symbols Rounded (icons)
wget -O ~/.local/share/fonts/"MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf" \
  "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"

# Rubik (clock, workspaces)
wget -O ~/.local/share/fonts/"Rubik[wght].ttf" \
  "https://github.com/googlefonts/rubik/raw/main/fonts/variable/Rubik%5Bwght%5D.ttf"
wget -O ~/.local/share/fonts/"Rubik-Italic[wght].ttf" \
  "https://github.com/googlefonts/rubik/raw/main/fonts/variable/Rubik-Italic%5Bwght%5D.ttf"

fc-cache -f
```

Verify all three resolve to themselves and not to a fallback:

```bash
for f in "Material Symbols Rounded" "Rubik" "CaskaydiaCove NF"; do fc-match "$f"; done
```

If any line comes back as `NotoSans-Regular.ttf`, that font is missing.

> **Why this matters so much.** Material Symbols renders icons from
> **ligatures** - the shell writes the literal word `terminal` and the font
> turns it into an icon. With the font missing, fontconfig silently falls back
> to Noto Sans and you get the *words themselves* rendered into the bar,
> overflowing and clipping: `rmin`, `web`, `ndar_r`. It looks like a broken
> layout or a scaling bug, but nothing is wrong with the layout at all.

> **Do not use `fonts-material-design-icons-iconfont` from apt.** That is the
> older Material Design Icons project - different family name, different
> ligature set. It will not satisfy `Material Symbols Rounded`.

### Step 4: Build Quickshell

Still not packaged in 26.04.

```bash
mkdir -p ~/caelestia-build && cd ~/caelestia-build
git clone https://git.outfoxxed.me/quickshell/quickshell.git
cd quickshell

cmake -GNinja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCRASH_HANDLER=OFF \
    -DINSTALL_QML_PREFIX=lib/qt6/qml

cmake --build build
sudo cmake --install build
```

> **`CRASH_HANDLER`, not `CRASH_REPORTER`.** Upstream renamed the option.
> CMake silently ignores unknown `-D` variables, so the old flag from the
> 25.10 guide looks accepted while crash handling stays **on**, and the build
> then fails on `cpptrace`, which Ubuntu does not package. Roughly 4 minutes
> on 8 cores.

### Step 5: Build libcava

Ubuntu's `cava` package is karlstav's console visualiser and ships no shared
library, so the LukashonakV fork is still required.

```bash
cd ~/caelestia-build
git clone https://github.com/LukashonakV/cava.git libcava
cd libcava
meson setup build --buildtype=release -Ddefault_library=shared
meson compile -C build
sudo meson install -C build

echo "/usr/local/lib/x86_64-linux-gnu" | sudo tee /etc/ld.so.conf.d/libcava.conf
sudo ldconfig
```

The pkg-config file installs as **`libcava.pc`**, not `cava.pc`.

### Step 6: Caelestia CLI

```bash
cd ~/caelestia-build
git clone https://github.com/caelestia-dots/cli.git caelestia-cli
cd caelestia-cli
python3 -m build --wheel
sudo pip3 install dist/*.whl --break-system-packages --force-reinstall
```

> `--break-system-packages` replaces the system `pillow` with a newer wheel.
> On a desktop install that is harmless, but it is a real system change - use
> `pipx` instead if you would rather not.

### Step 7: Caelestia Shell

```bash
mkdir -p ~/.config/quickshell
git clone https://github.com/caelestia-dots/shell.git ~/.config/quickshell/caelestia
cd ~/.config/quickshell/caelestia

# Required on 26.04 - see "The Qt 6.10 problem" below
git apply /path/to/caelestia-shell-ubuntu/patches/qt6.10-compat.patch

PKG_CONFIG_PATH="/usr/local/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH" \
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build
sudo cmake --install build
```

> **Clone in full, not shallow.** The build reads its version from
> `git describe`. With `--depth=1` there are no tags and CMake stops with
> `VERSION is not set and failed to get from git`. If you already made a
> shallow clone: `git fetch --unshallow --tags`.

### Step 8: Configuration

```bash
echo 'export QML_IMPORT_PATH=/usr/lib/qt6/qml' >> ~/.bashrc
mkdir -p ~/.config/caelestia ~/.config/hypr ~/Pictures/Wallpapers

cp config/26.04/shell.json ~/.config/caelestia/shell.json
cp config/26.04/quickshell/qml_color.json ~/.config/quickshell/qml_color.json
cp config/26.04/hyprland.conf ~/.config/hypr/hyprland.conf

Hyprland --verify-config   # should print "config ok"
```

The bundled [`hyprland.conf`](../config/26.04/hyprland.conf) is **self-contained** -
it does not `source` an external dotfiles tree the way the 25.10 one did, so
it works on a bare 26.04 install. It sets `QML_IMPORT_PATH`, autostarts
`caelestia shell -d`, and wires all 22 Caelestia actions to keybinds.

---

## The Qt 6.10 problem

**Ubuntu 26.04 ships Qt 6.10.2. Current Caelestia Shell targets Qt 6.11.**
Three independent things break. All are fixed by
[`patches/qt6.10-compat.patch`](../patches/qt6.10-compat.patch) (3 files, 89
lines), verified against Caelestia `v2.4.0-26-g7a527214`.

### 1. `DoubleSpinBox` does not exist

```
@components/controls/StyledSpinBox.qml[7:1]: DoubleSpinBox is not a type
```

`QtQuick.Templates.DoubleSpinBox` arrived in Qt 6.11. Qt 6.10.2 has only the
integer `SpinBox`, and Caelestia genuinely needs fractional steps
(`from: 0.5`, `stepSize: 0.5`), so swapping in `SpinBox` is not enough.

The patch adds `components/controls/DoubleSpinBox.qml`, picked up by QML's
implicit same-directory import. One subtlety: the `up`/`down` indicator slots
must be a **concrete** inline component type. Declaring them as bare
`QtObject` fails, because `up.indicator: ...` is resolved against the
declared type:

```
Cannot assign to non-existent property "indicator"
```

### 2. `char` is a reserved word

```
@modules/lock/center/InputField.qml[119:13]: Unexpected token `reserved word'
```

Caelestia uses `id: char`. Qt 6.10's QML parser treats `char` as reserved;
6.11 relaxed this. The patch renames it to `charItem`.

### 3. `RectangularShadow` has no per-corner radii

```
@modules/nexus/common/ListEditor.qml[240:17]:
Cannot assign to non-existent property "topRightRadius"
```

Qt 6.10.2's `RectangularShadow` exposes only `blur`, `cached`, `color`,
`material`, `offset`, `radius`, `spread`. `topLeftRadius` and friends are
6.11. The patch accepts and ignores them on `components/effects/Elevation.qml`,
falling back to the uniform `radius`. **Cosmetic only** - shadow corners are
uniform instead of per-corner.

### If you would rather not patch

Caelestia **v2.0.2 and earlier** predate all three issues and build unmodified
on Qt 6.10.2. That costs you months of upstream features, which is why this
guide patches forward instead.

Once Ubuntu ships Qt 6.11, drop the patch entirely.

---

## Hyprland 0.53 config changes

Configs written for older Hyprland will not load. Two breaking changes bite
almost everyone - always check with `Hyprland --verify-config`.

**The `gestures {}` block is gone** (removed in 0.51):

```bash
# Old
gestures {
    workspace_swipe = true
}

# 0.53
gesture = 3, horizontal, workspace
```

**`windowrule` is now a block**, not a one-liner:

```bash
# Old
windowrule = float, class:^(pavucontrol)$
windowrule = suppressevent maximize, class:.*

# 0.53
windowrule {
    name = float-config-tools
    match:class = ^(pavucontrol)$

    float = true
}

windowrule {
    name = suppress-maximize-events
    match:class = .*

    suppress_event = maximize
}
```

---

## HiDPI scaling

**This bites every high-DPI laptop.** Hyprland's `auto` scale guesses from
physical size and guesses badly. On a 14" 2560x1440 panel (~211 DPI) it picks
**2.0**, leaving just **1280x720** of logical space - text, buttons and the
clock all render roughly 60% oversized. An external 1080p monitor at 81 DPI
correctly gets 1.0, so the usual symptom is *"huge on the laptop, fine on the
second monitor"*.

Set it explicitly:

```bash
monitor = eDP-1, 2560x1440@60, 0x0,    1.6
monitor = DP-2,  1920x1080@60, 1600x0, 1
```

**Use a scale that divides your resolution exactly**, or you get fractional
scaling blur. Hyprland rounds the value to 2 decimal places, so `1.333333`
silently becomes `1.33` - and 2560 / 1.33 = 1925.2, which is not clean.

For 2560x1440:

| Scale | Logical | Effective DPI | Feel |
|---|---|---|---|
| 1.25 | 2048x1152 | ~169 | small text, most space |
| **1.6** | **1600x900** | **~132** | **comfortable - good default** |
| 2.0 | 1280x720 | ~105 | what `auto` picks; too large |

Note the second monitor's `x` offset must match the first one's **logical**
width, not its pixel width - `1600x0` above, not `2560x0`.

Keep per-machine layout in `~/.config/hypr/monitors.conf` (generate it with
`nwg-displays`) and `source` it, so the rest of your config stays portable.

## Configuring the shell

Caelestia's config schema moves fast, and **an out-of-date `shell.json` fails
silently** - unknown keys are logged as warnings and ignored, so settings
appear to do nothing. Check with:

```bash
caelestia shell -l | grep -i warn
```

Two traps worth knowing:

- `services.gpuType` is an **enum**: `Auto`, `Nvidia`, `Generic`, `None`.
  Values like `"intel"` are rejected outright. Use `Auto` for Intel and AMD.
- Default apps are Arch-flavoured - `foot`, `thunar`, `pwvucontrol` - and none
  ship on Ubuntu. Override `general.apps`.

The bundled [`shell.json`](../config/26.04/shell.json) is deliberately minimal
and only overrides what Ubuntu needs, letting Caelestia default the rest. That
survives upstream schema changes far better than a full copied config:

```json
{
  "general": {
    "apps": {
      "terminal": ["kitty"],
      "audio": ["pavucontrol"],
      "explorer": ["nautilus"]
    }
  },
  "services": {
    "gpuType": "Auto",
    "useFahrenheit": false
  },
  "paths": {
    "wallpaperDir": "~/Pictures/Wallpapers"
  }
}
```

Sizing and appearance are no longer file-driven - use the in-shell settings UI
(`SUPER+N`, or the launcher's `>` prefix then Settings).

---

## Troubleshooting

### The shell will not start

```bash
export QML_IMPORT_PATH=/usr/lib/qt6/qml
caelestia shell          # attached, prints errors
caelestia shell -l       # read the log
```

Quickshell needs `wlr-layer-shell`, which **GNOME does not implement**. The
shell will load under a GNOME session but draws nothing. Test it in an actual
Hyprland session.

### `CavaProvider is not a type`

Rebuild Quickshell and the shell with `PKG_CONFIG_PATH` set:

```bash
export PKG_CONFIG_PATH="/usr/local/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
```

### Files installing to `/usr/usr/lib/`

Use `-DCMAKE_INSTALL_PREFIX=/`, not `/usr`.

### `VERSION is not set and failed to get from git`

Shallow clone. `git fetch --unshallow --tags`.

### The bar shows words like `terminal`, `web`, `ndar_r` instead of icons

The `Material Symbols Rounded` font is missing and fontconfig has fallen back
to a text font, so icon ligature names render literally. See
[Step 3: Fonts](#step-3-fonts). Check with:

```bash
fc-match "Material Symbols Rounded"   # must NOT say NotoSans
```

### Everything is huge on the laptop but fine on the external monitor

Hyprland's `auto` scale. See [HiDPI scaling](#hidpi-scaling).

### `Failed to decode source: wallpaper.webp`

`sudo apt install qt6-image-formats-plugins`. Ubuntu installs only
gif/ico/jpeg/svg decoders by default.

### A setting in shell.json does nothing

It is probably an unknown key from an older schema. `caelestia shell -l | grep -i warn`
lists every rejected option. See [Configuring the shell](#configuring-the-shell).

### Wallpapers do not appear

`paths.wallpaperDir` in `~/.config/caelestia/shell.json` must point somewhere
real. `~` and `$HOME` are expanded, so `~/Pictures/Wallpapers` is portable -
prefer it to an absolute path with a username baked in.

### The uwsm session fails instantly

`sudo apt install uwsm`, or pick the plain "Hyprland" session. See Step 1.

---

## Credits

- [Caelestia Dots](https://github.com/caelestia-dots) - the shell, by Scout
- [Hyprland](https://hyprland.org/) by [@vaxry](https://github.com/vaxerski)
- [Quickshell](https://quickshell.outfoxxed.me/) by [@outfoxxed](https://github.com/outfoxxed)
- [LukashonakV](https://github.com/LukashonakV) - libcava fork
- [JaKooLit](https://github.com/JaKooLit) - the 25.10 route, no longer needed on 26.04

## License

GPL-3.0
