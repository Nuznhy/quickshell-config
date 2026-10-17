"""Install the production UI library beside isolated test configuration."""
from pathlib import Path
import re
import shutil


def install_design(target):
    root = Path(__file__).resolve().parents[2]
    prepare_component_dirs(target)
    shutil.copytree(root / 'kits', target / 'kits', dirs_exist_ok=True)
    shutil.copyfile(root / 'config/UiKit.qml', target / 'config/UiKit.qml')
    shutil.copyfile(root / 'config/Palettes.js', target / 'config/Palettes.js')
    shutil.copytree(root / 'components/ui', target / 'components/ui', dirs_exist_ok=True)
    shutil.copyfile(root / 'config/Design.qml', target / 'config/Design.qml')
    shutil.copyfile(root / 'config/WidgetStyle.js', target / 'config/WidgetStyle.js')
    shutil.copyfile(root / 'config/WallpaperColors.js', target / 'config/WallpaperColors.js')
    registry = target / 'config/qmldir'
    content = registry.read_text()
    if 'singleton Design ' not in content:
        registry.write_text(content + 'singleton Design 1.0 Design.qml\n')
    if 'singleton UiKit ' not in registry.read_text():
        with registry.open('a') as stream:
            stream.write('singleton UiKit 1.0 UiKit.qml\n')
    # Older feature fixtures define only the palette roles they used directly.
    # Complete that palette so the same production tokens work in every fixture.
    theme = target / 'config/Theme.qml'
    source = theme.read_text()
    if not re.search(r'property\s+string\s+uiKit\s*:', source):
        end = source.rfind('}')
        source = source[:end] + '\n    property string uiKit: "default"\n' + source[end:]
        theme.write_text(source)
    source = theme.read_text()
    if not re.search(r'property\s+string\s+mode\s*:', source):
        end = source.rfind('}')
        source = source[:end] + '\n    property string mode: "dark"\n' + source[end:]
        theme.write_text(source)
    colors = dict(bg='#191724', surface='#1f1d2e', overlay='#26233a',
                  muted='#6e6a86', subtle='#908caa', text='#e0def4',
                  love='#eb6f92', gold='#f6c177', rose='#ebbcba', pine='#31748f',
                  foam='#9ccfd8', iris='#c4a7e7', highlightLow='#21202e',
                  highlightMed='#403d52', highlightHigh='#524f67')
    missing = ''.join(f'    property color {name}: "{color}"\n'
                      for name, color in colors.items()
                      if not re.search(r'property\s+color\s+' + name + r'\s*:', source))
    if missing:
        end = source.rfind('}')
        theme.write_text(source[:end] + '\n' + missing + source[end:])

    qml_import_path(target)


def component_path(base, name):
    """Resolve a production UI path and prepare its destination in a fixture."""
    root = Path(__file__).resolve().parents[2]
    candidates = [path for folder in ('components', 'modules')
                  for path in (root / folder).rglob(name)]
    if len(candidates) != 1:
        raise ValueError(f"Expected one production component named {name}: {candidates}")
    destination = Path(base) / candidates[0].relative_to(root)
    if Path(base) != root:
        destination.parent.mkdir(parents=True, exist_ok=True)
    return destination


def prepare_component_dirs(target):
    """Mirror production UI directories before installing selected types or mocks."""
    root = Path(__file__).resolve().parents[2]
    prepare_script_dirs(target)
    for folder in ('components', 'modules'):
        for path in (root / folder).rglob('*'):
            if path.is_dir():
                (target / path.relative_to(root)).mkdir(parents=True, exist_ok=True)


def qml_import_path(target):
    """Expose an isolated shell as qs.* modules to the standard Qt test runner."""
    target = Path(target)
    for folder in ('components', 'config', 'services', 'modules', 'kits', 'tools', 'widgets'):
        base = target / folder
        if not base.exists():
            continue
        for directory in [base, *(p for p in base.rglob('*') if p.is_dir())]:
            qml = sorted(p for p in directory.glob('*.qml') if p.stem[0].isupper())
            scripts = sorted(directory.glob('*.js'))
            if not qml and not scripts:
                continue
            registry = directory / 'qmldir'
            previous = registry.read_text() if registry.exists() else ''
            lines = ['module qs.' + '.'.join(directory.relative_to(target).parts)]
            for path in qml:
                singleton = (re.search(r'^pragma Singleton\b', path.read_text(), re.M)
                             or re.search(r'^singleton ' + re.escape(path.stem) + r'\b', previous, re.M))
                lines.append(f'{"singleton " if singleton else ""}{path.stem} 1.0 {path.name}')
            lines.extend(f'{path.stem} 1.0 {path.name}' for path in scripts)
            registry.write_text('\n'.join(lines) + '\n')
    imports = target / '.qml-imports'
    imports.mkdir(exist_ok=True)
    alias = imports / 'qs'
    if not alias.exists():
        alias.symlink_to(target, target_is_directory=True)
    return imports


def prepare_script_dirs(target):
    """Preserve feature script paths when installing mocks in isolated shells."""
    root = Path(__file__).resolve().parents[2]
    (Path(target) / 'scripts').mkdir(parents=True, exist_ok=True)
    for folder in (root / 'scripts').iterdir():
        if folder.is_dir() and folder.name != '__pycache__':
            (Path(target) / 'scripts' / folder.name).mkdir(parents=True, exist_ok=True)


def script_path(base, name):
    """Resolve a runtime helper by its feature path and prepare fixture parents."""
    root = Path(__file__).resolve().parents[2]
    candidates = [path for path in (root / 'scripts').glob('*/*')
                  if path.is_file() and path.name == name]
    if len(candidates) != 1:
        raise ValueError(f'Expected one runtime helper named {name}: {candidates}')
    destination = Path(base) / candidates[0].relative_to(root)
    if Path(base) != root:
        destination.parent.mkdir(parents=True, exist_ok=True)
    return destination


def prepare_service_dirs(target):
    """Create feature service directories before installing selected mocks."""
    root = Path(__file__).resolve().parents[2]
    for folder in (root / 'services').iterdir():
        if folder.is_dir() and folder.name != '__pycache__':
            (Path(target) / 'services' / folder.name).mkdir(parents=True, exist_ok=True)


def service_path(base, name):
    """Resolve a service or its JS helper using the production feature path."""
    root = Path(__file__).resolve().parents[2]
    # The workspace fixture substitutes Quickshell.Hyprland beside Workspaces.
    if name == 'Hyprland.qml':
        relative = Path('services/workspaces/Hyprland.qml')
    else:
        candidates = [path for path in (root / 'services').glob('*/*')
                      if path.is_file() and path.name == name]
        if len(candidates) != 1:
            raise ValueError(f'Expected one service named {name}: {candidates}')
        relative = candidates[0].relative_to(root)
    destination = Path(base) / relative
    if Path(base) != root:
        destination.parent.mkdir(parents=True, exist_ok=True)
    return destination


def write_service_registry(target, declarations):
    """Register selected service mocks in their production feature modules."""
    groups = {}
    for line in declarations.splitlines():
        if not line.strip() or line.startswith('module '):
            continue
        folder = service_path(target, line.split()[-1]).parent
        groups.setdefault(folder, []).append(line)
    for folder, lines in groups.items():
        module = 'qs.' + '.'.join(folder.relative_to(target).parts)
        (folder / 'qmldir').write_text('\n'.join(['module ' + module, *lines]) + '\n')
