# Installation

[Home](../README.md) · [Configuration](configuration.md) · [Development](development.md)

Run the shell on Linux inside a Hyprland session with Quickshell, Qt 6, and a
working session D-Bus. Audio requires a PulseAudio-compatible server, such as
PipeWire with `pipewire-pulse`.

## Arch Linux packages

Install the core runtime:

```sh
sudo pacman -S --needed quickshell hyprland qt6-base qt6-declarative qt6-wayland \
  qt6-svg qt6-imageformats ttf-jetbrains-mono-nerd fontconfig hicolor-icon-theme \
  adwaita-icon-theme bash coreutils grep procps-ng jq python libpulse pavucontrol
```

Keep your existing audio server. A new PipeWire setup also needs `pipewire`,
`pipewire-pulse`, and `wireplumber`.

Install the packages for the features you use:

| Feature | Arch packages |
| --- | --- |
| Network | `networkmanager`, `libnm`, `python-gobject`, `nm-connection-editor`; your NetworkManager Wi-Fi backend and VPN plugins |
| Bluetooth | `bluez`, `python-gobject`, `glib2` |
| Brightness | `brightnessctl` for built-in displays; `ddcutil` for external monitors |
| Night Shift | `hyprsunset` |
| Lock and sleep | `hyprlock`, `hypridle` |
| Battery limits and power profiles | `polkit` and a session authentication agent; supported hardware |
| System information and updates | `pciutils`, `pacman-contrib` |
| Monitoring | `btop` and a terminal; NVIDIA metrics also use the installed driver's `nvidia-smi` |
| Wallpaper color extraction | `imagemagick` |
| Calendar feed | `gnome-keyring`, `libsecret`, `python-gobject`, `python-icalendar`, `python-recurring-ical-events` |
| Development | `qt6-declarative`, `findutils`, `git`; notification tests also need `libnotify`, `dbus`, `glib2` |

Application-specific requirements are listed in [Application themes](application-themes.md).

## Session setup

Start Quickshell with your Hyprland session:

```sh
quickshell --no-duplicate --path ~/.config/quickshell
```

Enable NetworkManager and Bluetooth if you use them. Keep only one network
manager for each interface and one desktop notification daemon.

For locking, provide `~/.config/hypr/hyprlock.conf` and merge the
[Hypridle configuration](../integrations/hypridle/hypridle.conf) into
`~/.config/hypr/hypridle.conf`. Start Hypridle through your session or its user
service:

```sh
systemctl --user enable --now hypridle.service
```

The user service needs the session's `WAYLAND_DISPLAY` and
`HYPRLAND_INSTANCE_SIGNATURE`. Lock requests use `loginctl lock-session`;
Hypridle launches Hyprlock and locks before suspend.

For external brightness, enable DDC/CI in the monitor settings and check
`ddcutil detect --brief` as your normal user. An initial setup may need
`sudo modprobe i2c-dev`. Power and hardware writes follow system polkit permissions.

Next: [configure the shell](configuration.md).
