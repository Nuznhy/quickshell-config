# Development

[Home](../README.md) · [Code style](code-style.md) · [UI kits](ui-kits.md) · [Repository rules](../AGENTS.md)

## Architecture

Keep related features together across UI, services, scripts, and tests:

```text
modules/audio/       Audio panels and controls
services/audio/      Shared audio state and actions
scripts/audio/       Runtime command helpers
tests/runners/       Feature test entry points and fixture support
```

`modules/bar/` owns bar composition and `widgets/` contains its triggers.
`modules/settings/` composes settings pages; feature-specific settings stay with
their feature. Shared controls belong in `components/ui/`, popup mechanics in
`components/popup/`, and other reusable adapters in `components/shared/`.

Dependencies flow from entry points to modules, then services, configuration,
and shared controls. Services, configuration, and shared controls must not
import feature UI.
Keep state and polling in services so screens share one instance.

Always use shell-root imports:

```qml
import qs.config
import qs.components.ui as UI
import qs.services.audio
import qs.config as ConfigScripts
```

Each module owns its `qmldir`, including singleton and JavaScript exports.
For example, palette data is available as `ConfigScripts.Palettes`. Resolve
runtime helpers with `Quickshell.shellPath("scripts/<feature>/<file>")`.
Keep runnable QML entry points at the repository root.

To add a bar widget, create it in `modules/bar/widgets/` and register it in
[BarLayoutData.js](../config/BarLayoutData.js). Follow the matching feature's
service and test patterns.

## Editor support

The root `.qmlls.ini` enables Quickshell's managed QML language-server
configuration. Start or restart Quickshell to populate it, then restart
`qmlls` in Neovim with `:LspRestart`. Quickshell supplies the import paths
for Qt, Quickshell, and the shell's `qs.*` modules.

## Checks

Run from the repository root:

```sh
bash scripts/check.sh
python3 tests/runners/test-settings.py
python3 tests/runners/test-design-system.py
```

Run the [test runner](../tests/runners/) for each changed feature. Backend tests
can also run directly, for example:

```sh
python3 -m unittest discover -s tests/battery -v
```

Checks enforce imports, module exports, and QML syntax. Qt tests use
`qmltestrunner`; native tests may need local IPC sockets or a private D-Bus
session. Tests use temporary state and mocked hardware. The workspace-preview
smoke test runs in a live Hyprland session.

Use [design_test_support.py](../tests/runners/design_test_support.py) to stage
fixtures at production paths. Avoid copying services or controls into a flat
test-only layout. Set `QMLFORMAT` or `QMLTESTRUNNER` if Qt tools live elsewhere.

Preview visuals with `quickshell --path gallery.qml`. Keep changes focused,
update related documentation and exports, and include relevant test results
when contributing.
