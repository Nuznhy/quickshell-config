# Quickshell bar

A Hyprland bar with selectable dark/light palettes, one panel per screen, and shared
system state. `shell.qml` is the entry point.

## Layout

```text
shell.qml                 Screen lifecycle; creates a Bar for each screen
config/
  Settings.qml            Device name, commands, dimensions, polling intervals
  Theme.qml               Active palette, typography, and saved appearance
  Palettes.js             Dark/light preset definitions
  Icons.qml               Window-class to Nerd Font icon mapping
  qmldir                  Singleton registrations
services/
  Audio.qml               Output discovery, volume/mute state, and audio actions
  Keyboard.qml            Keyboard layout polling and switching
  SystemStats.qml         CPU and memory sampling
  Time.qml                Shared system clock
  Workspaces.qml          Workspace state and window icon discovery
  qmldir                  Singleton registrations
modules/
  bar/Bar.qml             Panel layout and popup-close signal
  bar/widgets/            Visual bar widgets
  network/Network.qml     Optional network widget (not enabled)
components/
  ThemePicker.qml         Appearance controls and palette previews
  ThemeDropdown.qml       Active-theme card and floating theme menu
  PaletteSwatches.qml     Shared palette color previews
  ApplicationMixer.qml    Playback-stream volume sliders and mute controls
  AudioDeviceDropdown.qml  Collapsible output and microphone selectors
  AudioLevelControl.qml    Volume slider, percentage, and separate mute icon
  AudioSlider.qml          Live slider with throttled writes and stable release behavior
  DropdownWidget.qml      Reusable popup container
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

## Customize

- Click the palette icon beside the power button, then click the active-theme
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
- Top Margin and Side Margins adjust spacing from screen edges (0–40 px).
  Corner Rounding adjusts the bar's radius from square corners to a pill shape
  (0–21 px at the default height). These apply live across screens and persist
  with the other appearance settings; older saved settings default to zero.
- The choice is saved as `theme.json` in Quickshell’s per-shell state directory
  (`~/.local/state/quickshell/by-shell/<shell-id>` by default), independently of
  the dotfiles. The initial theme is Rosé Pine Dark. Save failures appear in
  the picker; missing or invalid settings fall back to the default.
- Edit palette definitions in `config/Palettes.js` and fonts in `config/Theme.qml`.
  Theme selection affects this shell; application/GTK themes are configured separately.
- Change the keyboard device, launcher commands, spacing, and refresh intervals
  in `config/Settings.qml`. Defaults retain the previous configuration.
- Reorder or add widgets in `modules/bar/Bar.qml`.
- Add application icons in `config/Icons.qml`.

To add a widget, create a QML type in `modules/bar/widgets/`, import config and
any needed services using the same relative paths as neighboring widgets, then
instantiate it in `Bar.qml`. Put shared polling/state in `services/` and register
new singleton types in `services/qmldir`. Keep processes and timers out of visual
widgets when their state can be shared. Local UI actions, such as opening the
logout launcher, can remain in the widget.

The network widget is retained as an optional prototype. Before enabling it,
review its `nmcli` parsing (escaped SSIDs and empty output), interface selection,
and password handling. Import `../network` from `Bar.qml` and supply its required
window reference with `Network { barWindow: barWindow }`. Its polling still lives
inside the widget. The active tray uses `QsMenuAnchor`; `TrayMenu.qml` is not wired
to it.

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
Right-clicking the bar widget
opens `pavucontrol`. Click outside or press Escape to dismiss the popup. Output-switching errors are shown in the popup.

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

The active bar needs compatible Quickshell/Qt 6 packages, Hyprland (`hyprctl`),
`jq`, `pactl`, `pavucontrol`, `free`, standard shell utilities, Linux `/proc`,
and JetBrainsMono Nerd Font. The configured logout action expects
`~/.config/hypr/scripts/logoutlaunch.sh`. The optional network widget needs
NetworkManager's `nmcli`.

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
and the logout launcher. The keyboard follows Hyprland layout-change events with a 2-second backup
poll; leave `keyboardName` empty to follow the active keyboard, or set it to
pin a device. Workspace discovery refreshes on all Hyprland events plus a 500 ms timer. These preserve
existing behavior; event-specific updates are a useful future optimization.

## Validation limitation

During this refactor, Qt 6 `qmlformat` parsed all files successfully. Live testing
was blocked before QML loading: the installed `quickshell` executable failed with
an undefined `QUntypedPropertyBinding` symbol in `Qt_6_PRIVATE_API`. Compatible
Quickshell and Qt packages are needed before visual and interaction checks can
be completed. Full lint still reports existing scope/metadata warnings, so a
successful syntax check does not establish runtime correctness.
