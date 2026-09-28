#!/usr/bin/env python3
"""Render wallpaper effects and test loading, rapid changes, and mode controls."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='qs-wallpaper-transitions-') as directory:
    base = Path(directory)
    for name in ['components','modules/bar/widgets','config','runtime']:
        (base/name).mkdir(parents=True,mode=0o700)
    for name in ['WallpaperTransition.qml','BarHoverIndicator.qml']:
        shutil.copyfile(root/'components'/name,base/'components'/name)
    shutil.copyfile(root/'modules/bar/widgets/ThemeModeWidget.qml',base/'modules/bar/widgets/ThemeModeWidget.qml')
    shutil.copyfile(root/'tests/wallpaper_transitions/tst_transition.qml',base/'tst_transition.qml')
    (base/'config/qmldir').write_text('singleton Theme 1.0 Theme.qml\nsingleton Settings 1.0 Settings.qml\n')
    (base/'config/Theme.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
 property string mode: "dark"
 readonly property bool isDark: mode === "dark"
 property bool ready: true
 property bool verticalBar: false
 property int fontSize: 20
 property int sideBarWidth: 64
 property string fontFamily: "sans-serif"
 property color text: "white"
 property color iris: "#c4a7e7"
 property color love: "#eb6f92"
 function selectMode(value) { if (ready) mode = value; }
}
''')
    (base/'config/Settings.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { property int barHeight: 42 }\n')
    for name,color in [('red','#e03020'),('blue','#2040e0')]:
        (base/(name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="600" height="340"><path fill="{color}" d="M0 0h600v340H0z"/><circle fill="white" cx="300" cy="170" r="50"/></svg>')
    env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',XDG_RUNTIME_DIR=str(base/'runtime'))
    subprocess.run(['/usr/lib/qt6/bin/qmltestrunner','-input',str(base)],env=env,check=True)
