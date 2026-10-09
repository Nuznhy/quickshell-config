#!/usr/bin/env python3
"""Test per-window workspace icons, focus targets, and animated lifecycle."""
from pathlib import Path
from design_test_support import install_design
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='qs-workspace-test-') as directory:
    base = Path(directory)
    for folder in ['components','services','config','runtime','modules/bar/widgets']:
        (base / folder).mkdir(parents=True, mode=0o700)
    shutil.copyfile(root / 'services/WorkspaceWindows.js', base / 'services/WorkspaceWindows.js')
    shutil.copyfile(root / 'services/WorkspacePreviewData.js', base / 'services/WorkspacePreviewData.js')
    source = (root / 'components/WorkspacePreviewContent.qml').read_text()
    (base / 'components/WorkspacePreviewContent.qml').write_text(source.replace('import Quickshell.Wayland\n','').replace('import Quickshell.Widgets\n',''))
    (base / 'components/ScreencopyView.qml').write_text('import QtQuick\nItem { property var captureSource; property bool live; property bool paintCursor; property bool hasContent: false; function captureFrame() {} }\n')
    source = (root / 'modules/bar/widgets/WorkspaceBar.qml').read_text()
    (base / 'modules/bar/widgets/WorkspaceBar.qml').write_text(source.replace('import Quickshell\n','').replace('import Quickshell.Hyprland\n','').replace('workspaceBar.QsWindow.window','null'))
    shutil.copyfile(root / 'components/BarHoverIndicator.qml', base / 'components/BarHoverIndicator.qml')
    (base / 'components/WorkspacePreview.qml').write_text('''import QtQuick
Item {
 objectName: "workspace-preview"
 property var barWindow
 property int workspaceId: -1
 property string highlightedAddress: ""
 function request(id, item, address) { workspaceId=id; highlightedAddress=address; }
 function leave(id) { if (id===workspaceId) {workspaceId=-1;highlightedAddress="";} }
 function close() {workspaceId=-1;highlightedAddress="";}
}
''')
    # IconImage belongs to the Quickshell executable; substitute only that
    # renderer for QtTest, leaving the production model, mouse areas and timers.
    source = (root / 'components/AnimatedAppIcons.qml').read_text()
    (base / 'components/AnimatedAppIcons.qml').write_text(source.replace('import Quickshell.Widgets\n',''))
    (base / 'components/IconImage.qml').write_text('import QtQuick\nItem { property url source; readonly property int status: Image.Null; property int implicitSize: 20; implicitWidth: implicitSize; implicitHeight: implicitSize }\n')
    (base / 'config/qmldir').write_text('singleton Theme 1.0 Theme.qml\nsingleton Settings 1.0 Settings.qml\n')
    with (base / 'config/qmldir').open('a') as stream:
        stream.write('singleton WorkspaceAppearance 1.0 WorkspaceAppearance.qml\n')
    for name in ['WorkspaceAppearanceData.js', 'AppGlyphs.js']:
        shutil.copyfile(root / 'config' / name, base / 'config' / name)
    appearance = (root / 'config/WorkspaceAppearance.qml').read_text().split('    Timer {')[0]
    appearance = appearance.replace('import Quickshell\n', '').replace('import Quickshell.Io\n', '').replace('Singleton {', 'QtObject {').replace('property bool ready: false', 'property bool ready: true').replace('saveTimer.restart();', '')
    (base / 'config/WorkspaceAppearance.qml').write_text(appearance + '}\n')
    (base / 'config/Settings.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { property int barHeight: 42 }\n')
    (base / 'config/Theme.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
 property bool verticalBar: false
 property int fontSize: 20
 property string fontFamily: "sans-serif"
 property string barFontFamily: fontFamily
 property color bg: "#191724"
 property color text: "#e0def4"
 property color love: "#eb6f92"
 property color iris: "#c4a7e7"
 property color surface: "#1f1d2e"
 property color highlightMed: "#403d52"
 property int sideBarWidth: 64
 function wallpaperFor(name) {return "";}
}
''')
    (base / 'services/qmldir').write_text('singleton Workspaces 1.0 Workspaces.qml\nsingleton Hyprland 1.0 Hyprland.qml\n')
    (base / 'services/Hyprland.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { function dispatch(command) {} }\n')
    (base / 'services/Workspaces.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
 property string lastFocused: ""
 property var urgent: []
 property var previewWindows: []
 property var workspaceIcons: ({})
 property var occupiedWorkspaceIds: Object.keys(workspaceIcons).map(id => Number(id))
 property int activeWorkspaceId: 1
 function getWsIcons(id) {return workspaceIcons[id] || [];}
 function getWsWindows(id) {return previewWindows;}
 function captureSource(address) {return null;}
 function needsAttention(appId, addresses) { return addresses.some(address => urgent.includes(address)); }
 function focusWindow(address) { lastFocused = address; }
}
''')
    shutil.copyfile(root / 'tests/workspaces/tst_windows.qml', base / 'tst_windows.qml')
    shutil.copyfile(root / 'tests/workspaces/tst_preview.qml', base / 'tst_preview.qml')
    install_design(base)
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', XDG_RUNTIME_DIR=str(base / 'runtime'))
    subprocess.run(['/usr/lib/qt6/bin/qmltestrunner','-input',str(base)],env=env,check=True)
