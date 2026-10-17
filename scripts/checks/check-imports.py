#!/usr/bin/env python3
"""Enforce shell-root QML imports, including embedded test fixtures."""
import ast
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
QUOTED_IMPORT = re.compile(r'^[ \t]*(?:import|\.import)\s+[\"\']', re.MULTILINE)

FLAT_SERVICE_IMPORT = re.compile(r'^[ \t]*import qs\.services(?:[ \t]+as \w+)?[ \t]*$', re.MULTILINE)


def check():
    errors = []
    for path in sorted(ROOT.rglob('*')):
        if not path.is_file() or path.suffix not in ('.qml', '.js', '.py'):
            continue
        source = path.read_text()
        if path.suffix == '.py':
            # Inspect decoded strings so escaped newlines in mock QML count too.
            if path.name == 'check-imports.py':
                continue
            tree = ast.parse(source, filename=str(path))
            snippets = [(node.value, node.lineno) for node in ast.walk(tree)
                        if isinstance(node, ast.Constant) and isinstance(node.value, str)]
        else:
            snippets = [(source, 1)]
        for snippet, start in snippets:
            for match in QUOTED_IMPORT.finditer(snippet):
                line = start + snippet.count('\n', 0, match.start())
                errors.append(f'{path.relative_to(ROOT)}:{line}: use a qs.* module import')
            for match in FLAT_SERVICE_IMPORT.finditer(snippet):
                line = start + snippet.count('\n', 0, match.start())
                errors.append(f'{path.relative_to(ROOT)}:{line}: import a specific qs.services.<feature> module')

    loose_services = [path.name for path in (ROOT / 'services').iterdir()
                      if path.is_file() and (path.suffix in ('.qml', '.js') or path.name == 'qmldir')]
    if loose_services:
        errors.append(f'services/: put service sources and module exports in feature directories: {sorted(loose_services)}')

    for folder in ('components', 'config', 'services', 'modules', 'kits', 'tools'):
        for directory in [ROOT / folder, *(p for p in (ROOT / folder).rglob('*') if p.is_dir())]:
            files = sorted(p for p in directory.iterdir() if p.is_file()
                           and p.suffix in ('.qml', '.js') and p.stem[0].isupper())
            if not files:
                continue
            registry = directory / 'qmldir'
            source = registry.read_text() if registry.exists() else ''
            module = 'qs.' + '.'.join(directory.relative_to(ROOT).parts)
            if f'module {module}' not in source.splitlines():
                errors.append(f'{registry.relative_to(ROOT)}: missing module {module}')
            registered = {line.split()[-1] for line in source.splitlines()
                          if line.split() and line.split()[-1].endswith(('.qml', '.js'))}
            expected = {p.name for p in files}
            if registered != expected:
                errors.append(f'{registry.relative_to(ROOT)}: exports differ from files: '
                              f'{sorted(registered ^ expected)}')
    return errors


if __name__ == '__main__':
    errors = check()
    if errors:
        print('\n'.join(errors), file=sys.stderr)
        sys.exit(1)
    print('QML imports use qs.* modules; module exports match source files.')
