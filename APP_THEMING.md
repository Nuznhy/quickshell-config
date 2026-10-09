# Application themes

Open **Settings → Appearance → Application themes** and enable the applications
that should follow the bar. Every switch starts off. Changing the palette or
Dark/Light updates enabled targets. Bar geometry and opacity changes update only
the enabled Hyprland appearance target; widget order and wallpaper changes do
not regenerate app themes.
Lock-screen background changes update only the enabled Hyprlock target.

Targets appear in a compact grid that adapts to the settings window width. Each
card keeps its toggle and a short status; click a status with a chevron to read
setup instructions or error details below the grid. Failed targets also show a
retry button on their card.

Switching a target off restores the previous theme selection. Existing Noctalia
selections and imports are recorded before replacement. Other application
settings, custom CSS, extensions, and dotfile symlinks are preserved.

## Targets

| Switch | Integration | Activation / refresh |
| --- | --- | --- |
| GTK 3 / 4 | Generated `gtk-3.0/quickshell-config.css` and `gtk-4.0/quickshell-config.css`, managed imports in `gtk.css`, GTK settings and desktop color preference. GTK 3 uses adw-gtk3. | Reopen applications; a new login may be needed after initial toolkit setup. |
| Qt / KDE | Uses the detected KDE or qt5ct/qt6ct platform integration. KDE colors go into `~/.local/share/color-schemes/quickshell-config.colors` and managed `kdeglobals` keys. qtct uses generated palettes and its custom-palette selection. | Sends KDE's palette-change notification; reopen apps or log in again after initial toolkit setup. |
| Rofi | Appends a managed import of `rofi/quickshell-config.rasi` to `rofi/config.rasi`. Syncs backgrounds, text, borders, accents, and selection colors while preserving the existing font and layout. | Colors load the next time Rofi opens. Disabling removes the override and restores the previous colors. |
| Ghostty | Selects the generated `ghostty/themes/quickshell-config` theme in existing `config` / `config.ghostty` files. | Requests reload with SIGUSR2 for this user's Ghostty processes. |
| Foot | Adds/replaces a managed theme include. The generated theme defines both `colors-dark` and `colors-light` using the selected bar palette. | Open a new terminal; tested with Foot 1.28. |
| Yazi | Generates a `quickshell-config.yazi` flavor and syntax palette, selecting it for both light/dark modes. | Reopen Yazi. |
| btop | Generates `btop/themes/quickshell-config.theme` and selects it. | Reopen btop. |
| Hyprland colors | Managed `hypr/quickshell-colors.lua` / `.conf` override for border colors. | Follows palette changes independently of appearance. Reloads Hyprland on apply/restore. |
| Hyprland appearance | Managed `hypr/quickshell-appearance.lua` / `.conf` override for rounding, opacity, gaps, border width and blur. | Follows bar geometry and opacity independently of colors. Reloads Hyprland on apply/restore. |
| Hyprtoolkit | Updates palette keys in `hypr/hyprtoolkit.conf`. | Uses the toolkit's configuration reload behavior. |
| Hyprlock | Manages `hypr/hyprlock.conf` with the shell palette, persistent layout/Caps Lock indicators, and the background selected in Settings → Lock screen. Backs up the entire previous config and restores it when disabled. | Loads on the next lock. Uses standard PAM authentication; does not restart a running locker. |
| Spotify | Generates a dedicated Spicetify theme and selects it, preserving extensions/custom apps. Runs `spicetify -q apply --no-restart`. | Reopen Spotify if needed. Existing Spotify/Spicetify setup and write access are required. |
| Discord | Generates a local CSS theme for detected Vencord/Vesktop installations and adds it to their enabled themes. | Reopen the client after first activation. No client mod is installed by this feature. |
| Zen Browser | Generates `chrome/quickshell-config.css` and manages its import in each registered profile's `chrome/userChrome.css`. Replaces a recognized Noctalia Zen import while enabled and restores it when disabled. | Restart Zen after palette or Dark/Light changes and after disabling sync. |
| tmux | Generates `tmux/quickshell-config.conf` with palette values consumed by the dotfiles' `tmux/theme.conf`. Preserves the two-line status layout, rounded segments, session/window labels and clock. | Updates integrated running servers live. Disabling restores the original Rosé Pine fallback, also live. |
| Powerlevel10k / Zsh | Generates `zsh/quickshell-p10k.zsh` and appends a managed source line to `$ZDOTDIR/.p10k.zsh`, or `~/.p10k.zsh` when ZDOTDIR is unset. Syncs prompt, directory, VCS, status, context, and common segment colors. Preserves layout, icons, custom functions, and symlinks. | Open a new shell or source your `.p10k.zsh` after applying, changing palettes, or disabling sync. No commands are injected into running terminals. |

Powerlevel10k sync starts disabled and requires `zsh` plus an existing `.p10k.zsh`
that your shell already loads. Custom configuration filenames are not detected.
The override preserves empty generic colors and array settings, and does not
rewrite inline color escapes inside custom formatter functions. Disabling removes
the managed source line and restores any previous generated file; unrelated edits
remain intact. Manual edits to managed content are reported as conflicts.

These integrations use native user configuration locations. Flatpak sandbox
permissions and custom client wrappers are not configured automatically. An app
that ignores toolkit colors or has explicit color overrides can still differ
from the shell. Noctalia and Matugen are not required.

## Hyprland syncing

Use the two independent switches under Application themes:

- **Hyprland colors** follows the bar palette for active/inactive borders. It does not change spacing, opacity, rounding, blur, or shadows’
  enabled state.
- **Hyprland appearance** follows bar rounding and opacity. Outer gaps follow
  bar margins: edge margin maps to top/bottom and side margin maps to left/right,
  swapped for a vertical bar. Inner gaps use the shared 8 px spacing token;
  borders use the shared 1 px border token. Soft blur (size 5, two passes) is enabled. This toggle does not set colors.

Neither toggle overrides any shadow settings; your Hyprland config controls them.

Both start off for new setups. An existing enabled combined Hyprland override
migrates to both switches enabled, preserving its behavior and restore backups.
Each switch has its own managed file and import, so disabling one restores that
part of your original config while leaving the other active.

Changes are debounced for 250 ms and update only Hyprland. There is no need to
toggle sync again after editing bar appearance. Settings are read when each
update starts, so rapid adjustments finish with the latest values.

The managed imports load after your existing config. Input, keybindings, monitor
layout, workspace rules, and animations are not changed. Disabling removes the
import and generated file and reloads your original styling. Existing files are
backed up; manual edits to managed files produce an error instead of being
overwritten. Symlinked configs remain symlinked.

Requires `hyprctl` and a standard config under `$XDG_CONFIG_HOME/hypr` (normally
`~/.config/hypr`). Custom Hyprland `--config` paths are not supported. When no
Hyprland session is running, the generated settings load at the next start.
Reloading follows [Hyprland’s documented configuration reload](https://wiki.hypr.land/configuring/core/advanced-configuration/using-hyprctl/).

## Toolkit setup

Enabling GTK manages its desktop preferences and removes a forcing `GTK_THEME`
assignment from recognized user shell/session files. On this machine that
assignment is in the symlinked `~/.zshrc`. Removing it lets GTK theme preferences
work instead of always forcing Adwaita dark.

Enabling Qt keeps/selects the detected platform integration and selects Fusion
as the palette-compatible style. On this Hyprland setup, only the relevant
`hl.env` lines in `hypr/config/env.lua` are managed. If that file is absent,
a dedicated `environment.d/90-quickshell-theme.conf` is used instead. The
previous values are recorded for restoration.

Already-running processes retain inherited environment variables. Reopen apps,
and log out/in after initial toolkit setup if necessary. The shell never
restarts an application or your desktop automatically. Unrecognized environment
scripts and app-specific launch overrides may still need manual adjustment.

## Dependencies

The generator uses Python's standard library and the existing Quickshell runtime.
Install only the optional tools for integrations you want:

- GTK: `adw-gtk-theme`, `gsettings-desktop-schemas`, `glib2` (`gsettings`), and
  `dconf`. GTK applications normally supply GTK itself.
- Qt/KDE: the session's KDE platform integration (`plasma-integration` on Arch,
  with its dependencies), or `qt5ct` / `qt6ct` for a qtct session. KDE reload uses
  `dbus-send` from `dbus`.
- Ghostty: `ghostty` and `procps-ng` (`pkill`).
- Foot, Yazi, btop: their respective applications (`foot`, `yazi`, `btop`).
- Rofi: `rofi`. Uses its native [Rasi theme overrides](https://davatorium.github.io/rofi/1.7.9/rofi-theme.5/).
  Launchers using a separate `-config` or an explicit `-theme` can bypass this
  integration; use the standard `rofi/config.rasi` to follow the shell palette.
- Hyprtoolkit: an existing `~/.config/hypr/hyprtoolkit.conf`.
- Hyprlock: `hyprlock` (validated against 0.9.6), `hyprctl`, and Python 3. See the
  [Hyprlock widget documentation](https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/).
  The media card also uses `busctl` (systemd); the Codex card reads local SQLite
  session metadata and bounded event tails. Neither integration is required to
  unlock, and unavailable status is displayed without changing authentication.
  The persistent Caps Lock label reads only keyboard modifier metadata; no
  keypresses or passwords are read. The password-border warning is native to
  Hyprlock and remains available even if `hyprctl` fails.
- Spotify: an initialized `spicetify-cli` setup for the installed Spotify client.
  Failed patching is shown as an error; this feature does not change `/opt`
  permissions or install Spotify.
- Discord: an existing Vencord or Vesktop installation with settings on disk.
- tmux: `tmux` and this dotfiles' theme integration. Its reusable color bindings
  are in [`integrations/tmux/theme.conf`](integrations/tmux/theme.conf); install
  them as `$XDG_CONFIG_HOME/tmux/theme.conf` (`~/.config/tmux/theme.conf` by default)
  and source that file from `tmux.conf` after other theme settings. The installed
  dotfiles already do this. Only the color file is reloaded on palette changes;
  plugins, keybindings, pane layouts, and running commands are not reloaded.
  Named sockets under `/tmp/tmux-UID` and `$TMUX_TMPDIR/tmux-UID` are discovered,
  plus a custom socket inherited through `$TMUX`. Only servers with this theme
  integration are updated. Other custom `-S` servers load colors when they next
  source the config. Explicit session/window color overrides take precedence
  over these global defaults. Do not edit the generated `quickshell-config.conf`;
  customize layout and fallback colors in `theme.conf` instead.
- Zen Browser: start Zen once to create a profile. Custom stylesheets must be
  enabled with `toolkit.legacyUserProfileCustomizations.stylesheets = true` in
  `about:config`, as described in [Zen's CSS guide](https://docs.zen-browser.app/guides/live-editing).
  Profiles are discovered from `profiles.ini` in `$XDG_CONFIG_HOME/zen`, `~/.zen`,
  and the Flatpak locations `~/.var/app/app.zen_browser.zen/{config/zen,.zen,zen}`.
  Relative and absolute profile paths are supported; all registered profiles that
  still exist receive the theme. The row identifies profiles that need stylesheet
  support enabled. Browser preferences are read but never rewritten. Sync changes
  browser UI colors, not websites, extensions, or workspace data; existing custom
  styles can still override these colors. No extension or developer-tools access
  is required, and the browser is never restarted automatically.

Refresh application availability with the circular-arrow button after installing
an optional dependency. Targets with missing requirements cannot be enabled;
an already enabled target can always be switched off to attempt restoration.

GTK and Zen sync reconcile duplicate or mixed Quickshell/previous-theme imports
when every import matches the saved recovery record. This repairs a previous
theme manager reinserting its import without discarding custom CSS or changing
the original restore snapshot. Unrecognized edits still produce a conflict.

## Recovery and errors

Application-theme preferences, operation journals, and private backups are kept
in `app-themes/` under Quickshell's per-shell state directory, beside `theme.json`.
The helper records each managed value before writing and preserves symlink
locations while updating their resolved targets. Generated files are written
atomically. Keep this state directory to retain restoration information.

A failure in one target does not block other integrations. The row shows the
error and a retry button. Failed restoration stays pending for retry, including
after restarting the shell. If a theme selection or generated file has been
edited manually, the helper preserves it and reports a conflict instead of
restoring over it. Backups remain available in `app-themes/backups/`.

A file lock serializes this helper's operations, including Spicetify. Avoid
running another theme generator against the same application simultaneously.

## Development and verification

`scripts/app-themes.py --state DIRECTORY` reads one JSON request from stdin and
returns a JSON object containing `targets`, or a top-level `error`. Actions are
`discover`, `sync`, `set`, and `retry`. Mutating requests supply the current
`palette` (all semantic roles from `config/Palettes.js`) and `mode` (`dark` or
`light`); `set` also supplies a known target ID and boolean `enabled`. `retry`
supplies a target ID. `discover` reads availability without editing app configs.
Requests can also include `lockScreen: {background: "theme" | "color" | "image",
color: "#RRGGBB", image: "file:///..."}`. It defaults to the theme background.

`services/AppTheming.qml` debounces palette changes and runs one worker at a time.
It queues target requests and follows in-flight changes with the latest palette.
Formatting lives in `scripts/app_theme_formats.py`; templates are bundled in code
and do not execute downloaded hooks.

Run from this repository:

```sh
python3 scripts/test-app-themes.py
python3 scripts/test-tmux-themes.py
bash scripts/check.sh
```

The tests use temporary configuration/state directories and fake reload commands
for application changes. They cover palette formats, restoration, manual edits,
symlinks, unavailable dependencies, failed hooks, UI switches, and the real QML
worker queue. Native Quickshell tests need permission to create local IPC sockets.
The tmux suite creates separate temporary servers to verify every palette,
restoration, new-server startup, and isolation from unrelated configurations.
