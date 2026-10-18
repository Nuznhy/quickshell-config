# Quickshell bar

A configurable Hyprland shell built with Quickshell and Qt Quick. Includes a bar
for each screen, shared desktop services, and selectable light and dark themes.

## Features

- Configurable widget layout, horizontal and vertical bars, and workspace previews.
- Audio, network (including connection IP addresses and DNS servers), Bluetooth, brightness, media, battery, and system monitoring.
- Notifications with history and Do Not Disturb, plus an optional calendar feed.
- Per-monitor wallpapers, wallpaper-derived colors, UI kits, and application themes.
- Quick settings, Night Shift, and Hyprlock integration.

## Getting started

Place this repository at `~/.config/quickshell`, install the
[dependencies](docs/installation.md), then run inside Hyprland:

```sh
quickshell --no-duplicate --path ~/.config/quickshell
```

Open Settings from the bar or use:

```sh
quickshell ipc -p ~/.config/quickshell call settings open
```

## Documentation

- [Installation](docs/installation.md) — packages and session services.
- [Configuration](docs/configuration.md) — settings, calendar, notifications, and saved state.
- [Application themes](docs/application-themes.md) — supported integrations and restoration.
- [Development](docs/development.md) — architecture, checks, and contributing.
- [Code style](docs/code-style.md) — QML, JavaScript, Python, and shell conventions.
- [UI kits](docs/ui-kits.md) — extending the shared visual system.
- [Palette sources](docs/palettes.md) — upstream attribution and color roles.

## Project structure

```text
shell.qml             Main shell entry point
gallery.qml           UI gallery entry point
modules/<feature>/    Feature UI and settings panels
services/<feature>/   Shared state, polling, and system integration
components/           Reusable ui/, popup/, and shared/ controls
config/               Preferences, palettes, and design configuration
kits/                 UI kit implementations and registry
scripts/<feature>/    Runtime command helpers
scripts/checks/       Verification tools; scripts/check.sh runs the checks
integrations/         External application configuration
tests/                Feature tests, fixtures, and runners/
docs/                 User and contributor guides
```

Run `bash scripts/check.sh` before submitting changes. See
[development](docs/development.md) for feature tests and
[AGENTS.md](AGENTS.md) for repository rules.
