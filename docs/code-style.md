# Code style

[Home](../README.md) · [Development](development.md) · [UI kits](ui-kits.md)

## General

- Use four spaces, UTF-8, and a final newline. Remove trailing whitespace.
- Follow nearby code when editing a file; keep unrelated formatting out of changes.
- Prefer descriptive names, small functions, and explicit inputs over clever abstractions.
- Comment on intent and constraints; avoid narrating obvious code or recording fix history.

## QML and JavaScript

- Use `PascalCase.qml` for components and `camelCase` for IDs, properties,
  functions, and signals. Use `root` for the top-level component ID.
- Put pragmas first, then imports. Always use `qs.*` for project imports and
  import specific service modules. Alias shared controls as `UI`.
- Keep the root ID, public properties, signals, and derived state near the top;
  group related handlers and child objects together.
- Use typed properties, `required` inputs, and `readonly` derived values where
  appropriate. Prefer bindings to manually copying state between properties.
- Use braces for JavaScript blocks and semicolons for statements. Use `const`
  for new local values that do not change and `let` for those that do.
- Build feature UI from shared controls. Use `Design` tokens for spacing,
  typography, colors, and animation timings; keep visual overrides in UI kits.
- Keep polling, processes, and shared state in services. Keep rendering and
  interaction in components. See [architecture](development.md#architecture).

## Python

- Use `snake_case` for functions and variables, `PascalCase` for classes, and
  `UPPER_SNAKE_CASE` for constants. Use underscores in importable module filenames.
- Keep imports at the top and executable entry points behind
  `if __name__ == '__main__':`. Importing helpers should not trigger system actions.
- Prefer `pathlib.Path` for paths and argument lists for subprocesses. Set
  timeouts for commands that can block; avoid constructing shell commands.
- Catch expected exceptions, keep errors actionable, and keep diagnostics out
  of structured stdout. Do not include credentials in errors or command arguments.

## Shell

- Use Bash with `#!/usr/bin/env bash` and `set -euo pipefail` for command helpers.
- Quote variable expansions, use arrays for command arguments, and avoid `eval`.
- Validate inputs and propagate failures. Handle expected races explicitly.

## Checks

Run `bash scripts/check.sh` and the affected feature tests from
[Development](development.md#checks). The check command validates imports,
exports, and QML syntax; it does not enforce all style conventions.

To format a changed QML file:

```sh
/usr/lib/qt6/bin/qmlformat -i path/to/Component.qml
```

Review the resulting diff before committing.
