# Quickshell bar

A Hyprland bar with selectable dark/light palettes, one panel per screen, and shared
system state. `shell.qml` is the entry point.

See [Dependencies and Arch installation](DEPENDENCIES.md) for the complete
dependency list, a copyable install script, and service setup instructions.

## Layout

```text
shell.qml                 Screen lifecycle; creates a Bar for each screen
config/
  Settings.qml            Device name, commands, dimensions, polling intervals
  Theme.qml               Active palette, typography, and saved appearance
  Palettes.js             Dark/light preset definitions
  Icons.qml               Automatic system application icon lookup
  qmldir                  Singleton registrations
services/
  Audio.qml               Output discovery, volume/mute state, and audio actions
  Keyboard.qml            Keyboard layout polling and switching
  SystemStats.qml         Shared hardware sampling and monitoring history
  Time.qml                Shared system clock
  Notifications.qml       Notification daemon, history, DND, and app actions
  NetworkState.qml        Shared Wi-Fi, Ethernet, VPN, and connection state
  BluetoothState.qml      Bluetooth adapters, devices, discovery, and pairing
  Workspaces.qml          Workspace state and window icon discovery
  qmldir                  Singleton registrations
modules/
  bar/Bar.qml             Panel layout and popup-close signal
  bar/widgets/            Visual bar widgets
  network/Network.qml     Network status widget and control center dropdown
  notifications/NotificationToasts.qml  Notification popups on the active screen
components/
  ThemePicker.qml         Appearance controls and palette previews
  ThemeDropdown.qml       Active-theme card and floating theme menu
  PaletteSwatches.qml     Shared palette color previews
  ApplicationMixer.qml    Playback-stream volume sliders and mute controls
  AudioDeviceDropdown.qml  Collapsible output and microphone selectors
  AudioLevelControl.qml    Volume slider, percentage, and separate mute icon
  AudioSlider.qml          Live slider with throttled writes and stable release behavior
  DropdownWidget.qml      Reusable popup container
  NotificationCenter.qml Notification history and Do Not Disturb controls
  NotificationCard.qml   Shared notification card for popups and history
  NetworkCenter.qml      Connections, IP addresses, Wi-Fi passwords, and switches
  BluetoothCenter.qml    Bluetooth power, visibility, devices, and pairing prompts
  TrayMenu.qml            Optional menu appearance (not used by the tray)
scripts/check.sh          Parse every QML file with Qt 6 qmlformat
scripts/audio-status.sh   Read the default output and available devices
scripts/audio-select-output.sh  Change output and move existing playback streams
scripts/audio-select-input.sh   Change microphone and move existing recording streams
```

The dependency direction is entry point → modules → services/config. Shared
components may use config, but should not depend on a particular bar widget.
Services are singletons, so adding screens does not add another CPU, memory,
audio, keyboard, or workspace poller. Popup and hover state stay in each widget.

## Settings window

Click the gear button to open the separate Settings window. **Bar layout**
lets you drag widget cards within or between Start, Center, and End. The same
sections become Top, Middle, and Bottom for a vertical bar. Each switch controls
whether that widget appears; hidden cards retain their saved positions. Escape
cancels a drag, and dropping outside a section leaves the layout unchanged.

Changes apply immediately to every monitor and save automatically. Reset layout
restores the original widget order and visibility without changing appearance.
The clock can also be moved or hidden. Sections scroll when their contents exceed
the available space, and spacing is only inserted between displayed widgets.

**Appearance** contains palette, font, bar geometry, monitor visibility, application
themes, and the settings-button icon. Choose Gear, Sliders, Palette, Grid, Linux,
or Arch from the icon catalog. Select Custom to reveal the glyph field and image
picker; Reset restores the gear. **Wallpapers** contains monitor previews and a folder
gallery. Closing the settings window leaves the shell running.
To reopen it even if its bar button is hidden:

```sh
quickshell ipc -p ~/.config/quickshell call settings open
```

The same IPC target provides `close` and `toggle`. Widget layouts are stored in
`bar-layout.json` beside `theme.json` in Quickshell's per-shell state directory.
Hiding a widget does not turn off the notification daemon or other shared shell
services. The editor displays media and workspaces even when their bar content
is temporarily absent.

Run `python3 scripts/test-settings.py` for isolated layout, drag-and-drop,
visibility, orientation, and persistence checks. It uses Qt 6's test runner and
Quickshell with temporary state; it does not change your desktop layout.

## PC monitoring

Enable **PC monitoring** in Settings → Bar layout, then use the gear next to its
switch to configure metrics. CPU and Memory remain available as separate widgets.
Each metric supports **Off**, **Short** (icon and meter), and **Long** (meter and
numbers). CPU load and RAM start in Long mode; the new widget starts disabled
to preserve existing layouts. Preferences save separately in `monitoring.json`.

Left-click opens graphs for all supported metrics, even those hidden from the
bar. Samples are taken every two seconds and retained for ten minutes in memory
while monitoring is enabled. Right-click opens `btop` in the default terminal:
`xdg-terminal-exec`, `$TERMINAL`, the Hyprland terminal setting, then installed
terminal fallbacks. Errors appear on hover and in the history popup.

CPU/GPU load and temperature, RAM/VRAM usage, and exposed CPU/GPU/battery power
sensors are discovered automatically. Settings offer a CPU temperature source
override. Unavailable sensors show a reason; no driver or permission changes are
made. Power readings describe individual sources, not whole-PC consumption.
Meters use sensor limits where available; otherwise temperature uses 100°C and
power graphs use their labelled recent peak. Vertical memory values use `G` for
GiB. History resets when Quickshell restarts.

Run `python3 scripts/test-monitoring.py` for isolated sensor, terminal, controls,
history, and settings-persistence checks.

## Customize

- Open Settings → Appearance, then click the active-theme
  card to toggle a floating menu of names and color swatches. Choose Rosé Pine,
  Catppuccin, Gruvbox, Solarized, Everforest, or Neutral. Every preset supports
  Dark and Light. Scroll the menu for more themes; selecting one closes the menu
  and updates the full preview. Changes apply immediately across bars and popups.
  The menu does not resize the widget. Click outside or press Escape to close it.
- Added catalog palettes are bundled for offline use. See
  [palette sources](config/PALETTE_SOURCES.md) for upstream links and color mappings.
- The Bar Opacity slider adjusts the entire bar, including its text and icons,
  from 20% to 100% across all screens. Popups remain opaque for readability.
  Opacity updates live and is saved alongside the palette and mode.
- Bar Font Size adjusts bar text from 12–28 px, with bar thickness adapting to
  larger text. Bar Position places the bar on the Top, Left, Bottom, or Right.
  Side bars use a narrow rail with vertically stacked widget contents: workspaces,
  tray, and media at the top, the clock centered, and system controls at the bottom.
  The two end sections scroll independently when needed, keeping the clock visible.
  Popups open inward from the selected edge. Font size and position are saved.
- Edge Margin and End Margins adjust spacing from screen edges (0–40 px).
  Corner Rounding adjusts the bar's radius from square corners to a pill shape
  (0–21 px at the default height). These apply live across screens and persist
  with the other appearance settings; older saved settings default to zero.
- The choice is saved as `theme.json` in Quickshell’s per-shell state directory
  (`~/.local/state/quickshell/by-shell/<shell-id>` by default), independently of
  the dotfiles. The initial theme is Rosé Pine Dark. Save failures appear in
  the picker; missing or invalid settings fall back to the default.
- Edit palette definitions in `config/Palettes.js` and fonts in `config/Theme.qml`.
  Enable individual targets under Application themes to sync app colors with the
  shell. See [Application themes](APP_THEMING.md) for supported apps, toolkit
  setup, and restoration. All app switches start off.
- Change the keyboard device, launcher commands, spacing, and refresh intervals
  in `config/Settings.qml`. Defaults retain the previous configuration.
- Reorder and show/hide widgets in Settings → Bar layout. New widget types are
  registered in `config/BarLayoutData.js`.
- In Appearance → Monitor bars, switch the bar on or off for each connected
  monitor. Choices persist by output name (for example `DP-1`); new outputs
  default to enabled. One connected bar stays available for restoring others.
  If unplugging monitors leaves only disabled outputs, the first remaining
  output temporarily shows a bar without changing the saved preferences.
- In Settings → Wallpapers, monitor cards sit side by side and wrap on smaller
  windows. Drop a local image onto a monitor's card, click its preview to browse,
  or use the folder button. Images are checked before replacing the current
  wallpaper; invalid files leave it unchanged. Each card has a Clear button.
  Choose folder loads its images into a thumbnail gallery (without scanning
  subfolders). Select a monitor under Apply to, then click a thumbnail. The folder
  is remembered across restarts; removing it from the gallery keeps current
  wallpapers. Images fill the screen without distortion, cropping where necessary.
  Paths are saved by output name
  and restored after restart or reconnect; keep the selected files on disk.
  Wallpaper rendering runs directly in Quickshell's background layer, independently
  of bar visibility, and does not require Noctalia or another wallpaper daemon.
  Clear removes Quickshell's wallpaper for that output without deleting the image.
- Dropdowns share the same outer padding, controlled by `popupPadding` in
  `config/Settings.qml` (12 px by default).
- Workspace icons come from application desktop entries and the system icon theme,
  displayed in their original colors at full opacity. All distinct apps on each
  workspace are shown. Lookup matches desktop IDs, StartupWMClass, and the initial
  window class automatically; apps without a usable icon get a generic fallback.
  No per-app icon mapping is required.
- Click an app icon to switch to its workspace, focus its window, and move the
  pointer to its center. If the app has several windows on that workspace, the
  most recently focused one is selected. Clicking the workspace number or empty
  space still switches workspaces normally.
- Only workspaces with open app windows appear, sorted by their actual workspace
  numbers. Empty workspaces are hidden, including the active one when empty.
- App-list changes settle for 100 ms before updating. Moved apps pop out of the
  old workspace and into the new one; unchanged icons keep their hover state.
  Workspace widths resize smoothly as icons change. New workspaces slide in;
  empty ones slide out after their last icon finishes popping out, smoothly
  shifting neighboring workspaces and the tray.
- App icons show a small attention badge when one of their windows is marked
  urgent by Hyprland. Clicking a badged icon focuses that urgent window; the badge
  clears when it is acknowledged. This follows window urgency, not unread message
  counts or every desktop notification.
- Telegram instead follows its own tray unread indicator, including muted unread
  items when Telegram includes them in its badge. Focusing Telegram does not clear
  the badge; it clears when Telegram resets its tray indicator. Keep Telegram's
  tray icon enabled for this behavior; without it, window urgency is used.
- Click the tray chevron to open a compact icon grid. The popup fits its contents
  and wraps after six columns, resizing as tray apps appear or disappear. Hover
  an icon for its name; left-click activates it, middle-click performs its
  secondary action, and right-click opens its menu. Menu-only apps open their
  menu on left-click too. Click outside or press Escape to close the dropdown.
- Between workspaces and the tray, the current media widget shows artwork with
  artist above title. Both lines truncate with an ellipsis; hover for the full
  text. Players are discovered through MPRIS, preferring playing media over
  paused tracks. The widget hides when neither is available, and missing artwork
  uses a music icon. No player-specific configuration is required.
  Left-click opens artwork, full track details, playback progress, and Previous,
  Play/Pause, and Next controls. Right-click toggles play/pause; scroll up for
  the previous track and down for the next. Controls follow the player's reported
  capabilities; elapsed time and duration appear when supported.
  Click or drag the timeline to seek; the time label previews the chosen position
  while dragging and the seek is sent on release. Changing tracks or closing the
  dropdown cancels an unfinished drag. Players without seeking support show a
  read-only timeline.
- Click the central date/time to open the themed calendar. Today is highlighted,
  and weekday order follows your locale. Browse with the month arrows, select a
  date, or press Today to return to the current month. Left/right arrow keys
  browse months, Home returns to today, and Escape or clicking outside closes it.
  Opening the calendar resets it to today.

To add a widget, create a QML type in `modules/bar/widgets/`, import config and
any needed services using the same relative paths as neighboring widgets, then
register its ID, label, default section, and component path in `config/BarLayoutData.js`. Put shared polling/state in `services/` and register
new singleton types in `services/qmldir`. Keep processes and timers out of visual
widgets when their state can be shared. Local UI actions, such as opening the
power dropdown, can remain in the widget.

The active tray uses `QsMenuAnchor`; `TrayMenu.qml` is not wired to it.

## Network control center

Click the network icon beside the sound widget to view active connections and
their local IPv4/IPv6 addresses. Addresses are selectable for copying. Ethernet
adapters have connect/disconnect switches; Wi-Fi has a radio switch and a list
of nearby networks with signal strength, security, and connection controls.
Wi-Fi discovery runs while the panel is open.

Saved Wi-Fi credentials are reused. New WPA/WPA2/WPA3 personal networks prompt
for a password in the panel, delivered through Quickshell's NetworkManager API
without placing it in process arguments or files. The field clears on submission
or closing the panel. Use Advanced for enterprise, hidden, and other special
network configurations.

Each saved NetworkManager VPN or WireGuard profile has an on/off switch. Add VPN
and Advanced open `nm-connection-editor` to configure/import profiles and any
required credentials. Provider apps that manage tunnels outside NetworkManager
are not controlled here. Connecting a VPN requires an existing configured profile
and its NetworkManager plugin where applicable.

Connection details come from libnm, preserving names containing punctuation and
all interface addresses. `nmcli monitor` triggers refreshes, backed by a 2.5-second
poll while open and a 10-second poll while closed. Operations show pending/error
states; failed switches return to the reported state.

Run `python3 scripts/test-network.py` for metadata and simulated UI interaction
checks. These do not modify live network connections. Set `QMLTESTRUNNER` if the
Qt 6 runner is not installed at `/usr/lib/qt6/bin/qmltestrunner`.

## Power and session lock

The power dropdown has Lock, Sleep, Reboot, and Shut down icons.
Reboot and shutdown require confirmation in the dropdown. Failed commands show
an error. These actions do not depend on Noctalia or an external logout script.

Lock launches this configuration's own `modules/lock/shell.qml` in a separate
Quickshell process. It uses Wayland's session-lock protocol on every monitor and
PAM's `login` service to authenticate the current user with the system password.
Only successful PAM authentication unlocks the session. Passwords are not passed
to commands or saved; fields and pending responses are cleared after use.
The lock screen inherits the bar's colors when launched from the power menu.
File watching is disabled in the locker so editing the bar does not reload it.

Sleep waits for the compositor to confirm the lock is secure, then runs
`systemctl suspend`. Reboot and shutdown use `systemctl reboot` and
`systemctl poweroff`, respecting the system's normal permissions and inhibitors.
On another PC, this requires a compositor supporting `ext-session-lock-v1`,
Quickshell's PAM module, an appropriate `/etc/pam.d/login`, and systemd.

For a lock keybinding, run `python3 ~/.config/quickshell/scripts/power-action.py lock`.
For lock-then-sleep, use `sleep` instead of `lock`. Run
`python3 scripts/test-power.py` for mocked power and authentication checks. These
do not lock, suspend, reboot, power off, or check your real password.
An actual compositor lock/unlock has not been exercised by these tests. If a
session-lock process crashes, the compositor keeps the session locked; do not
kill the locker as a way to unlock it.

## Monitor brightness

Click the sun icon beside the volume widget for a brightness slider per display.
Displays are discovered automatically on opening, every 15 seconds while open,
and with Refresh, including plugged/unplugged monitors. There are no configured
monitor names or I2C bus numbers. Slider writes are queued, keeping the latest
requested value per monitor while slower hardware commands finish.

External monitors use `ddcutil` and DDC/CI; enable DDC/CI in the monitor's own menu
and ensure your distribution grants your user access to `/dev/i2c-*` (the
`i2c-dev` module must be loaded). Built-in screens are discovered through Linux
backlight devices and controlled with `brightnessctl`. Install these tools on
each PC as needed. Unsupported monitors remain visible with an explanation.
This adjusts hardware brightness; there is no software dimming fallback.

Run `python3 -m unittest discover -s tests/brightness -v` to test discovery and
hardware command handling with simulated displays, without changing brightness.

## Bluetooth control center

Click the Bluetooth icon to view connected, paired, and nearby devices. The
panel matches the network controls, with power and Allow discovery switches.
Allow discovery makes this computer visible to other devices for three minutes;
switch it off to end visibility early. Scan searches for nearby devices for up
to 30 seconds. Closing the panel stops scans started by this shell.

Pair or connect devices, disconnect them, and confirm Forget to remove a pairing.
Battery levels appear when the device reports them. PIN/passkey entry and pairing
confirmation appear in the panel for pairing initiated here; this does not replace
the system's default pairing agent. Multiple adapters can be selected in the panel.
Operations show progress and errors, with switches following the adapter's state.

Bluetooth requires BlueZ, Quickshell's Bluetooth module, Python 3, and PyGObject.
Run `python3 scripts/test-bluetooth.py` for pairing-agent and simulated UI checks;
these do not change real Bluetooth devices or adapter settings.

## Dependencies and development

Click the volume widget to toggle its popup, centered below the bar. Hovering
only changes the pointer cursor. Output and Microphone dropdowns show the current
devices and open floating lists over the mixer without resizing the volume
widget. Click outside a list or press Escape to dismiss it. Only one selector opens at a time,
and both reset to collapsed when the volume popup closes. Select an output;
the selected device becomes the default
and existing playback streams are moved to it. The list refreshes automatically
when devices connect or disconnect. Scroll over the bar widget or volume meter
to change volume. Each device selector has a slider, percentage, and separate
mute icon beneath it. The output slider supports 0–150%; microphone gain supports
0–100%. Muted icons are highlighted, and moving a slider does not toggle mute.
Middle-clicking the bar widget opens `pavucontrol`; right-clicking toggles output
mute. Click outside or press Escape to dismiss the popup. Output-switching errors are shown in the popup.

The Microphone dropdown excludes speaker-monitor sources. Selecting a microphone
sets the default input and moves existing recording streams to it. Opening the
selector does not start recording. Device changes and disconnections refresh
automatically; unavailable selectors are disabled.

The Applications section lists active playback streams by application and media
title. Each stream has a 0–150% volume slider and a mute/unmute button. All audio
sliders apply changes while dragging, throttled to 60 ms with a final update on
release. The shell updates displayed levels immediately, combines queued volume
changes, and rejects polls started before a write. A fresh read reconciles the
server state after writes complete, including failures. Apps may
have multiple streams or disappear when playback stops; the list updates
automatically. These controls adjust playback streams, not microphone inputs.

## Notifications

Left-click the bell to open notification history; right-click it to toggle Do
Not Disturb. Its dot indicates unread entries; opening the panel marks them
read. The panel also has a DND switch. Do Not Disturb hides popups, including critical ones,
while retaining history. Turning it off does not replay missed popups.

The daemon displays up to three cards on the active screen and stores the most
recent 100 notifications. Normal popups hide after six seconds; explicit app
timeouts expire the live notification. Critical notifications and timeout-zero
notifications remain visible until dismissed or moved into history. Hovering
pauses expiration. App actions work while their notification is still live;
closed notifications remain as text history. Transient notifications are never
saved. Clear individual entries with × or use Clear all.

Open invokes the app's notification action, closes history, and focuses the
sender's most recently used matching window across workspaces, centering the
cursor on it. Matching uses the sender's desktop entry, StartupWMClass, and app
name; window titles are not used. It briefly waits for newly opened windows.
If no sender window can be matched, the app's own action still runs.

History and DND are saved locally in `Quickshell.statePath("notifications.json")`
(under the shell's XDG state directory), including notification text. History
survives restart; application actions do not. No notification sounds are played.

Only one desktop notification daemon can own the session's notification service.
For Noctalia v5, `integration/noctalia-notifications.toml` can be copied into
`~/.config/noctalia/` to disable its daemon while retaining its other features.
Reload with `noctalia msg config-reload`. Run Quickshell with your session for
notification handling to remain available after login.

Codex CLI can send completion, approval, and question alerts through Ghostty's
desktop notification support. In `~/.codex/config.toml`, add to the existing
`[tui]` section:

```toml
notifications = true
notification_method = "osc9"
notification_condition = "always"
```

Restart Codex after editing. Ghostty's `desktop-notifications` must be enabled
(its default). These alerts go through the same Quickshell history and DND as
other applications. Other terminals must support OSC 9 desktop notifications.
See the [Codex notification settings](https://learn.chatgpt.com/docs/config-file/config-advanced#notifications).

Optional commands for keybindings:

```sh
quickshell ipc -p ~/.config/quickshell call notifications toggleDnd
quickshell ipc -p ~/.config/quickshell call notifications dnd true
quickshell ipc -p ~/.config/quickshell call notifications status
quickshell ipc -p ~/.config/quickshell call notifications clear
```

`python3 scripts/test-notifications.py` tests the daemon on a private D-Bus
session using temporary state. It requires Python 3, `dbus-run-session`,
`notify-send`, and `gdbus`, and does not touch your desktop history.

The active bar needs compatible Quickshell/Qt 6 packages, Hyprland (`hyprctl`),
`jq`, `pactl`, `pavucontrol`, `free`, standard shell utilities, Linux `/proc`,
and JetBrainsMono Nerd Font. The network control center needs
NetworkManager, `nmcli`, `nm-connection-editor`, Python 3, PyGObject, and libnm
introspection (`python-gobject` and `libnm` on Arch-based systems).

From this directory:

```sh
bash scripts/check.sh
/usr/lib/qt6/bin/qmllint shell.qml config/*.qml services/*.qml modules/bar/*.qml modules/bar/widgets/*.qml components/*.qml modules/network/*.qml
quickshell -p .
```

`check.sh` checks parsing without rewriting files. Set `QMLFORMAT` to the Qt 6
formatter path on systems where it is installed elsewhere. Full `qmllint` also
reports semantic/style warnings; Quickshell platform-selected types and enum
metadata can produce diagnostics that need runtime verification.

To format a changed file:

```sh
/usr/lib/qt6/bin/qmlformat -i path/to/File.qml
```

After changes, check each screen, workspace switching/icons, clock updates,
keyboard switching, volume scrolling/mute display/hover popup, tray actions,
and the power menu. The keyboard follows Hyprland layout-change events with a 2-second backup
poll; leave `keyboardName` empty to follow the active keyboard, or set it to
pin a device. Workspace discovery refreshes on all Hyprland events plus a 500 ms timer. These preserve
existing behavior; event-specific updates are a useful future optimization.

## Validation

The shell loads on Quickshell 0.3.1. Notification integration checks cover real
D-Bus delivery and replacement, DND, timeouts, transient notifications, client
closure, actions, history limits, hot reload, and persistence across restart.
Full lint still reports platform metadata warnings for Quickshell window types;
parsing alone does not establish runtime correctness.
