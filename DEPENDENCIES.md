# Dependencies and Arch Linux installation

This guide covers the config's runtime dependencies, hardware integrations, and
test tools. Pacman installs their transitive library dependencies automatically.
The config has been tested with Quickshell **0.3.1**, Qt **6.11.2**, and Hyprland
**0.56.2**. These are tested versions, not exact version pins.

## Runtime packages

| Feature | Arch packages | Purpose |
| --- | --- | --- |
| Shell | `quickshell` | Bar, popups, tray, media, notifications, wallpaper layers, and lock screen. |
| Desktop | `hyprland` | Running Wayland compositor and `hyprctl` for workspaces, window focus, pointer movement, and keyboard layouts. The focus helper uses Hyprland's Lua dispatch API. |
| Qt UI | `qt6-base`, `qt6-declarative`, `qt6-wayland`, `qt6-svg` | Qt Quick, Controls, Layouts, Shapes, Dialogs, FolderListModel for the wallpaper gallery, Wayland rendering, and SVG icons. These are also Quickshell package dependencies. |
| Additional image formats | `qt6-imageformats` | Extra Qt image decoders for artwork and wallpapers; available formats depend on installed plugins. |
| Fonts | `ttf-jetbrains-mono-nerd`, `fontconfig` | Configured text font and Nerd Font widget symbols. |
| Application icons | `hicolor-icon-theme`, `adwaita-icon-theme` | Icon lookup infrastructure and a recommended fallback theme. Apps supply their own desktop entries and icons. |
| Helpers and statistics | `bash`, `coreutils`, `grep`, `procps-ng`, `jq`, `python` | Shell scripts, `head`, `free`, JSON processing, and Python helpers. Linux `/proc` and `/sys` must be available. |
| PC monitoring | `python`, `btop`, an installed terminal | Standard-library collector reads `/proc` and `/sys`; right-click launches `btop`. No extra Python libraries or Qt Charts module are required. |
| Quick settings system info | `python`, `pciutils`, `systemd` | Standard library and Linux interfaces supply system details; `lspci` supplies GPU models and `udevadm` supplies cached installed RAM sizes. No pip packages are needed. |
| Pending repository updates | `pacman-contrib` | `checkupdates` checks configured repositories in a separate database without installing packages. AUR updates are not included. |
| Laptop battery | `python`, `polkit`, `coreutils` | Reads `/sys/class/power_supply`; charge limits use the driver's threshold file. `pkexec` elevates `tee` for protected writes; an active polkit agent is needed for authentication. No extra daemon is required. |
| Workspace previews | `quickshell`, `hyprland` | Native `Quickshell.Wayland.ScreencopyView` captures individual windows through `hyprland-toplevel-export-v1`. No external screenshot utility is needed. |
| Audio controls | `libpulse`, `pavucontrol` | `pactl` for device discovery, volume, mute, and moving streams; middle-click launches the mixer. |
| Audio server | `pipewire`, `pipewire-pulse`, `wireplumber` **or an existing PulseAudio server** | A running PulseAudio-compatible server is required. PipeWire is the default choice in the script below. |
| Network | `networkmanager`, `libnm`, `python-gobject`, `nm-connection-editor` | NetworkManager daemon, `nmcli`, NM introspection through Python GI, and the advanced/VPN profile editor. |
| Wi-Fi backend | `wpa_supplicant` | Default NetworkManager Wi-Fi backend. An already configured NetworkManager setup using `iwd` can keep it instead. |
| Bluetooth | `bluez`, `python-gobject`, `glib2` | BlueZ daemon and Python Gio/GLib D-Bus pairing helper. |
| External monitor brightness | `ddcutil` | DDC/CI discovery and hardware brightness control over I²C. |
| Built-in display brightness | `brightnessctl` | Controls devices exposed under `/sys/class/backlight`. |
| Night Shift | `hyprsunset` | Warm screen colors from the quick settings panel, controlled through `hyprctl`; starts on demand, or controls an existing daemon. Included in the install script below. |
| System/session services | `dbus`, `systemd`, `polkit` | Session/system buses, logind, suspend/reboot/shutdown, and authorization according to system policy. Normally already present on Arch. |
| Lock authentication | `pam`, `pambase` | The custom locker authenticates through `/etc/pam.d/login`. |

The Quickshell build must provide these imported modules:

```text
Quickshell
Quickshell.Io
Quickshell.Widgets
Quickshell.Wayland
Quickshell.Hyprland
Quickshell.Networking
Quickshell.Bluetooth
Quickshell.Services.Mpris
Quickshell.Services.Notifications
Quickshell.Services.SystemTray
Quickshell.Services.Pam
```

Missing imported modules can prevent the shell from loading, even if the
corresponding hardware is absent. The official Arch
[Quickshell package](https://archlinux.org/packages/extra/x86_64/quickshell/)
is available in Extra. The configured
[JetBrains Mono Nerd Font](https://archlinux.org/packages/extra/any/ttf-jetbrains-mono-nerd/)
is also available in Extra; neither requires an AUR helper.

Workspace previews require the native `ScreencopyView` type and the compositor's
window-capture protocol described in the
[Quickshell documentation](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/ScreencopyView/).
If an individual window cannot be captured, its preview shows its icon and title.

## Optional and development packages

| Package | When needed |
| --- | --- |
| NetworkManager VPN plugin matching your VPN | For example, `networkmanager-openvpn` for OpenVPN or `networkmanager-openconnect` for OpenConnect. Install only the plugin your saved profile needs. WireGuard profiles are handled by NetworkManager directly. |
| `bluez-utils` | Optional `bluetoothctl` diagnostics; the widget itself uses native APIs and its Python helper. |
| `libnotify` | `notify-send` for notification integration tests or sending notifications from scripts. |
| `findutils` | `find` used by `scripts/check.sh`. |
| `git` | Cloning/updating this repository or the parent dotfiles submodule. |
| `nvidia-utils` | NVIDIA monitoring uses `nvidia-smi` from the matching installed driver stack. AMD monitoring uses kernel sysfs interfaces. Other GPUs expose only the metrics supported by their driver. |
| `xdg-terminal-exec` | Optional default-terminal resolver. Without it, monitoring checks `$TERMINAL`, Hyprland's terminal setting, then supported installed terminals. |
| `lm_sensors` | Optional sensor diagnostics; monitoring reads kernel hwmon files directly and does not run sensor detection or change permissions. |

CPU package energy counters may be root-readable by default. The optional
`scripts/setup-cpu-power.py` setup uses systemd's `udevadm` and coreutils to grant
one existing local group read access; see [PC monitoring](README.md#pc-monitoring).
This permission setup is separate from the base dependency installer.

QML parsing, linting, and UI tests use `qmlformat`, `qmllint`, `qmltestrunner`,
and `QtTest` from `qt6-declarative`. Python tests use the standard library and
the runtime GI dependencies above. Notification tests additionally use
`dbus-run-session` from `dbus` and `gdbus` from `glib2`.

Media controls use MPRIS and require a player exposing that interface. No
`playerctl` package is needed. Wallpapers and locking are implemented in this
config: Noctalia, `swww`, `hyprpaper`, `hyprlock`, and `swaylock` are not required.
Light/dark wallpaper transitions use Qt Quick animations and the existing image
decoders; they need no additional package.
Codex/Ghostty notification integration is optional; neither is a shell dependency.

Application color syncing is optional and starts disabled. See
[Application themes](APP_THEMING.md#dependencies) for per-target packages and
setup. GTK syncing needs `adw-gtk-theme`, `gsettings-desktop-schemas`, `glib2`, and
`dconf`; Qt uses the existing KDE platform integration or qt5ct/qt6ct. Spotify
uses an already initialized `spicetify-cli` installation. Zen Browser syncing
needs an existing Zen profile with custom stylesheets enabled (see the setup
guide above); it requires no additional package. tmux syncing requires `tmux` and
the dotfiles' `tmux/theme.conf` integration, with no plugin dependency. These optional app
integrations are not installed by the base script below.

## Arch install script

Save the following block as `install-quickshell-deps.sh`, then run
`bash install-quickshell-deps.sh`. It installs packages and performs a full Arch
upgrade with interactive pacman confirmation. Run it as your normal user with
`sudo` available, or as root.

It preserves an installed PulseAudio server. Set `AUDIO_BACKEND=existing` to
leave audio-server packages entirely unchanged, or `AUDIO_BACKEND=pipewire` to
explicitly choose PipeWire (pacman will ask about conflicting packages).
For an existing NetworkManager/iwd setup, set `WIFI_BACKEND=existing`.
Use `INSTALL_TEST_TOOLS=0` to omit test/diagnostic extras.

```bash
#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f /etc/arch-release ]] || ! command -v pacman >/dev/null; then
    printf 'This installer targets Arch Linux with pacman.\n' >&2
    exit 1
fi

as_root=()
if (( EUID != 0 )); then
    if ! command -v sudo >/dev/null; then
        printf 'Install sudo or run this script as root.\n' >&2
        exit 1
    fi
    as_root=(sudo)
fi

packages=(
    quickshell hyprland
    qt6-base qt6-declarative qt6-wayland qt6-svg qt6-imageformats
    ttf-jetbrains-mono-nerd fontconfig hicolor-icon-theme adwaita-icon-theme
    bash coreutils grep procps-ng jq python btop pciutils pacman-contrib
    libpulse pavucontrol
    networkmanager libnm python-gobject nm-connection-editor
    bluez glib2 ddcutil brightnessctl hyprsunset
    dbus systemd polkit pam pambase
)

audio_backend="${AUDIO_BACKEND:-auto}"
if [[ "$audio_backend" == auto ]]; then
    if pacman -Qq pulseaudio >/dev/null 2>&1; then
        audio_backend=existing
    else
        audio_backend=pipewire
    fi
fi
case "$audio_backend" in
    pipewire) packages+=(pipewire pipewire-pulse wireplumber) ;;
    existing) ;;
    *) printf 'AUDIO_BACKEND must be auto, pipewire, or existing.\n' >&2; exit 1 ;;
esac

case "${WIFI_BACKEND:-wpa_supplicant}" in
    wpa_supplicant) packages+=(wpa_supplicant) ;;
    existing) ;;
    *) printf 'WIFI_BACKEND must be wpa_supplicant or existing.\n' >&2; exit 1 ;;
esac

case "${INSTALL_TEST_TOOLS:-1}" in
    1) packages+=(libnotify findutils bluez-utils git) ;;
    0) ;;
    *) printf 'INSTALL_TEST_TOOLS must be 0 or 1.\n' >&2; exit 1 ;;
esac

"${as_root[@]}" pacman -Syu --needed "${packages[@]}"

qml_root=/usr/lib/qt6/qml/Quickshell
for module in . Io Widgets Wayland Hyprland Networking Bluetooth \
    Services/Mpris Services/Notifications Services/SystemTray Services/Pam; do
    if [[ ! -f "$qml_root/$module/qmldir" ]]; then
        printf 'Missing Quickshell module: %s\n' "$module" >&2
        exit 1
    fi
done

python3 - <<'PY'
import gi
gi.require_version("NM", "1.0")
gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")
from gi.repository import NM, Gio, GLib
print("Python NetworkManager and Bluetooth dependencies are available.")
PY

printf '\nDependencies installed. Follow the service/session setup below.\n'
```

## Service and session setup

Night Shift needs the [hyprsunset package](https://archlinux.org/packages/extra/x86_64/hyprsunset/).
For an existing installation that only needs this new dependency:

```sh
sudo pacman -S --needed hyprsunset
```

The quick settings panel detects it automatically while open; no Quickshell
restart is needed. Enabling starts a session-local daemon with the saved warmth
(4000 K by default). The color-temperature slider appears while enabled, ranges
from 1500 K to 6500 K in 50 K steps, and saves its setting in `quick-controls.json`. Disabling
restores neutral colors. A separate autostart entry or systemd
service is unnecessary. An already running daemon is reused, preserving its
gamma setting. New daemons read the default hyprsunset config, so any configured
schedule can still change the filter. The panel reads its current state every
five seconds while open.

Installing packages does not migrate an existing desktop's service setup.
Enable NetworkManager when it is the network manager you intend to use; avoid
having another service manage the same interfaces. Enable Bluetooth if needed:

```sh
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
```

For the PipeWire option, run the following as your desktop user inside the
logged-in session (without sudo):

```sh
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
pactl info
```

Network and power actions follow the machine's polkit/logind permissions. If a
policy requires interactive authorization, the session also needs a running
polkit authentication agent; this config does not implement one.
Battery charge-limit writes also use that agent. Limits are available only when
the battery driver exposes `charge_control_end_threshold`; peripheral batteries
are excluded. Driver-supported values and persistence across reboot vary. See
[Battery](README.md#battery) for applying limits and restoring full charging.

For DDC brightness, enable DDC/CI in the monitor's menu. The installed Arch
`ddcutil` package supplies `/usr/lib/modules-load.d/ddcutil.conf` to load
`i2c-dev` at boot and a udev rule granting active local users access to display
I²C devices. Reboot after initial installation, or load the module now with
`sudo modprobe i2c-dev`. Check access as your normal user with
`ddcutil detect --brief`; the widget must be able to use it without sudo.
Brightness support still depends on the monitor, GPU, and connection.

Run the shell inside Hyprland with a working session D-Bus. The locker also
requires the compositor's `ext-session-lock-v1` support and a working
`/etc/pam.d/login` authentication stack. Keep only one notification daemon
running so Quickshell can own `org.freedesktop.Notifications`.

From this repository directory:

```sh
quickshell --no-duplicate --path .
```

Add the equivalent command with an absolute config path to your Hyprland
autostart. For example, with the tested Lua configuration and the config at
`~/.config/quickshell`:

```lua
hl.exec_cmd("quickshell --no-duplicate")
```

## Verification

From this repository directory, these checks exercise parsing and simulated or
isolated integrations without changing live connections or powering off the PC:

```sh
bash scripts/check.sh
python3 scripts/test-app-themes.py
python3 scripts/test-settings.py
python3 scripts/test-quick-controls.py
python3 scripts/test-monitoring.py
python3 scripts/test-workspaces.py
python3 scripts/test-wallpaper-transitions.py
python3 scripts/test-network.py
python3 scripts/test-bluetooth.py
python3 scripts/test-notifications.py
python3 scripts/test-power.py
python3 -m unittest discover -s tests/brightness -v
python3 -m unittest discover -s tests/battery -v
python3 -m unittest discover -s tests/system_info -v
```

The quick-controls tests mock Night Shift commands and do not change screen
colors, the live theme, or DND. To check tmux theme syncing with temporary
servers, install `tmux` and run `python3 scripts/test-tmux-themes.py`.

The workspace capture smoke test needs a running Hyprland session and at least
one open app window. It briefly displays a click-through preview and checks real
capture without switching workspaces or focusing another window:

```sh
python3 scripts/test-workspace-preview.py
```

The Qt tools default to `/usr/lib/qt6/bin`. `scripts/check.sh` accepts `QMLFORMAT`;
some test runners also accept `QMLTESTRUNNER`. Runners with a fixed tool path
need that path adjusted on other distributions. Hardware operation and real
lock/unlock authentication still need verification on each target machine.
