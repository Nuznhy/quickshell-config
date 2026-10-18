# UI kits

[Home](../README.md) · [Development](development.md) · [Palette sources](palettes.md)

Kits control presentation while shared controls retain input handling and state.
Choose a kit in Appearance or preview it with `quickshell --path gallery.qml`.
Gallery choices do not save preferences.
Switching kits keeps the selected palette and refreshes enabled application
themes. Kits can offer native palettes in Appearance → Colors. A selected native
palette remains selected and available when switching to another kit.

## Windows 7 Aero

The **Windows 7 Aero** kit combines tinted glass, reflections, fine bevels, and
glossy controls with the selected theme or wallpaper palette. Both light and
dark modes are supported. Content panels and menu/popup interiors stay opaque;
glass is used for the bar and popup frames. Segoe UI is used when installed, with
a system sans-serif fallback. Icon fonts and the configured bar font are retained.

Choose **Windows 7 Aero** in Colors and **Light** mode for softened Aero colors:
light gray panels, soft silver content surfaces and buttons, and restrained blue
selection and focus accents. Buttons use a stepped silver gradient and a fine
inner rim; checkboxes have recessed faces and drawn ticks. Sliders use a narrow
groove and a pointed thumb, rotating with vertical controls. When the thumb is
hidden, the track retains its value fill.
Glass takes its color from the desktop and chosen
surface. Dark mode uses a neutral charcoal companion palette. The palette is
optional and is also available in the gallery while previewing this kit.

For compositor blur on Hyprland with Lua configuration, enable
`decoration.blur.enabled`, then load
[aero.lua](../integrations/hyprland/aero.lua) after your appearance settings:

```lua
dofile(os.getenv("HOME") .. "/.config/quickshell/integrations/hyprland/aero.lua")
```

The rule matches the stable `quickshell-bar` namespace and enables blur for the
bar and its attached popups. Restart Quickshell when first adopting the namespace.
Any existing rules targeting the bar's former default `quickshell` namespace
should target `quickshell-bar` instead. The snippet does not set global blur
strength or alter other applications. Low bar opacity can fall below the rule's
`ignore_alpha` threshold. Without compositor blur, tint and reflections still
render, but the desktop behind the glass remains sharp.

The gallery's patterned glass samples demonstrate transparency and clipping,
not compositor blur. Inspect the running shell to verify blur. Aero styling
uses QML and Canvas; it does not require Windows image assets or fonts to be
downloaded. Visual references are Microsoft's
[Windows 7 design guide](https://learn.microsoft.com/en-us/windows/win32/uxguide/windows)
and the exported controls from
[Aero UI (Windows 7)](https://www.figma.com/design/C478MHucFtLrSgPmlP3blk/Aero-UI--Windows-7---Community-?node-id=11-105).
The reference geometry, gradient stops, and reflection direction are adapted to
the selected palette; large light surfaces remain soft gray.

## Windows XP Luna

The **Windows XP Luna** kit adapts the supplied vector reference sheets
*Desktop*, *Window frames*, *Bars, Specials*, and *Menu, Lists*: glossy blue
bars, cream panels, recessed fields, beveled buttons, and flat menu selections.
Control surfaces use QML and Canvas. Shell icons use original PNG artwork
extracted from the supplied XP icon sheets and bundled in
[`kits/windowsxp/icons/`](../kits/windowsxp/icons/). The source SVG sheets are
not runtime dependencies. Existing shell interactions are retained.

Choose **Windows XP Luna** in Colors and **Light** mode for the native blue and
cream palette. **Dark** provides a companion interpretation. Other palettes,
including wallpaper colors, remain supported. Switching kits keeps the selected
palette. Bar foreground colors are resolved separately so blue bars remain
readable without changing popup text colors.

UI text uses installed Tahoma, then DejaVu Sans, then system sans-serif. Icons
switch with the kit; unmapped icons retain their font glyphs, including distinct
battery levels, wireless signal strengths, and unavailable-device states.
Custom settings icons, application/tray icons, and explicitly configured bar
fonts are preserved. Bar orientation,
opacity, radius, widget effects, and attached popup geometry remain configurable.
Checkboxes and radios use drawn green marks; sliders use a recessed groove and
pointed handle. Switches and narrow scrollbars adapt the same bevel treatment.

[`sources.json`](../kits/windowsxp/icons/sources.json) records each bundled
icon's source sheet, embedded image ID, and native size. To extract the original
PNG bytes again, run `python3 scripts/appearance/extract-xp-icons.py /path/to/sheets`.

## Add a kit

1. Copy `kits/minimal/` or `kits/rounded/` to `kits/<id>/` and edit `Kit.qml`.
   Use a lowercase module name containing letters, numbers, or underscores.
2. Register its ID, name, and description in [Registry.js](../kits/Registry.js).
3. Import and instantiate it in [UiKit.qml](../config/UiKit.qml), then add it to
   `definitions`.
4. Add a `qmldir` exporting the kit's QML types and JavaScript helpers.

Use [minimal](../kits/minimal/Kit.qml) or [rounded](../kits/rounded/Kit.qml) as a starting point:

```qml
import QtQuick
import qs.kits.default as Default

Default.Kit {
    tokens: ({radiusControl: 10, radiusCard: 16})
    controlSurface: Component { ControlSurface {} }
}
```

Tokens inherit from [Tokens.js](../kits/default/Tokens.js). Optional `palette`
and `palettes.light` / `palettes.dark` objects override selected color roles.
Renderers should use `Design` colors. Omitted values inherit the selected theme;
QML eight-digit colors use `#AARRGGBB`.
Application themes use the saved kit's resolved colors; transparent roles are
composited onto the palette background for formats that require opaque RGB.
Gallery previews do not affect application themes.
An optional `fontFamily` overrides UI text typography; an empty string inherits
the theme font. Keep icon fonts and explicit caller font choices intact.
An optional `controlFill(state)` returns a control color from `fill`, `variant`,
`selected`, `hovered`, `down`, `enabled`, `accent`, and `controlKind`. Shared controls use that
color to calculate readable text; keep interaction logic in the controls.

`controlKind` defaults to `button`; menu rows use `menuItem` and select triggers
use `select`. Keep the host fill and renderer in agreement so text contrast
matches the painted surface. An optional `barPalette` maps `Design` role names
(such as `background`, `text`, `textSecondary`, `textMuted`, `accent`, `danger`,
and `border`) to colors. `Design.barColor(role)` falls back to the ordinary role
when there is no override. Use bar roles only for content painted on the bar;
popup interiors and separately filled capsules retain their own colors.

To offer optional native colors, add a light/dark preset to
[Palettes.js](../config/Palettes.js) with a unique `id` and `kit: "<id>"`.
`Palettes.forKit(kit, selected)` supplies the picker choices, including the current
selection. Native presets do not replace the palette automatically.

## Kit icons

Add an `icons` object to `Kit.qml`, mapping semantic names to a resolved image
URL or an object of native pixel sizes and URLs:

```qml
icons: ({
    settings: {
        16: Qt.resolvedUrl("icons/16/settings.png").toString(),
        32: Qt.resolvedUrl("icons/32/settings.png").toString()
    }
})
```

Use `UI.Icon { name: "settings" }` or `UI.IconButton { iconName: "settings" }`.
[`IconNames.js`](../config/IconNames.js) supplies default glyphs and maps existing
`text` glyphs to semantic names, so state-dependent icons can keep their existing
bindings. Kits can define additional names; supply `text` as their font fallback.
`ToggleTile` accepts `iconName` and keeps `iconGlyph` as its fallback.

`UiKit.iconSource()` selects the smallest native size at least as large as the
requested physical size, or the largest available size. `UI.Icon` accounts for
the screen scale, bounds the image to its control, and preserves the artwork's
colors. Omitted or failed images show the original glyph. Switching kits updates
existing icons immediately. An explicit `source` takes precedence over the kit;
`useKitIcons: false` preserves a caller's custom glyph. Keep icon-only labels in
`UI.Icon`, with adjacent text in a separate label; ordinary `UI.Text` is unchanged.

## Visual slots

| Slots | Purpose |
| --- | --- |
| `controlSurface`, `textFieldSurface` | Control backgrounds |
| `cardSurface`, `menuSurface` | Cards and menus |
| `choiceIndicator`, `switchIndicator` | Checkbox, radio, and switch visuals |
| `sliderTrack`, `sliderHandle` | Slider visuals |
| `scrollBarTrack`, `scrollBarThumb` | Scrollbar visuals; host retains geometry, visibility, and input |
| `barSurface`, `widgetIndicator`, `dropdownSurface` | Bar and popup presentation |

See [Default.Kit](../kits/default/Kit.qml) for the complete contract. Renderers
receive their host through `parent.surface`; [Surface.qml](../kits/default/Surface.qml)
provides standard geometry and border bindings. Keep service calls, input
handlers, and settings writes outside renderers. Preserve keyboard focus,
disabled states, user overrides, and both bar orientations.

Validate with the [development checks](development.md#checks) and
`python3 tests/runners/test-ui-kits.py`.
