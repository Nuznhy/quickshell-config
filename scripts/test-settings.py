#!/usr/bin/env python3
"""Test the layout model, drag/drop UI, and section geometry in isolation."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import json
import time

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='qs-settings-test-') as directory:
    target = Path(directory)
    for subdir in ['config', 'components', 'modules/settings', 'modules/bar/widgets', 'runtime']:
        (target / subdir).mkdir(parents=True, exist_ok=True, mode=0o700)
    for name in ['ControlSwitch.qml', 'NotificationButton.qml', 'WallpaperSelector.qml',
                 'WallpaperPage.qml', 'SettingsIcon.qml', 'SettingsIconEditor.qml', 'BarFontPicker.qml']:
        shutil.copyfile(root / 'components' / name, target / 'components' / name)
    for path in ['config/BarLayoutData.js', 'modules/settings/BarLayoutEditor.qml', 'modules/bar/BarSection.qml']:
        shutil.copyfile(root / path, target / path)
    (target / 'config/qmldir').write_text('singleton Theme 1.0 Theme.qml\nsingleton BarLayout 1.0 BarLayout.qml\nsingleton Settings 1.0 Settings.qml\n')
    theme_source = (root / 'config/Theme.qml').read_text()
    wallpaper_functions = theme_source[theme_source.index('    function wallpaperMode('):theme_source.index('    function setWallpaperFolder(')]
    (target / 'config/Theme.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
    property bool ready: true
    property string wallpaperFolder: ""
    function setWallpaperFolder(value) { wallpaperFolder = value; }
    readonly property string defaultSettingsIcon: "󰒓"
    property string settingsIcon: defaultSettingsIcon
    property string settingsIconSource: ""
    property int fontSize: 20
    readonly property string defaultBarFontFamily: "JetBrainsMono Nerd Font"
    property string barFontFamily: defaultBarFontFamily
    function setBarFontFamily(value) { barFontFamily = value; }
    function setSettingsIcon(glyph, source) {
        settingsIcon = glyph.trim() || defaultSettingsIcon;
        settingsIconSource = source;
    }
    property var connectedScreens: [{name: "DP-1"}, {name: "HDMI-A-1"}]
    property var wallpapers: ({})
    property string mode: "dark"
    property bool separateWallpapers: false
    property var lightWallpapers: ({})
    property var darkWallpapers: ({})
    property Timer saveTimer: Timer { id: appearanceSaveTimer; interval: 250 }
    WALLPAPER_FUNCTIONS
    property bool verticalBar: false
    readonly property color bg: "#191724"
    readonly property color surface: "#1f1d2e"
    readonly property color overlay: "#26233a"
    readonly property color highlightMed: "#403d52"
    readonly property color highlightHigh: "#524f67"
    readonly property color iris: "#c4a7e7"
    readonly property color text: "#e0def4"
    readonly property color subtle: "#908caa"
    readonly property color love: "#eb6f92"
    readonly property string fontFamily: "sans-serif"
}
'''.replace('    WALLPAPER_FUNCTIONS', wallpaper_functions))
    (target / 'config/Settings.qml').write_text('''pragma Singleton
import QtQuick
QtObject { readonly property int barHeight: 42; readonly property int widgetSpacing: 12 }
''')
    (target / 'config/BarLayout.qml').write_text('''pragma Singleton
import QtQuick
import "BarLayoutData.js" as Data
QtObject {
    property var state: Data.defaults()
    property bool ready: true
    property bool showMedia: true
    property bool showWorkspaces: true
    function ids(section) { return state.sections[section]; }
    function entry(id) { return Data.widget(id); }
    function isEnabled(id) { return !state.disabled.includes(id); }
    function reset() { state = Data.defaults(); }
    function setEnabled(id, enabled) { state = Data.setEnabled(state, id, enabled); }
    function move(id, section, index) { state = Data.move(state, id, section, index); }
}
''')
    for name, conditional in [('WorkspaceBar', 'implicitWidth: BarLayout.showWorkspaces ? 30 : 0'),
                              ('Tray', 'implicitWidth: 30'),
                              ('MediaWidget', 'implicitWidth: 30; visible: BarLayout.showMedia')]:
        (target / f'modules/bar/widgets/{name}.qml').write_text('import QtQuick\nimport "../../../config"\nItem { implicitHeight: 42; ' + conditional + ' }\n')
    for path in (root / 'tests/settings').glob('tst_*.qml'):
        shutil.copyfile(path, target / path.name)
    (target / 'test wallpaper.svg').write_text('''<svg xmlns="http://www.w3.org/2000/svg" width="800" height="450">
<defs><linearGradient id="sky" x2="0" y2="1"><stop stop-color="#403d70"/><stop offset="1" stop-color="#ebbcba"/></linearGradient></defs>
<path fill="url(#sky)" d="M0 0h800v450H0z"/><circle cx="590" cy="125" r="50" fill="#f6c177"/>
<path fill="#31748f" d="M0 380L240 140 430 365 580 235 800 400V450H0z"/>
<path fill="#1f1d2e" d="M0 450L180 300 330 420 510 305 800 450z"/></svg>''')
    (target / 'not an image.jpg').write_text('This is not an image.')
    (target / 'gallery/subfolder').mkdir(parents=True)
    (target / 'empty-gallery').mkdir()
    for name in ['first image.svg', 'SECOND.SVG', 'subfolder/nested.svg']:
        shutil.copyfile(target / 'test wallpaper.svg', target / 'gallery' / name)
    (target / 'gallery/readme.txt').write_text('Not a wallpaper')
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', XDG_RUNTIME_DIR=str(target / 'runtime'))
    subprocess.run([os.environ.get('QMLTESTRUNNER', '/usr/lib/qt6/bin/qmltestrunner'), '-input', str(target)], env=env, check=True)

    # Exercise the real FileView singleton across process restarts, never the
    # desktop shell's state. A failed write is produced with a directory at the
    # intended file path, which is reliable even when tests run as root.
    shutil.copyfile(root / 'config/BarLayout.qml', target / 'config/BarLayout.qml')
    (target / 'shell.qml').write_text('''import QtQuick
import Quickshell
import "config"
ShellRoot {
    property int elapsed: 0
    property bool started: false
    function fail(message) { console.error("SETTINGS_TEST_FAILED: " + message); Qt.quit(); }
    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            elapsed += 50;
            if (elapsed > 5000) { fail("timeout"); return; }
            if (!BarLayout.ready) return;
            const phase = Quickshell.env("QS_TEST_PHASE");
            if (!started) {
                started = true;
                if (phase === "write") {
                    BarLayout.move("clock", "start", 1);
                    BarLayout.setEnabled("settings", false);
                } else if (phase === "read") {
                    if (BarLayout.ids("start")[1] !== "clock" || BarLayout.isEnabled("settings")) {
                        fail("saved state was not restored"); return;
                    }
                } else if (phase === "corrupt") {
                    if (!BarLayout.errorMessage || BarLayout.ids("center")[0] !== "clock") {
                        fail("corrupt state did not fall back"); return;
                    }
                    BarLayout.reset();
                } else if (phase === "failure") {
                    BarLayout.setEnabled("tray", false);
                }
            }
            if (elapsed < 900) return;
            if (phase === "failure") {
                if (BarLayout.isEnabled("tray") || !BarLayout.errorMessage.includes("could not save")) {
                    fail("write failure was not surfaced"); return;
                }
            } else if (BarLayout.errorMessage) { fail(BarLayout.errorMessage); return; }
            console.log("SETTINGS_TEST_OK: " + phase);
            Qt.quit();
        }
    }
}
''')
    env.update(XDG_STATE_HOME=str(target / 'state'), XDG_CACHE_HOME=str(target / 'cache'),
               QT_QUICK_BACKEND='software')

    def run_phase(phase):
        result = subprocess.run(['quickshell', '--path', str(target)],
                                env=dict(env, QS_TEST_PHASE=phase),
                                text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                timeout=15, check=True)
        if f'SETTINGS_TEST_OK: {phase}' not in result.stdout or 'SETTINGS_TEST_FAILED' in result.stdout:
            raise AssertionError(result.stdout)
        print(f'PASS: real layout persistence / {phase}', flush=True)

    run_phase('write')
    run_phase('read')
    state_file, = (target / 'state').rglob('bar-layout.json')
    state_file.write_text('{invalid json')
    run_phase('corrupt')
    state_file.unlink()
    state_file.mkdir()
    run_phase('failure')

    # Real settings-window lifecycle and recovery IPC with every widget hidden.
    state_file.rmdir()
    for subdir in ['components', 'config', 'services', 'modules/settings', 'scripts']:
        shutil.copytree(root / subdir, target / subdir, dirs_exist_ok=True)
    (target / 'shell.qml').write_text('''import QtQuick
import Quickshell
import Quickshell.Io
import "config"
import "services"
import "modules/settings"
ShellRoot {
    SettingsWindow { id: window }
    IpcHandler {
        target: "test"
        function hideAll(): void {
            for (const entry of BarLayout.registry) BarLayout.setEnabled(entry.id, false);
        }
        function status(): string {
            return JSON.stringify({visible: window.visible, opened: ShellSettings.opened,
                ready: Theme.ready && BarLayout.ready, disabled: BarLayout.state.disabled.length,
                font: Theme.barFontFamily, folder: Theme.wallpaperFolder, icon: Theme.settingsIcon, iconSource: Theme.settingsIconSource,
                separateWallpapers: Theme.separateWallpapers, wallpapers: Theme.wallpapers,
                lightWallpapers: Theme.lightWallpapers, darkWallpapers: Theme.darkWallpapers,
                lockScreen: Theme.lockScreen,
                error: Theme.errorMessage});
        }
        function preferences(): void {
            Theme.setBarFontFamily("DejaVu Sans");
            Theme.setBarFontFamily("");
            Theme.setBarFontFamily(null);
            Theme.setWallpaperFolder(Qt.resolvedUrl("gallery").toString());
            Theme.setSettingsIcon("★", Qt.resolvedUrl("test wallpaper.svg").toString());
            Theme.setWallpaper("TEST-1", Qt.resolvedUrl("test wallpaper.svg").toString(), "shared");
            Theme.setWallpaper("TEST-1", Qt.resolvedUrl("gallery/first image.svg").toString(), "light");
            Theme.setWallpaper("TEST-1", "", "dark");
            Theme.setSeparateWallpapers(true);
            Theme.setLockBackground("image", Qt.resolvedUrl("test wallpaper.svg").toString());
            Theme.setLockBackground("color", "#123abc");
            Theme.setLockBackground("mode", "color");
            Theme.setLockBackground("color", "not a color");
            Theme.save();
        }
        function checkWallpaperModes(): bool {
            const previousStyle = Theme.wallpaperTransitionStyle;
            Theme.selectMode("light");
            let valid = Theme.wallpaperFor("TEST-1") === Theme.lightWallpapers["TEST-1"];
            valid = valid && Theme.wallpaperTransitionStyle !== previousStyle
                && Theme.wallpaperTransitionStyle >= 0 && Theme.wallpaperTransitionStyle < 6;
            Theme.selectMode("dark");
            valid = valid && Theme.wallpaperFor("TEST-1") === "";
            Theme.setSeparateWallpapers(false);
            valid = valid && Theme.wallpaperFor("TEST-1") === Theme.wallpapers["TEST-1"];
            Theme.selectMode("light");
            valid = valid && Theme.wallpaperFor("TEST-1") === Theme.wallpapers["TEST-1"];
            Theme.setSeparateWallpapers(true);
            valid = valid && Theme.wallpaperFor("TEST-1") === Theme.lightWallpapers["TEST-1"];
            Theme.selectMode("dark");
            Theme.save();
            return valid;
        }
        function monitoring(): bool {
            window.monitoringSettings = true;
            return window.monitoringSettings;
        }
        function monitoringPanels(): int { return SystemStats.panels; }
    }
}
''')
    with (target / 'window.log').open('w+') as log:
        process = subprocess.Popen(['quickshell', '--path', str(target)], env=env,
                                   stdout=log, stderr=subprocess.STDOUT)
        try:
            def ipc(target_name, action):
                result = subprocess.run(['quickshell', 'ipc', '--path', str(target), 'call', target_name, action],
                                        env=env, capture_output=True, text=True, timeout=5)
                if result.returncode:
                    raise RuntimeError(result.stdout + result.stderr)
                return result.stdout.strip()

            deadline = time.monotonic() + 8
            while True:
                try:
                    status = json.loads(ipc('test', 'status'))
                    if status['ready']:
                        break
                except (RuntimeError, json.JSONDecodeError):
                    pass
                if time.monotonic() >= deadline:
                    log.seek(0)
                    raise AssertionError(log.read())
                time.sleep(0.05)
            assert not status['visible']
            assert status['font'] == 'JetBrainsMono Nerd Font'
            assert status['folder'] == '' and status['iconSource'] == '' and status['icon'] == '󰒓'
            assert not status['separateWallpapers']
            assert status['lockScreen'] == {'background': 'theme', 'color': '#191724', 'image': ''}
            ipc('settings', 'open')
            assert json.loads(ipc('test', 'status'))['visible']
            ipc('settings', 'open')  # Reuses the same window.
            assert ipc('test', 'monitoring') == 'true'
            assert ipc('test', 'monitoringPanels') == '1'
            ipc('test', 'hideAll')
            assert json.loads(ipc('test', 'status'))['disabled'] == 19
            ipc('settings', 'close')
            assert not json.loads(ipc('test', 'status'))['visible']
            assert ipc('test', 'monitoringPanels') == '0'
            ipc('settings', 'open')
            assert json.loads(ipc('test', 'status'))['visible']
            ipc('settings', 'toggle')
            assert not json.loads(ipc('test', 'status'))['opened']
            ipc('test', 'preferences')
            time.sleep(.4)
            preferences = json.loads(ipc('test', 'status'))
            assert not preferences['error'], preferences
            assert preferences['font'] == 'DejaVu Sans'
            assert preferences['lockScreen']['background'] == 'color'
            assert preferences['lockScreen']['color'] == '#123abc'
            process.terminate()
            process.wait(timeout=5)
            process = subprocess.Popen(['quickshell', '--path', str(target)], env=env,
                                       stdout=log, stderr=subprocess.STDOUT)
            deadline = time.monotonic() + 8
            while True:
                try:
                    restored = json.loads(ipc('test', 'status'))
                    if restored['ready']:
                        break
                except (RuntimeError, json.JSONDecodeError):
                    pass
                if time.monotonic() >= deadline: raise AssertionError('Settings restart timed out')
                time.sleep(.05)
            assert not restored['error'], restored
            for key in ['font', 'folder', 'icon', 'iconSource', 'separateWallpapers', 'wallpapers', 'lightWallpapers', 'darkWallpapers', 'lockScreen']:
                assert restored[key] == preferences[key], (key, restored, preferences)
            assert ipc('test', 'checkWallpaperModes') == 'true'
            print('PASS: shared/light/dark wallpapers persist, clear independently, and follow theme changes', flush=True)
            print('PASS: wallpaper folder and custom settings icon survive restart', flush=True)
            log.flush()
            log.seek(0)
            output = log.read()
            for error in ['ReferenceError', 'TypeError', 'Binding loop', 'Failed to load configuration']:
                assert error not in output, output
            print('PASS: settings window reuse, close, toggle, and recovery with all widgets hidden', flush=True)
        finally:
            process.terminate()
            process.wait(timeout=5)
