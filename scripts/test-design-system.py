#!/usr/bin/env python3
"""Exercise production primitives and render the gallery with isolated state."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
from design_test_support import install_design

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='qs-design-') as directory:
    base = Path(directory)
    (base / 'config').mkdir()
    (base / 'runtime').mkdir(mode=0o700)
    (base / 'config/qmldir').write_text('singleton Theme 1.0 Theme.qml\n')
    (base / 'config/Theme.qml').write_text('''pragma Singleton
import QtQuick
QtObject { property string fontFamily: "JetBrainsMono Nerd Font" }
''')
    install_design(base)
    shutil.copyfile(root / 'config/Palettes.js', base / 'config/Palettes.js')
    shutil.copytree(root / 'tools/design-gallery', base / 'tools/design-gallery')
    for name in ['ControlSwitch.qml', 'AudioSlider.qml', 'MediaSeekSlider.qml', 'NotificationButton.qml',
                 'AudioLevelControl.qml', 'CalendarPanel.qml', 'MediaDetails.qml', 'AudioDeviceDropdown.qml']:
        shutil.copyfile(root / 'components' / name, base / 'components' / name)
    for path in (root / 'tests/design_system').glob('tst_*.qml'):
        shutil.copyfile(path, base / path.name)
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
               XDG_RUNTIME_DIR=str(base / 'runtime'), XDG_CACHE_HOME=str(base / 'cache'),
               XDG_STATE_HOME=str(base / 'state'))
    subprocess.run([os.environ.get('QMLTESTRUNNER', '/usr/lib/qt6/bin/qmltestrunner'),
                    '-input', str(base)], env=env, check=True)
