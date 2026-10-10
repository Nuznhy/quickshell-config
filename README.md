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

## iCalendar feed

The clock popup displays one private **HTTPS iCalendar (.ics) feed**, including
Google Calendar's **Secret address in iCal format**. There is no Google account
login, OAuth, GNOME Online Accounts, or Evolution Data Server dependency.
The integration only reads events and is off by default.

On Arch, install these optional packages:

```sh
sudo pacman -S --needed gnome-keyring libsecret python-gobject python-icalendar python-recurring-ical-events
```

Open **Settings → Bar layout → Clock’s cog**, paste the private HTTPS address into
the masked field, and click **Save feed**. Unlock GNOME Keyring if prompted.
Saving enables the feed and refreshes events automatically. The field clears as
soon as you save or leave the calendar settings or close Settings. The saved address is never read back into
that field. No terminal command is needed to configure a feed.

The UI passes the address to the helper through a private stdin pipe. It is stored
with libsecret in your default Secret Service keyring (normally GNOME Keyring),
never in command arguments, Quickshell preferences, or a plaintext fallback file.

For Google Calendar, open its website → Settings → select your calendar →
**Integrate calendar → Secret address in iCal format**. Copy that address into
the masked field in Clock settings. Your calendar does not need to be made public. Some managed
accounts do not expose this address. See [Google's instructions](https://support.google.com/calendar/answer/37648?hl=en-GB).
Clear the clipboard and any clipboard-manager history after pasting a private URL.

Enable **Show iCalendar events** in Clock settings, then open the clock popup. Days containing events
have a dot; a scrollable agenda appears to the right of the calendar. Switching
days fades between event lists in a fixed-height panel, reusing the list model
and the already-loaded month data. Recurring occurrences,
exceptions, all-day events, and events spanning midnight are supported. Timed
events use your system timezone; all-day dates stay on their original dates.
Refresh downloads the feed again. The provider's feed may lag behind changes
made in its app. Automatic refresh runs every five minutes while the popup is
open; opening or changing months also fetches. Each popup has an isolated reader.

To replace the URL, paste a new address in **Clock settings** and click
**Save feed**. **Remove feed** deletes the saved address and disables the feed.
Keyring errors appear in the popup; a failed save keeps the previously stored feed.

Turn off **Show iCalendar events** to immediately clear displayed events in all popups. Removing
the saved URL does not revoke it at the provider. For Google, reset the secret
address in its calendar settings if you want to invalidate an exposed link.

### Credential and data protection

**A private feed URL is a bearer secret:** anyone holding it can read the feed
without logging in. iCalendar is a data format, not encryption. The implementation
requires HTTPS with certificate verification, rejects redirects (including HTTPS
to HTTP), and does not use environment-configured HTTP proxies. If your provider
redirects, configure its direct HTTPS feed address. There is no HTTP fallback,
certificate bypass, account password, OAuth token, or embedded login flow.

Use a **password-protected GNOME keyring** and a working Secret Service on your
session D-Bus. On Hyprland, your login manager/PAM can unlock the keyring, or you
can unlock it interactively with Seahorse. This integration does not change PAM
or weaken keyring settings. It will not store the URL outside the keyring when
Secret Service is unavailable. An unlocked keyring is not protection against
compromised programs running as your user.

Only the enabled preference is persisted in
`Quickshell.statePath("calendar-feed.json")`. Feed bytes and displayed events are
kept in process memory, with no calendar cache on disk. Closing the popup or
turning the integration off cancels its reader and clears its event model; this
is not a guarantee of cryptographic memory erasure or protection against swap.
The reader disables core dumps and has download, memory, CPU and wall-time limits.
Feeds over 5 MiB are rejected; output is limited to 2,000 occurrences, with a
warning if truncated. Only the visible six-week range is sent to the UI, though
an iCalendar subscription downloads the provider's entire feed to filter locally.

The URL exists briefly in the masked QML input and private write request during
setup; it is never included in command arguments or logs. Network and parser failures
use fixed messages rather than raw exceptions. Event titles are rendered as plain
text; attachments, links and alarms are not fetched or executed. Failed refreshes
clear old results and show an error; there is no offline cache. The ordinary date
grid works without the optional packages.

Validation: `python3 -m unittest discover -s tests/calendar -v` and
`bash scripts/check.sh`. Tests use synthetic feeds, fake keyring/network calls,
and isolated shell state, without reading or changing your real keyring.

References: [libsecret API](https://gnome.pages.gitlab.gnome.org/libsecret/libsecret-python-examples.html),
[iCalendar recurrence library](https://recurring-ical-events.readthedocs.io/en/latest/user-guide/examples.html).

## Design system

All shell surfaces share the tokens in `config/Design.qml` and the primitives in
`components/ui/`. `Theme` owns palettes and saved preferences; `Design` derives
presentation from them without writing settings or depending on services.
Existing bar font, size, geometry, and workspace capsule settings remain intact.

Import the primitives with a namespace to avoid collisions with Qt's controls:

```qml
import "../config"
import "ui" as UI

UI.Button {
    text: "Connect"
    variant: "primary"
    busy: connectionPending
    enabled: deviceAvailable
    onClicked: requestConnection()
}
```

Use the relative path to `components/ui` from the consuming file. Features own
service calls, validation rules, and persistence; primitives own appearance,
keyboard behavior, and interaction feedback.

| Foundation | Shared values / roles |
| --- | --- |
| Spacing | `space2`, `space4`, `space8`, `space12`, `space16`, `space20`, `space24`, `space32` |
| Layout | `controlGap` 8, `panelPadding` 12, `sectionGap` 16, `windowPadding` 20 |
| Text roles | `caption` 10, `label` 11, `body` 12, `section` 16, `panel` 20, `page` 24 px |
| Line height | Body 1.35, headings 1.2, `bar` 1 to preserve existing bar metrics |
| Corners | `radiusSmall` 4, `radiusControl` 8, `radiusCard` 12; capsules use half their height |
| Heights | `compactHeight` 28, `controlHeight` 32, `selectorHeight` 40; content may grow |
| Motion | `durationFast` 120, `durationNormal` 160, `durationSlow` 300 ms |
| Colors | `background`, `surface`, `surfaceRaised`, `text`, `textSecondary`, `textMuted`, `border`, `accent`, `danger`, `warning`, `success`, `info` |

`UI.Text.role` selects size, weight, and line height. Use `UI.Icon` for glyphs;
its font stays on JetBrainsMono Nerd Font. Keep the configurable bar font for
bar text. Filled controls choose readable foreground colors from the palette,
falling back to black or white when neither palette foreground reaches 4.5:1.

| Primitive | Interface and use |
| --- | --- |
| `Button`, `IconButton` | Standard Qt button signals/properties; `variant`: `neutral`, `primary`, `ghost`, `destructive`; `size`: `default`, `compact`; `busy`, `capsule`, `accentColor`; `checked`/`highlighted` for selection |
| `TextField` | Standard text, placeholder, password, read-only, validator, and editing APIs; `invalid` adds error presentation without hiding focus |
| `ComboBox` | Standard model, `textRole`, `valueRole`, current index/value, and `activated`; `busy` disables interaction and closes the popup |
| `MenuItem`, `Popup` | Selectable rows and a shared popup surface; Escape/outside-parent dismissal, bounded content supplied by the caller |
| `CheckBox`, `RadioButton`, `Switch` | Standard Qt checked/toggled behavior; radio siblings are exclusive; `Switch.busy` suppresses activation |
| `SegmentedControl` | String-array `model`, caller-owned `currentIndex`, and `selected(index)` request signal; arrow-key navigation |
| `ToggleTile` | Button contract plus `iconGlyph`; caller-owned `checked`, or opt into local toggling with `checkable: true` |
| `Slider` | Standard range/value/moved APIs; `accentColor`, `showHandle`; wheel input is opt-in |
| `Card`, `Pane`, `Capsule`, `Divider`, `MenuSurface` | Shared surfaces; `Pane` includes standard padding, `Card` leaves child layout to the caller |
| `RowLayout`, `ColumnLayout`, `GridLayout` | Qt layout APIs with the shared default control gap |
| `ScrollView`, `ScrollBar` | Qt scrolling behavior with shared scrollbar geometry and state colors |
| `FieldLabel`, `HelperText` | Shared field label/helper roles; helper text supports `invalid` |

Controls distinguish normal, hover, pressed, selected, keyboard-focused,
disabled, and applicable busy states. Button hover animates the fill and a
one-pixel outline; keyboard focus uses a distinct two-pixel outline.
Focus is independent of selection.
Busy buttons retain their dimensions and show an activity mark; clearing busy
restores the caller's current `enabled` binding. Provide accessible names for
icon buttons, fields, selectors, and sliders.

`NotificationButton` is a compatibility adapter (`accent` maps to the primary
variant). `ControlSwitch` retains its service-controlled `value` and
`changeRequested(value)` contract: a failed request does not change confirmed
state. Audio throttling and media seek-on-release remain in their feature
adapters, which extend `UI.Slider`.

New feature components should use these primitives and semantic tokens rather
than defining another button background, field style, font size, or corner
radius. Specialized content geometry remains local: charts, wallpaper/media
previews, miniature lock-screen text, window positioning, and workspace animation
math. Native tray menus and external application theme generators retain their
platform behavior. Palette swatches display the actual palette colors.

Run the standalone gallery from the repository root:

```sh
quickshell --path tools/design-gallery
```

It displays all primitives and variants, supports all six palettes in light and
dark modes, and never saves preview choices. Hover, press, Tab, and resize to
inspect interaction and narrow layouts. `Design.previewPalette` is reserved for
this isolated preview and tests; production screens use the active `Theme`.

```sh
python3 scripts/test-design-system.py
bash scripts/check.sh
```

The isolated QtTest suite covers interaction, disabled/busy behavior, controlled
selection, text input, sliders, popup dismissal, and live palette changes. It
also renders every palette and a narrow gallery under `/tmp/qs-design-gallery-*`.
Existing feature test harnesses install the same production UI library alongside
their service mocks through `scripts/design_test_support.py`.

## Settings window

Click the bar's settings icon for a compact panel with hostname, OS, uptime,
Night Shift, light/dark mode, and DND. The gear inside this panel
opens the full Settings window. Theme and DND use the same shared state as their
other controls. Night Shift uses `hyprsunset` and starts it on demand.
While enabled, its color-temperature slider adjusts warmth live from 1500 K to
6500 K in 50 K steps; 4000 K is the default. Lower values are warmer and higher
values are cooler. The chosen setting is saved in
`quick-controls.json` and reused when enabled again. Scrolling does not change
the slider. Turning Night Shift off restores neutral colors. It reuses an existing daemon,
preserving its gamma setting. New daemons use the default hyprsunset config;
any configured schedule can still change the filter's state.
The panel reads the actual filter state when opened and every five seconds while
visible. Its state survives shell reloads while the daemon is running; it does
not add a login service. Install it with `sudo pacman -S hyprsunset`.
See the [hyprsunset documentation](https://wiki.hypr.land/Hypr-Ecosystem/hyprsunset/).

**Bar layout**
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
Run `python3 scripts/test-quick-controls.py` for the quick panel and Night Shift
helper checks without changing live theme, notifications, or screen colors.

Expand **System info** in the quick settings panel for OS/kernel, CPU/GPU models,
RAM, free/total space on the filesystem containing your home directory, laptop
battery status, active connections and local IPs, and pending repository updates.
RAM includes installed capacity from udev's cached firmware data or readable
firmware tables; otherwise it
is explicitly labelled as OS-usable memory. GPU names use `lspci` from `pciutils`.
Update checks use `checkupdates` from `pacman-contrib` with its separate database;
they never install packages or refresh the system pacman database. Checks run
when first expanded, then at most every 30 minutes while viewed, or on refresh.
The count covers configured Arch repositories, not AUR packages. Errors and the
last successful check time remain visible.

## Duplicate laptop screen

Click the monitor button to duplicate the active laptop screen on connected
external monitors. Click again to restore your saved Hyprland configuration,
including resolution, refresh rate, scale, placement, and color settings.
The button is enabled by default and can be moved or hidden as **Duplicate laptop
screen** in Settings → Bar layout. The icon highlights mirroring and turns red on errors.

Mirroring uses each external monitor's preferred resolution and automatic scale;
the laptop resolution stays unchanged. Hyprland scales the mirrored image to the
external output, so different aspect ratios may stretch it. See
[Hyprland monitor modes](https://wiki.hypr.land/configuring/core/monitors/modes/).
This uses the Lua monitor API (Hyprland 0.55+). Restoring runs `hyprctl reload`,
which reloads the whole Hyprland configuration and resets other temporary config
overrides too. No config files are edited. A manual Hyprland reload also restores
the configured layout. Monitor state is shared between bars and read back after
changes; reconnects and external configuration changes are picked up automatically.

Run `python3 -m unittest discover -s tests/display_mode -v` for isolated display
discovery, mirroring, restoration, and failure checks without changing displays.

## Desktop / TV switch

Click the monitor button, or press **Super+Shift+F2**, to switch between the
configured DP-1 + DP-2 desktop and HDMI-A-1 TV. The switcher first enables the
destination, moves workspaces and apps, and then disables the source displays.
Switching back restores each workspace to its previous monitor; workspaces
created on TV go to DP-1, except workspace 9 which goes to DP-2 when available.
The bar button is enabled by default and can be moved or hidden as
**Desktop / TV switch** in Settings → Bar layout, independently of
**Duplicate laptop screen**.

After switching to TV, press **Enter** within 15 seconds or click **Keep TV**
on the bar. Without confirmation, Desktop is restored automatically. Pressing
**Super+Shift+F2** again during the countdown cancels the TV switch immediately.

If the TV is disconnected, the desktop remains active and Hyprland shows an
error. If the TV is unplugged in TV mode, the desktop is restored. If DP-2 is
disconnected, Desktop still works on DP-1. A Hyprland config
reload starts in Desktop mode and ends any in-progress TV session. The button
reads the active outputs rather than trusting a saved mode.

Run `python3 -m unittest discover -s tests/desktop_tv -v` for isolated
backend and widget checks without changing the live displays.

## Battery

Enable **Battery** in Settings → Bar layout. It starts disabled and hides itself
on desktops without a system battery. Peripheral batteries (headsets, mice, etc.)
are excluded. The bar shows charge percentage and charging state, adapting to
horizontal and vertical layouts. Multiple energy-reporting batteries use a
capacity-weighted charge percentage; other combinations use the average.

Click it to see each battery's charge, status, estimated health (full capacity /
design capacity), cycle count, and full/design capacity when the driver exposes
them. Missing values are shown as unavailable.

The popup also shows estimated time until empty while discharging, or until full
(or the applied charge limit) while charging. It uses driver estimates when
available, otherwise remaining energy/power or charge/current. Estimates update
every 10 seconds while the popup is open and vary with workload and charging rate.
Idle/full batteries hide the estimate; missing rate data is shown as unavailable.

Use **Power profile** in the popup to select the firmware's supported modes,
such as Power saver, Balanced, and Performance. The active mode is highlighted
after driver readback; firmware hotkey changes are picked up on refresh. This
uses the kernel's [platform profile interface](https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-platform_profile)
and may prompt for polkit authorization. Unsupported devices show an explanation.
Profiles control the laptop's firmware performance/power/cooling policy; they do
not configure a separate CPU governor or install a power management daemon.

If the driver exposes `charge_control_end_threshold`, choose a **50–100%** charge
limit and click the check button to apply it. This sets the hardware threshold;
the driver may round to a supported value, which the panel reads back. Set 100%
to allow a full charge. When necessary, the start threshold is lowered below the
new limit and restored if applying the end threshold fails. Existing charge above
the limit is not forcibly discharged. Hardware support is required; the shell
does not simulate a limit on unsupported machines.

Applying a limit may prompt through `pkexec`; run a polkit authentication agent
in your session. Only the requested sysfs write is elevated, without installing
a custom privileged service or changing permissions. Limits may reset after a
reboot or be changed by tools such as TLP; the popup always shows the driver value
and lets you reapply it. The shell does not silently reapply limits at login.
See the [kernel power-supply interface](https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-class-power).

Run `python3 -m unittest discover -s tests/battery -v` and
`python3 -m unittest discover -s tests/system_info -v` for isolated hardware and
update-check fixtures. Quick-controls tests also exercise the battery popup.

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
terminal fallbacks. Errors appear in the history popup.

CPU/GPU load and temperature, RAM/VRAM usage, and exposed CPU/GPU/battery power
sensors are discovered automatically. Settings offer a CPU temperature source
override. Unavailable sensors show a reason; no driver or permission changes are
made. Power readings describe individual sources, not whole-PC consumption.
Meters use sensor limits where available; otherwise temperature uses 100°C and
power graphs use their labelled recent peak. Vertical memory values use `G` for
GiB. History resets when Quickshell restarts.

If the CPU power card says its energy counter needs read permission, opt in with
`sudo python3 scripts/setup-cpu-power.py --group "$(id -gn)"` from this config
directory. This installs `80-quickshell-cpu-power.rules` in `/etc/udev/rules.d`
and grants the chosen group read access only to package energy counters, now
and after reboot. Power controls and core subdomain counters remain unchanged.
The graph starts sampling automatically, without restarting Quickshell.
Preview the rule first by adding `--print-rule` (no sudo needed).

Run `python3 scripts/test-monitoring.py` for isolated sensor, terminal, controls,
history, and settings-persistence checks.

## Customize

In **Settings → Appearance → Colors**, **Theme from wallpaper** generates a
shared palette from the selected monitor. Choose **Dominant**, **Vibrant**, **Average**, **Muted**, **Dark**, **Light**, or
**Balanced** extraction and a **Neutral**, **Tonal**, or **Vivid** variant. Changing
any of these controls generates and applies the Wallpaper theme automatically;
light/dark swatches show the result. ImageMagick (`magick`) is required for
generation; processing stays local.

**Muted** favors low saturation; **Dark** and **Light** favor darker or lighter source colors.
**Balanced** averages distinct color buckets equally, reducing the influence of large flat areas.
**Vivid colors for Neovim** uses a separately generated vivid variant when the Wallpaper
theme and Neovim application sync are enabled. It leaves the shared palette unchanged,
updates automatically, and is saved across restarts.

**Follow wallpaper changes** is off by default. When enabled, it updates colors
while the Wallpaper theme is selected, including separate light/dark wallpapers.
Selecting a built-in preset pauses automatic application. Missing images or
disconnected source monitors keep the last applied palette and show an inline
error. The saved palette remains available after restarting or removing the image.
Already-enabled application theme syncs follow successfully applied palettes.
Run `python3 scripts/test-wallpaper-colors.py` for extraction, contrast, UI,
automatic-update, and persistence checks.

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
- Appearance → Text & icon lets you search installed fonts for the bar, preview
  the selection, and reset to JetBrainsMono Nerd Font. The chosen font is saved
  across restarts. Settings and icon-only buttons keep their existing font.
- Bar text size adjusts bar text from 12–28 px, with bar thickness adapting to
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
- Edit palette definitions in `config/Palettes.js` and the shell’s default font in `config/Theme.qml`.
  Enable individual targets under Application themes to sync app colors with the
  shell. See [Application themes](APP_THEMING.md) for supported apps, toolkit
  setup, and restoration. All app switches start off.
- In **Appearance → Widget styling**, choose **Off**, **Instant**, or **Animated**
  independently for bar edge lines and hover backgrounds. Edge lines move to the
  left/right on vertical bars; Off also hides active-state lines. Defaults retain
  animated lines (300 ms) and no hover background. Animation duration supports
  100–600 ms; background strength supports 0–30% (12% by default).
  The preview responds to hover, click, and keyboard focus. Settings apply across
  all monitors and save automatically. Reset affects only widget styling.
  Keyboard focus remains visible with effects off. There is no click flash;
  popup controls, workspace movement, and external theme syncing are unaffected.
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
- Enable **Different wallpapers for light and dark** in Wallpapers to reveal
  Light/Dark options. Select a mode, then use the monitor cards or gallery to set
  its wallpaper; editing a mode does not switch the shell theme. Wallpapers follow
  the active light/dark theme automatically. Unset modes use the shared wallpaper;
  Clear explicitly removes only the selected mode's wallpaper. Turning the toggle
  off restores the shared wallpaper for both themes, keeping separate selections
  saved for later. The toggle starts off for existing configurations.
- Mode changes randomly use a fade, gentle zoom, or one of four directional wipes
  when the wallpaper changes. The next image loads before the transition starts;
  missing files keep the previous image. Shared wallpapers stay still when the
  same image is used in both modes. Effects are chosen together for all monitors.
- The **Light / dark mode** bar widget switches modes with one click. Its sun/moon
  icon reflects the current mode; it can be moved or hidden in Bar layout.
  It uses the same theme setting as Appearance, including application theme sync.
- Dropdowns share the same outer padding, controlled by `popupPadding` in
  `config/Settings.qml` (12 px by default).
- In Settings → Bar layout, click the gear beside **Workspaces** to hide app icons,
  choose app images or Nerd Font symbols, customize the separator (including none),
  and add a rounded capsule around the icons. Changes apply to all bars and survive
  restarts. Reset restores the original look. Unknown apps use a generic Nerd Font
  symbol, and each icon still focuses its own window.
- By default, workspace icons come from application desktop entries and the system icon theme,
  displayed in their original colors at full opacity. Every window gets its own
  icon, including multiple windows of the same app on a workspace. Lookup matches desktop IDs, StartupWMClass, and the initial
  window class automatically; apps without a usable icon get a generic fallback.
  No per-app icon mapping is required.
- Click an app icon to switch to its workspace, focus its window, and move the
  pointer to its center. Each icon targets that exact window. Clicking the workspace number or empty
  space still switches workspaces normally.
- Hover a workspace for a miniature preview; hovering an app icon outlines that
  exact window. The preview opens after 280 ms, stays outside the bar, and is
  click-through. It composes window captures over the workspace monitor's wallpaper
  using Hyprland's window geometry. Captures refresh at most four times per second
  while shown and are released when closed. Unavailable captures show the window's
  icon and title. Floating/fullscreen stacking is approximated from window metadata.
  This uses Quickshell's native ScreencopyView and Hyprland's toplevel export protocol,
  with no screenshot utility or saved screenshots required.
- Only workspaces with open app windows appear, sorted by their actual workspace
  numbers. Empty workspaces are hidden, including the active one when empty.
- App-list changes settle for 100 ms before updating. Moved apps pop out of the
  old workspace and into the new one; unchanged icons keep their hover state.
  Workspace widths resize smoothly as icons change. New workspaces slide in;
  empty ones slide out after their last icon finishes popping out, smoothly
  shifting neighboring workspaces and the tray.
- Window icons show a small attention badge when their window is marked
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

Manual Lock and the parent dotfiles' lid-close binding both request
`loginctl lock-session`. Hypridle listens for that request and launches Hyprlock
through `scripts/launch-hyprlock.py`, using `~/.config/hypr/hyprlock.conf`.
The launcher checks Hyprland's lock state rather than `pidof`: Hyprlock can leave
a process behind after unlocking, and that process must not block the next lock.
A per-session guard prevents overlapping launches until the compositor locks.
Startup errors go to `quickshell-hyprlock-*.log` in `$XDG_RUNTIME_DIR`.
Unlock with your normal login password.
Sleep requests the same lock, then runs `systemctl suspend`; Hypridle's
`inhibit_sleep = 3` delays sleep until Hyprland reports the session locked.
The helper rejects Lock/Sleep if required tools or the Hypridle listener are
missing. Reboot and shutdown use `systemctl reboot` and `systemctl poweroff`,
respecting the system's normal permissions and inhibitors.

Enable the Hypridle user service to start it with the graphical session.
The existing lid/suspend policy stays in effect. See [Dependencies and session setup](DEPENDENCIES.md#service-and-session-setup)
for packages, configuration, and activation. The shell no longer runs a separate
Quickshell locker; all entry points share
Hyprlock's appearance and authentication.

In **Settings → Lock screen**, enable **Sync shell theme** to apply the current
palette and light/dark mode to Hyprlock. Choose **Theme color**, **Plain color**
(hex `#RRGGBB`), or **Picture** (local PNG, JPEG, or WebP). Pictures are checked
before selection and must remain on disk. Preferences persist across restarts;
changes apply on the next lock, including locks requested by Hypridle.

The generated layout always shows the current keyboard layout and Caps Lock
on/off status, even before typing. Caps Lock also highlights the password border.
The layout uses Hyprlock's native `$LAYOUT`; the Caps Lock label reads Hyprland's
main keyboard every 500 ms and shows “unknown” if unavailable. An opaque themed
panel keeps these indicators readable over pictures and custom colors.

The clock/date, unlock field, and two compact cards share the theme palette.
The media card reads local MPRIS players using `busctl` every three seconds,
preferring playing over paused media, and shows the title and artist. No player
controls or remote artwork downloads are used on the lock screen.
The Codex card checks local session events every five seconds from
`$CODEX_HOME` (default `~/.codex`). It shows recent activity, completion, or
interruption, without exposing task titles, prompts, or responses. This is a
best-effort adapter for local Codex session files, not a live app-server
connection: activity older than two minutes becomes “Awaiting update”, and
events older than a day are omitted. Missing or incompatible data is reported
on the card. Use **Settings → Lock screen → Reapply** to regenerate the layout;
the updated layout appears on the next lock.

Sync uses a managed `hypr/hyprlock.conf` with standard PAM authentication. The
previous configuration is backed up and restored when sync is disabled; manual
edits produce a conflict instead of being overwritten. Use the normal config
path in Hypridle (`hyprlock`, without a custom `--config`) to share this setup.
See [application themes](APP_THEMING.md) for recovery details. Background paths
containing `$`, `#`, braces, newlines, or outer whitespace must be renamed because
Hyprlang interprets those characters. Keep the Quickshell installation at its
current path while sync is enabled so the Caps Lock helper stays available.

For a lock keybinding, run `python3 ~/.config/quickshell/scripts/power-action.py lock`.
For lock-then-sleep, use `sleep` instead of `lock`. Run
`python3 scripts/test-power.py` for isolated routing and failure checks. These
use fake session commands and do not lock, suspend, reboot, power off, or check
your real password. Verify physical lid closing and password unlocking on the
target machine.

## Monitor brightness

Click the sun icon beside the volume widget for a brightness slider per display.
Displays are discovered on opening and with Refresh, including plugged/unplugged
monitors. While open, values are checked every 15 seconds and after writes without
rediscovering devices or replacing their controls. A failed value check retains
the last level and shows an error beside the affected monitor. There are no configured
monitor names or I2C bus numbers. Slider writes are queued, keeping the latest
requested value per monitor while slower hardware commands finish.

External monitors use `ddcutil` and DDC/CI; enable DDC/CI in the monitor's own menu
and ensure your distribution grants your user access to `/dev/i2c-*` (the
`i2c-dev` module must be loaded). Built-in screens are discovered through Linux
backlight devices and controlled with `brightnessctl`. Install these tools on
each PC as needed. Unsupported monitors remain visible with an explanation.
This adjusts hardware brightness; there is no software dimming fallback.

Run `python3 scripts/test-brightness.py` to test discovery, queued writes,
readback, and recovery with simulated displays, without changing brightness.

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
automatically; unavailable selectors are disabled. Pending switches keep labels,
percentages, and layout steady, using a small indicator in the selector. Failed
checks preserve the last confirmed state until a successful snapshot arrives.
Run `python3 scripts/test-audio.py` for isolated switching and recovery checks.

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

`python3 scripts/test-wallpaper-transitions.py` checks all wallpaper effects,
rapid mode changes, missing images, and the sun/moon button using isolated state.

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
