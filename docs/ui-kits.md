# UI kits

[Home](../README.md) · [Development](development.md) · [Palette sources](palettes.md)

Kits control presentation while shared controls retain input handling and state.
Choose a kit in Appearance or preview it with `quickshell --path gallery.qml`.
Gallery choices do not save preferences.

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

## Visual slots

| Slots | Purpose |
| --- | --- |
| `controlSurface`, `textFieldSurface` | Control backgrounds |
| `cardSurface`, `menuSurface` | Cards and menus |
| `choiceIndicator`, `switchIndicator` | Checkbox, radio, and switch visuals |
| `sliderTrack`, `sliderHandle` | Slider visuals |
| `barSurface`, `widgetIndicator`, `dropdownSurface` | Bar and popup presentation |

See [Default.Kit](../kits/default/Kit.qml) for the complete contract. Renderers
receive their host through `parent.surface`; [Surface.qml](../kits/default/Surface.qml)
provides standard geometry and border bindings. Keep service calls, input
handlers, and settings writes outside renderers. Preserve keyboard focus,
disabled states, user overrides, and both bar orientations.

Validate with the [development checks](development.md#checks) and
`python3 tests/runners/test-ui-kits.py`.
