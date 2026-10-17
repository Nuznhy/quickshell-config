#!/usr/bin/env python3
"""Exercise production primitives and render the gallery with isolated state."""
from pathlib import Path
import os
import shutil
import subprocess
import sys
import tempfile
from design_test_support import prepare_service_dirs, write_service_registry, prepare_script_dirs, qml_import_path, install_design, component_path

root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='qs-design-') as directory:
    base = Path(directory)
    prepare_service_dirs(base)
    prepare_script_dirs(base)
    (base / 'config').mkdir()
    (base / 'runtime').mkdir(mode=0o700)
    (base / 'config/qmldir').write_text('singleton Theme 1.0 Theme.qml\n')
    (base / 'config/Theme.qml').write_text('''pragma Singleton
import QtQuick
import qs.config as ConfigScripts
QtObject {
    property string fontFamily: "JetBrainsMono Nerd Font"
    property bool ready: true
    property bool verticalBar: false
    property int sideBarWidth: 64
    property var widgetStyle: ConfigScripts.WidgetStyle.defaults()
    function setWidgetStyle(key, value) { widgetStyle = ConfigScripts.WidgetStyle.normalize(Object.assign({}, widgetStyle, {[key]: value})); }
    function resetWidgetStyle() { widgetStyle = ConfigScripts.WidgetStyle.defaults(); }
    function save() {}
}
''')
    (base / 'services').mkdir(exist_ok=True)
    write_service_registry(base, 'singleton CalendarFeed 1.0 CalendarFeed.qml\nCalendarEvents 1.0 CalendarEvents.qml\n')
    (base / 'services/calendar/CalendarFeed.qml').write_text('''pragma Singleton
import QtQuick
QtObject { property bool enabled: false; property bool busy: false }
''')
    (base / 'services/calendar/CalendarEvents.qml').write_text('''import QtQuick
QtObject {
    property bool active: false
    property date firstDate
    property date endDate
    property bool loading: false
    property string errorMessage: ""
    function eventsOn(date) { return []; }
    function refresh() {}
}
''')
    install_design(base)
    shutil.copyfile(root / 'config/Palettes.js', base / 'config/Palettes.js')
    shutil.copytree(root / 'tools/gallery', base / 'tools/gallery')
    for name in ['ControlSwitch.qml', 'AudioSlider.qml', 'MediaSeekSlider.qml', 'NotificationButton.qml',
                 'BarHoverIndicator.qml', 'WidgetStyleSettings.qml', 'AppearanceSlider.qml', 'AudioLevelControl.qml', 'CalendarPanel.qml', 'MediaDetails.qml', 'AudioDeviceDropdown.qml']:
        shutil.copyfile(component_path(root, name), component_path(base, name))
    for path in (root / 'tests/design_system').glob('tst_*.qml'):
        shutil.copyfile(path, base / path.name)
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND=os.environ.get('QT_QUICK_BACKEND', 'software'),
               XDG_RUNTIME_DIR=str(base / 'runtime'), XDG_CACHE_HOME=str(base / 'cache'),
               XDG_STATE_HOME=str(base / 'state'))
    subprocess.run([os.environ.get('QMLTESTRUNNER', '/usr/lib/qt6/bin/qmltestrunner'),
                    '-import', str(qml_import_path(base)), '-input', str(base), *sys.argv[1:]], env=env, check=True)
