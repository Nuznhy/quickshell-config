"""Install the production UI library beside isolated test configuration."""
from pathlib import Path
import re
import shutil


def install_design(target):
    root = Path(__file__).resolve().parent.parent
    shutil.copytree(root / 'components/ui', target / 'components/ui', dirs_exist_ok=True)
    shutil.copyfile(root / 'config/Design.qml', target / 'config/Design.qml')
    registry = target / 'config/qmldir'
    content = registry.read_text()
    if 'singleton Design ' not in content:
        registry.write_text(content + 'singleton Design 1.0 Design.qml\n')
    # Older feature fixtures define only the palette roles they used directly.
    # Complete that palette so the same production tokens work in every fixture.
    theme = target / 'config/Theme.qml'
    source = theme.read_text()
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
