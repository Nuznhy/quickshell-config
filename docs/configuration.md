# Configuration

[Home](../README.md) · [Installation](installation.md) · [Application themes](application-themes.md)

Open Settings from the bar or run:

```sh
quickshell ipc -p ~/.config/quickshell call settings open
```

The same IPC target accepts `close` and `toggle`.

## Settings

- **Bar layout:** reorder widgets, enable or hide them, and open feature settings.
- **Appearance:** choose a palette, light/dark mode, font, UI kit, bar geometry,
  monitor visibility, and application themes.
- **Wallpapers:** choose images per monitor, with shared or separate light/dark images.
- **Lock screen:** configure Hyprlock theme syncing, background, and optional ASCII art.

Changes apply across screens and save automatically. Device names, command
choices, and polling defaults live in [config/Settings.qml](../config/Settings.qml).
UI kit authoring is covered in [UI kits](ui-kits.md).

The quick settings panel includes Night Shift, theme mode, DND, and system
information. Hardware features depend on the device and its drivers. Battery
charge limits and firmware power profiles may require polkit authorization;
limits can reset after reboot.

## Calendar

Install the [optional calendar packages](installation.md#arch-linux-packages).
In Settings → Bar layout → Clock settings, save a private HTTPS iCalendar
(`.ics`) URL and enable the feed. The clock popup shows events for the selected day.

The URL is stored in the session's Secret Service keyring, with no plaintext
fallback. Treat it as a password: anyone with the URL can read the feed. The URL
is passed through stdin; events stay in memory and are fetched only while the
calendar is active. Remove the feed from Clock settings when it is no longer needed.

## Notifications

Quickshell must be the only notification daemon on the session bus. For
Noctalia, use the provided [notification configuration](../integrations/noctalia-notifications.toml)
to disable its daemon.

History and DND survive restarts. Notification text is stored locally in
`notifications.json`; transient notifications are not saved.

```sh
quickshell ipc -p ~/.config/quickshell call notifications toggleDnd
quickshell ipc -p ~/.config/quickshell call notifications status
quickshell ipc -p ~/.config/quickshell call notifications clear
```

## Saved state

The Desktop / TV widget uses Hyprland's `config.monitors` controller. The controller
remembers the confirmed layout and desktop workspace placement across config
reloads in the same Hyprland session. A new login starts on Desktop. TV switches
still require confirmation; reloading before confirmation restores Desktop.
Session state lives in `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/desktop-tv-state`.

Preferences are stored in Quickshell's per-shell XDG state directory, normally
`~/.local/state/quickshell/by-shell/<shell-id>/`. This includes theme, bar layout,
workspace appearance, monitoring, calendar preferences, and quick controls.
Application-theme backups live in `app-themes/` there; keep them for restoration.

For lock and sleep setup, see [Installation](installation.md#session-setup).
