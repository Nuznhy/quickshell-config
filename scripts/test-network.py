#!/usr/bin/env python3
"""Exercise the UI with fake networks. No system connection is changed."""
from pathlib import Path
from design_test_support import install_design
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
subprocess.run(['python3', '-m', 'unittest', 'discover', '-s', str(root / 'tests/network'), '-v'], check=True)
with tempfile.TemporaryDirectory(prefix='qs-network-test-') as directory:
    target = Path(directory)
    for subdir in ['components', 'config', 'services', 'runtime']:
        (target / subdir).mkdir(mode=0o700)
    for name in ['NetworkCenter.qml', 'ControlSwitch.qml', 'NotificationButton.qml']:
        shutil.copyfile(root / 'components' / name, target / 'components' / name)
    shutil.copyfile(root / 'tests/network/fixtures/NetworkState.qml', target / 'services/NetworkState.qml')
    (target / 'services/qmldir').write_text('singleton NetworkState 1.0 NetworkState.qml\n')
    # Fixed test palette avoids constructing Quickshell state services in qmltestrunner.
    (target / 'config/qmldir').write_text('singleton Theme 1.0 Theme.qml\n')
    (target / 'config/Theme.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
    readonly property color bg: "#191724"
    readonly property color surface: "#1f1d2e"
    readonly property color overlay: "#26233a"
    readonly property color highlightMed: "#403d52"
    readonly property color iris: "#c4a7e7"
    readonly property color text: "#e0def4"
    readonly property color muted: "#6e6a86"
    readonly property color subtle: "#908caa"
    readonly property color love: "#eb6f92"
    readonly property color foam: "#9ccfd8"
    readonly property color gold: "#f6c177"
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}
''')
    shutil.copyfile(root / 'tests/network/tst_controls.qml', target / 'tst_controls.qml')
    install_design(target)
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', XDG_RUNTIME_DIR=str(target / 'runtime'))
    subprocess.run([os.environ.get('QMLTESTRUNNER', '/usr/lib/qt6/bin/qmltestrunner'), '-input', str(target)], env=env, check=True)
