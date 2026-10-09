#!/usr/bin/env python3
"""Exercise quick controls without changing desktop theme, DND or screen colors."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
subprocess.run(['python3', '-m', 'unittest', 'discover', '-s', str(root/'tests/quick_controls'), '-v'], check=True)
with tempfile.TemporaryDirectory(prefix='qs-quick-controls-') as directory:
    base = Path(directory)
    for name in ['components', 'config', 'services', 'runtime', 'widgets']:
        (base/name).mkdir(mode=0o700)
    for name in ['QuickSettings.qml', 'NotificationButton.qml', 'AppearanceSlider.qml', 'SystemInfoPanel.qml', 'BatteryCenter.qml']:
        shutil.copyfile(root/'components'/name, base/'components'/name)
    shutil.copyfile(root/'tests/quick_controls/tst_panel.qml', base/'tst_panel.qml')
    shutil.copyfile(root/'tests/quick_controls/tst_system_info.qml', base/'tst_system_info.qml')
    widget = (root/'modules/bar/widgets/BatteryWidget.qml').read_text().replace('import Quickshell\n', '').replace('"../../../', '"../').replace('barWindow: root.QsWindow.window', 'barWindow: null')
    (base/'widgets/BatteryWidget.qml').write_text(widget)
    (base/'components/DropdownWidget.qml').write_text('''import QtQuick
Item {
    property var barWindow
    property int popupWidth: 0
    property bool sizeToContent: false
    property bool showStem: false
    property string stemAlignment: ""
    property bool focusGrabEnabled: true
    property bool popupDismissEnabled: true
    property bool dropdownOpen: false
    property Component popupContent
}
''')
    mocks = {
        'config/Settings': '''property int barHeight: 42''',
        'config/Theme': '''property bool verticalBar: false
            property int fontSize: 20
            property string mode: "dark"
            readonly property bool isDark: mode === "dark"
            property bool ready: true
            property string fontFamily: "JetBrainsMono Nerd Font"
            property string barFontFamily: fontFamily
            property color love: "#eb6f92"
            property color text: "#e0def4"
            property color subtle: "#908caa"
            property color iris: "#c4a7e7"
            property color foam: "#9ccfd8"
            property color surface: "#1f1d2e"
            property color overlay: "#26233a"
            property color highlightHigh: "#524f67"
            property color highlightMed: "#403d52"
            property color bg: "#191724"
            function selectMode(value) { mode = value; }''',
        'services/QuickControls': '''property int openPanels: 0
            property string hostname: "nuznhyarch"
            property string osName: "Arch Linux"
            property string uptime: "Up 1h 24m"
            property string errorMessage: ""
            property bool ready: true
            property int strength: 50
            readonly property int temperature: 6500 - strength * 50
            property string settingsError: ""
            function setStrength(value) { strength = Math.round(value); }
            property bool nightEnabled: false
            property bool available: true
            property bool busy: false
            function toggleNightShift() { nightEnabled = !nightEnabled; }''',
        'services/SystemInfo': '''property int openPanels: 0
            property var details: ({os: "Arch Linux", kernel: "7.2.6", cpu: "Ryzen 7 5800X3D", gpu: "NVIDIA RTX 4090", ram: "64 GiB", disk: "300 GiB free / 1 TiB total"})
            property bool checkingUpdates: false
            property int updateCount: 3
            property double checkedAt: 0
            property string errorMessage: ""
            property string updateError: ""
            function checkUpdates() { updateCount = 4; }''',
        'services/NetworkState': '''property var connections: [{state: "activated", name: "Home", devices: ["eth0"], ipv4: ["192.168.1.2"], ipv6: [], vpn: false}]
            property string statusError: ""
            function refresh() {}''',
        'services/BatteryState': '''property int openPanels: 0
            property var batteries: []
            property var powerProfiles: ({available: false, current: "", profiles: []})
            property string lastProfile: ""
            property string actionKind: "limit"
            function setProfile(profile) { actionKind = "profile"; lastProfile = profile; }
            property bool changing: false
            property bool charging: false
            property real percent: 72
            property string icon: "󰁹"
            readonly property bool present: batteries.length > 0
            property string errorMessage: ""
            property string message: ""
            property string lastId: ""
            property int lastLimit: 0
            function setLimit(id, limit) { lastId = id; lastLimit = limit; }''',
        'services/Notifications': '''property bool doNotDisturb: false
            function setDoNotDisturb(value) { doNotDisturb = value; }'''
    }
    for name, body in mocks.items():
        path = base/name
        path.with_suffix('.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject {\n'+body+'\n}\n')
        with (path.parent/'qmldir').open('a') as f:
            f.write(f'singleton {path.name} 1.0 {path.name}.qml\n')
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', XDG_RUNTIME_DIR=str(base/'runtime'))
    subprocess.run(['/usr/lib/qt6/bin/qmltestrunner', '-input', str(base)], env=env, check=True)

    # Real singleton, Process queue and FileView persistence; fake only the
    # hyprsunset backend so these checks never change the user's screen colors.
    import json
    (base/'scripts').mkdir()
    shutil.copyfile(root/'services/QuickControls.qml', base/'services/QuickControls.qml')
    (base/'scripts/quick-controls.py').write_text('''import json, os, sys, time
from pathlib import Path
time.sleep(0.2)
with Path(os.environ['QS_CONTROL_CALLS']).open('a') as log:
    log.write(json.dumps(sys.argv[1:]) + '\\n')
print(json.dumps(dict(available=True, enabled=sys.argv[1] != 'off', error='')))
''')
    (base/'shell.qml').write_text('''import QtQuick
import Quickshell
import "services"
ShellRoot {
    property int ticks: 0
    property int phase: 0
    function fail(message) { console.error("CONTROLS_FAILED: " + message); Qt.quit(); }
    Timer {
        interval: 25; repeat: true; running: true
        onTriggered: {
            ticks++;
            if (ticks > 160) { fail("timeout"); return; }
            if (!QuickControls.ready) return;
            if (Quickshell.env("QS_CONTROL_PHASE") === "restore") {
                if (QuickControls.strength !== 90) { fail("saved strength"); return; }
                if (QuickControls.temperature !== 2000) { fail("temperature mapping"); return; }
                console.log("CONTROLS_OK: persistence"); Qt.quit(); return;
            }
            if (phase === 0) {
                QuickControls.available = true;
                QuickControls.nightEnabled = true;
                QuickControls.setStrength(10);
                phase = 1;
            } else if (phase === 1 && QuickControls.busy) {
                QuickControls.setStrength(30);
                QuickControls.setStrength(90);
                phase = 2;
            } else if (phase === 2 && ticks > 40 && !QuickControls.busy && !QuickControls.pendingAction) {
                if (QuickControls.settingsError || QuickControls.errorMessage) { fail("service error"); return; }
                console.log("CONTROLS_OK: queue drained"); Qt.quit();
            }
        }
    }
}
''')
    calls = base/'calls.jsonl'
    native_env = dict(env, XDG_STATE_HOME=str(base/'state'), XDG_CACHE_HOME=str(base/'cache'), QS_CONTROL_CALLS=str(calls))
    for phase in ['write', 'restore']:
        result = subprocess.run(['quickshell', '--path', str(base)], env=dict(native_env, QS_CONTROL_PHASE=phase),
                                capture_output=True, text=True, timeout=8)
        output = result.stdout + result.stderr
        assert 'CONTROLS_OK:' in output and 'CONTROLS_FAILED:' not in output, output
        for error in ['TypeError', 'ReferenceError', 'Binding loop', 'Unable to assign']:
            assert error not in output, output
        print(f'PASS: native quick controls {phase}')
    requests = [json.loads(line) for line in calls.read_text().splitlines()]
    assert requests == [['adjust', '--temperature', '6000'], ['adjust', '--temperature', '2000']], requests
    print('PASS: rapid slider updates retain the latest temperature')

    for name in ['BatteryState.qml', 'SystemInfo.qml']:
        shutil.copyfile(root/'services'/name, base/'services'/name)
    (base/'config/BarLayout.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { property bool ready: true; function isEnabled(id) {return false;} }\n')
    with (base/'config/qmldir').open('a') as f:
        f.write('singleton BarLayout 1.0 BarLayout.qml\n')
    (base/'scripts/battery.py').write_text('''import json, sys
from pathlib import Path
state = Path(__file__).with_name('battery-limit')
profile_state = Path(__file__).with_name('power-profile')
if len(sys.argv) > 1 and sys.argv[1] == 'set': state.write_text(sys.argv[3])
if len(sys.argv) > 1 and sys.argv[1] == 'profile': profile_state.write_text(sys.argv[2])
limit = int(state.read_text()) if state.exists() else 100
profile = profile_state.read_text() if profile_state.exists() else 'balanced'
print(json.dumps(dict(batteries=[dict(id="BAT0", percent=75, status="Charging", full=40, unit="Wh", limit=limit, timeRemaining=1800, chargeTarget=limit)], powerProfiles=dict(available=True, current=profile, profiles=[dict(id=p, label=p) for p in ['balanced', 'performance']]), error="", message="Applied")))
''')
    (base/'scripts/system-info.py').write_text('''import json, sys
print(json.dumps(dict(count=4, error="") if len(sys.argv)>1 else dict(os="Test Linux", cpu="Test CPU")))
''')
    (base/'shell.qml').write_text('''import QtQuick
import Quickshell
import "services"
ShellRoot {
    property int ticks: 0
    property int phase: 0
    Timer {
        interval: 25; running: true; repeat: true
        onTriggered: {
            ticks++;
            if (ticks > 100) {console.error("SYSTEM_FAILED: timeout"); Qt.quit(); return;}
            if (phase === 0) {
                BatteryState.openPanels = 1;
                SystemInfo.openPanels = 1;
                phase = 1;
            } else if (phase === 1 && BatteryState.present && SystemInfo.updateCount === 4 && SystemInfo.details.cpu === "Test CPU") {
                if (BatteryState.percent !== 75 || !BatteryState.charging) {console.error("SYSTEM_FAILED: battery summary"); Qt.quit(); return;}
                BatteryState.setLimit("BAT0", 80);
                phase = 2;
            } else if (phase === 2 && !BatteryState.changing && BatteryState.batteries[0].limit === 80) {
                if (BatteryState.errorMessage) {console.error("SYSTEM_FAILED: apply error"); Qt.quit(); return;}
                if (BatteryState.batteries[0].timeRemaining !== 1800 || !BatteryState.powerProfiles.available) {console.error("SYSTEM_FAILED: estimates/profiles"); Qt.quit(); return;}
                BatteryState.setProfile("performance");
                phase = 3;
            } else if (phase === 3 && !BatteryState.changing && BatteryState.powerProfiles.current === "performance") {
                if (BatteryState.errorMessage) {console.error("SYSTEM_FAILED: profile error"); Qt.quit(); return;}
                console.log("SYSTEM_OK: discovery, estimates, info, updates, charge and profile actions"); Qt.quit();
            }
        }
    }
}
''')
    result = subprocess.run(['quickshell', '--path', str(base)], env=native_env, capture_output=True, text=True, timeout=6)
    output = result.stdout + result.stderr
    assert 'SYSTEM_OK:' in output and 'SYSTEM_FAILED:' not in output, output
    for error in ['TypeError', 'ReferenceError', 'Binding loop', 'Unable to assign']:
        assert error not in output, output
    print('PASS: native battery and system information services')
