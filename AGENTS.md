# Repository rules

See [Development](docs/development.md) for architecture and checks, and
[README](README.md) for the documentation index.

## File ownership

- Feature UI and settings panels: `modules/<feature>/`.
- Bar composition and triggers: `modules/bar/` and `modules/bar/widgets/`.
- Settings navigation and general shell settings: `modules/settings/`.
- Shared state, polling, and system integration: `services/<feature>/`.
- Runtime helpers and their templates: `scripts/<feature>/`.
- Reusable controls: `components/ui/`, `components/popup/`, `components/shared/`.
- Preferences and design configuration: `config/`; visual implementations: `kits/`.
- External configuration: `integrations/`; project guides: `docs/`.
- Feature tests and fixtures: `tests/<feature>/`; runners and support: `tests/runners/`.

Keep related service JavaScript beside its owner. Calendar owns clock/feed
services; display owns display-mode and desktop/TV state; quicksettings owns
quick controls and system information. Do not add loose source files or a
combined registry under `components/` or `services/`.

## Dependencies and imports

- Entry points compose modules, services, configuration, and shared controls.
  Services, configuration, and shared controls must not import feature UI.
  Avoid circular dependencies.
- Always use `qs.*` module imports, including specific `qs.services.<feature>`
  imports. Do not use relative imports, `root:/`, or filesystem paths for imports.
- Each feature owns its `qmldir`; register QML types, singletons, and JavaScript
  helpers there. Preserve shared singleton identity across consumers.
- Resolve runtime helpers with `Quickshell.shellPath("scripts/<feature>/<file>")`.
- Keep runnable QML entry points at the repository root. Runtime scripts must
  not depend on test support.
- The three top-level power/lock Python scripts are compatibility launchers;
  keep their implementations in `scripts/power/`.

## Changes and verification

Follow [Code style](docs/code-style.md) when adding or editing code.

Update callers, module exports, fixtures, integrations, and docs together.
Keep documentation concise and linked; omit machine-specific notes and fix history.
Run `bash scripts/check.sh` and the affected feature tests. Preserve production
paths in fixtures using [design_test_support.py](tests/runners/design_test_support.py);
pass `qml_import_path(fixture)` to QtTest's `-import` option.
