#!/usr/bin/env python3
"""Test per-window workspace icons, focus targets, and animated lifecycle."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='qs-workspace-test-') as directory:
    base = Path(directory)
    for folder in ['components','services','config','runtime']:
        (base / folder).mkdir(mode=0o700)
    shutil.copyfile(root / 'services/WorkspaceWindows.js', base / 'services/WorkspaceWindows.js')
    # IconImage belongs to the Quickshell executable; substitute only that
    # renderer for QtTest, leaving the production model, mouse areas and timers.
    source = (root / 'components/AnimatedAppIcons.qml').read_text()
    (base / 'components/AnimatedAppIcons.qml').write_text(source.replace('import Quickshell.Widgets\n',''))
    (base / 'components/IconImage.qml').write_text('import QtQuick\nImage {}\n')
    (base / 'config/qmldir').write_text('singleton Theme 1.0 Theme.qml\n')
    (base / 'config/Theme.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
 property bool verticalBar: false
 property int fontSize: 20
 property string fontFamily: "sans-serif"
 property color bg: "#191724"
 property color text: "#e0def4"
 property color love: "#eb6f92"
}
''')
    (base / 'services/qmldir').write_text('singleton Workspaces 1.0 Workspaces.qml\n')
    (base / 'services/Workspaces.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
 property string lastFocused: ""
 property var urgent: []
 function needsAttention(appId, addresses) { return addresses.some(address => urgent.includes(address)); }
 function focusWindow(address) { lastFocused = address; }
}
''')
    shutil.copyfile(root / 'tests/workspaces/tst_windows.qml', base / 'tst_windows.qml')
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', XDG_RUNTIME_DIR=str(base / 'runtime'))
    subprocess.run(['/usr/lib/qt6/bin/qmltestrunner','-input',str(base)],env=env,check=True)
