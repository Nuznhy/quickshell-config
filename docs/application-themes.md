# Application themes

[Home](../README.md) · [Configuration](configuration.md) · [Installation](installation.md)

In Settings → Appearance → Application themes, enable the applications that
should follow the shell palette. Integrations start disabled. Disable a target
to restore its previous theme; use its status details for setup errors and retry.

## Supported integrations

| Targets | Requirements and behavior |
| --- | --- |
| GTK 3 / 4 | `adw-gtk-theme`, `gsettings-desktop-schemas`, `glib2`, `dconf`; generated CSS and theme preferences |
| Qt / KDE | Existing KDE platform integration or `qt5ct` / `qt6ct`; generated application palettes |
| Rofi, Ghostty, Foot, Yazi, btop | Existing application configuration; generated native themes |
| Hyprland colors and appearance | Separate switches for palette and bar-derived geometry; reloads Hyprland |
| Hyprtoolkit | Existing `hypr/hyprtoolkit.conf` |
| Hyprlock | Existing lock setup; follows the selected lock-screen background and palette |
| Spotify | Initialized Spicetify installation with write access |
| Discord | Existing Vencord or Vesktop installation |
| Zen Browser | Existing profile with `toolkit.legacyUserProfileCustomizations.stylesheets` enabled |
| tmux | `tmux` and the bundled [theme integration](../integrations/tmux/theme.conf) |
| Powerlevel10k | `zsh` and an existing `.p10k.zsh` loaded by the shell |
| Neovim | `nvim` and a standard `nvim/init.lua`; generated colorscheme and reload helper |
| Codex CLI | `codex` and an existing `$CODEX_HOME` (defaults to `~/.codex`); generated TextMate theme |

Applications may need reopening after a theme change. Toolkit integrations can
adjust session theme settings; log out and back in after initial setup if needed.
The shell does not install applications, client modifications, or plugins.

For tmux, install the bundled file as `~/.config/tmux/theme.conf` and source it
from `tmux.conf` after other theme settings. Integrated servers update live.
For Neovim, restart once after enabling; later updates load on focus or
`:QuickshellThemeReload`. Zen and Codex CLI need restarting to load changed colors.

## Restoration

Operation records and backups live in `app-themes/` under the shell's
[state directory](configuration.md#saved-state). Keep this directory if you
want to restore earlier settings.

Manual changes to managed values are preserved and reported as conflicts.
A failed target can be retried without blocking other applications. Avoid
running multiple theme generators against the same application's configuration.

Implementation: [AppTheming.qml](../services/appearance/AppTheming.qml),
[app-themes.py](../scripts/appearance/app-themes.py), and
[app_theme_formats.py](../scripts/appearance/app_theme_formats.py).
