# Palette sources

[Home](../README.md) · [UI kits](ui-kits.md)

Palette values are bundled locally; the picker never needs network access.
The shell adapts the source palettes to its existing semantic color roles.

- **Gruvbox**: Dawid Kurek and morhetz, medium-contrast dark/light variants from
  [Tinted Theming](https://github.com/tinted-theming/schemes/tree/spec-0.11/base16):
  [dark](https://github.com/tinted-theming/schemes/blob/spec-0.11/base16/gruvbox-dark-medium.yaml),
  [light](https://github.com/tinted-theming/schemes/blob/spec-0.11/base16/gruvbox-light-medium.yaml).
- **Solarized**: Ethan Schoonover, catalog adaptation by aramisgithub:
  [dark](https://github.com/tinted-theming/schemes/blob/spec-0.11/base16/solarized-dark.yaml),
  [light](https://github.com/tinted-theming/schemes/blob/spec-0.11/base16/solarized-light.yaml).
- **Everforest**: sainnhe's published
  [palette](https://github.com/sainnhe/everforest/blob/master/palette.md), using
  medium-contrast backgrounds and the respective dark/light foregrounds.

For the Base16 presets, bg/surface/overlay use base00/01/02; muted/subtle/text
use base03/04/05. Love/gold/rose/pine/foam/iris use base08/0A/09/0D/0C/0E;
highlightLow/Med/High use base01/02/03. These are shell adaptations, not full
upstream editor themes. Rosé Pine and Catppuccin are also adapted to these roles; Neutral is bundled locally.

**Windows 7 Aero** is offered with the Windows 7 kit. Its light variant maps
Aero's gray control surfaces, softened off-white content areas, dark text, and blue selection
colors to shell roles, following Microsoft's
[Windows 7 color guidance](https://learn.microsoft.com/en-us/windows/win32/uxguide/vis-color).
Panel backgrounds and borders remain neutral; blue is reserved for interaction
accents. The charcoal dark variant is a companion interpretation, not an original
Windows 7 theme.
