#!/usr/bin/env python3
"""Isolated generators, recovery, controls, and real QML worker tests."""
from pathlib import Path
from design_test_support import install_design
import struct
import zlib
import json
import os
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parent.parent
subprocess.run(['python3', '-m', 'unittest', 'discover', '-s', str(ROOT / 'tests/app_themes'), '-v'], check=True)
with tempfile.TemporaryDirectory(prefix='qs-app-themes-') as directory:
    base = Path(directory)
    app = base / 'shell'
    for sub in ['components', 'config', 'services', 'scripts', 'runtime', 'bin']:
        (app / sub).mkdir(parents=True, mode=0o700)
    for name in ['ApplicationThemes.qml', 'NotificationButton.qml', 'ControlSwitch.qml', 'LockScreenSettings.qml']:
        shutil.copyfile(ROOT / 'components' / name, app / 'components' / name)
    (app / 'config/qmldir').write_text('singleton Theme 1.0 Theme.qml\n')
    (app / 'config/Theme.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
    property bool ready: true
    property string mode: "dark"
    property var palette: ({bg: "#191724", surface: "#1f1d2e", overlay: "#26233a", muted: "#6e6a86", subtle: "#908caa", text: "#e0def4", love: "#eb6f92", gold: "#f6c177", rose: "#ebbcba", pine: "#31748f", foam: "#9ccfd8", iris: "#c4a7e7", highlightLow: "#21202e", highlightMed: "#403d52", highlightHigh: "#524f67"})
    property var widgetStyle: ({lines: "animated", background: "off", duration: 300, strength: 12})
    property int barRadius: 0
    property real barOpacity: 1
    property int barTopMargin: 0
    property int barSideMargin: 0
    property bool verticalBar: false
    property string lockBackgroundMode: "theme"
    property string lockBackgroundColor: "#191724"
    property string lockBackgroundImage: ""
    property var lockScreen: ({background: lockBackgroundMode, color: lockBackgroundColor, image: lockBackgroundImage})
    function setLockBackground(kind, value) {
        if (kind === "mode") lockBackgroundMode = value;
        else if (kind === "color") lockBackgroundColor = value;
        else if (kind === "image") lockBackgroundImage = value;
    }
    readonly property color bg: palette.bg
    readonly property color text: palette.text
    readonly property color subtle: palette.subtle
    readonly property color love: palette.love
    readonly property color surface: palette.surface
    readonly property color overlay: palette.overlay
    readonly property color iris: palette.iris
    readonly property color gold: palette.gold
    readonly property color highlightMed: palette.highlightMed
    readonly property string fontFamily: "sans-serif"
}
''')
    (app / 'services/qmldir').write_text('singleton AppTheming 1.0 AppTheming.qml\n')
    (app / 'services/AppTheming.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
    property var targets: []
    property bool busy: false
    property string errorMessage: ""
    property string lastTarget: ""
    property bool lastEnabled: false
    function refresh() {}
    function isApplying(id) { return false; }
    function retry(id) {}
    function reset() {
        targets = [{id: "ghostty", name: "Ghostty", available: true, enabled: false, state: "off", message: ""},
            {id: "discord", name: "Discord", available: false, enabled: false, state: "off", message: "Requires Vencord"},
            {id: "hyprlock", name: "Hyprlock", available: true, enabled: false, state: "off", message: ""}];
    }
    function setEnabled(id, value) {
        lastTarget = id; lastEnabled = value;
        targets = targets.map(t => t.id === id ? Object.assign({}, t, {enabled: value}) : t);
    }
}
''')
    shutil.copyfile(ROOT / 'tests/app_themes/tst_controls.qml', app / 'tst_controls.qml')
    shutil.copyfile(ROOT / 'tests/app_themes/tst_lock_screen.qml', app / 'tst_lock_screen.qml')
    def png_chunk(kind, data):
        return struct.pack('!I', len(data)) + kind + data + struct.pack('!I', zlib.crc32(kind + data))
    (app / 'picture.png').write_bytes(b'\x89PNG\r\n\x1a\n'
        + png_chunk(b'IHDR', struct.pack('!2I5B', 1, 1, 8, 2, 0, 0, 0))
        + png_chunk(b'IDAT', zlib.compress(b'\x00\x40\x60\x80')) + png_chunk(b'IEND', b''))
    (app / 'broken.png').write_text('not an image')
    install_design(app)
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', XDG_RUNTIME_DIR=str(app / 'runtime'))
    subprocess.run([os.environ.get('QMLTESTRUNNER', '/usr/lib/qt6/bin/qmltestrunner'), '-input', str(app)], env=env, check=True)

    # Native service + helper, with only a fake Ghostty and a fake reload hook.
    shutil.copyfile(ROOT / 'services/AppTheming.qml', app / 'services/AppTheming.qml')
    for name in ['app-themes.py', 'app_theme_formats.py', 'hyprlock-status.py']:
        shutil.copyfile(ROOT / 'scripts' / name, app / 'scripts' / name)
    for name in ['ghostty', 'pkill', 'hyprlock', 'hyprctl']:
        path = app / 'bin' / name
        path.write_text('#!/bin/sh\nsleep 0.15\nexit 0\n')
        path.chmod(0o700)
    config = base / 'userconfig'
    (config / 'hypr').mkdir(parents=True)
    (config / 'hypr/hyprland.lua').write_text('-- user styling\n')
    (config / 'ghostty').mkdir(parents=True)
    (config / 'ghostty/config').write_text('font-size=16\ntheme=before\n')
    env.update(HOME=str(base / 'home'), XDG_CONFIG_HOME=str(config), XDG_DATA_HOME=str(base / 'data'),
               XDG_STATE_HOME=str(base / 'state'), XDG_CACHE_HOME=str(base / 'cache'),
               PATH=str(app / 'bin') + ':' + os.environ['PATH'], VENCORD_USER_DATA_DIR='')
    (app / 'shell.qml').write_text('''import QtQuick
import Quickshell
import Quickshell.Io
import "services"
import "config"
ShellRoot {
    IpcHandler {
        target: "test"
        function status(): string { return JSON.stringify({ready: AppTheming.ready, busy: AppTheming.busy, pending: AppTheming.syncPending,
            error: AppTheming.errorMessage, targets: AppTheming.targets}); }
        function enable(): void { AppTheming.setEnabled("ghostty", true); }
        function disable(): void { AppTheming.setEnabled("ghostty", false); }
        function palette(value: string): void { Theme.palette = Object.assign({}, Theme.palette, {bg: value}); }
        function accent(value: string): void { Theme.palette = Object.assign({}, Theme.palette, {iris: value}); }
        function widgetStyle(): void { Theme.widgetStyle = {lines: "off", background: "instant", duration: 400, strength: 20}; }
        function unrelated(): void { Theme.barRadius += 1; }
        function hyprEnable(): void { AppTheming.setEnabled("hyprland", true); }
        function hyprColorsEnable(): void { AppTheming.setEnabled("hyprland-colors", true); }
        function hyprColorsDisable(): void { AppTheming.setEnabled("hyprland-colors", false); }
        function hyprDisable(): void { AppTheming.setEnabled("hyprland", false); }
        function barStyle(radius: int): void { Theme.barRadius = radius; Theme.barOpacity = 0.7; Theme.barTopMargin = 10; Theme.barSideMargin = 24; }
        function vertical(): void { Theme.verticalBar = true; }
        function lockEnable(): void { AppTheming.setEnabled("hyprlock", true); }
        function lockColor(value: string): void { Theme.lockScreen = {background: "color", color: value, image: ""}; }
    }
    Component.onCompleted: AppTheming.refresh()
}
''')
    with (base / 'runtime.log').open('w+') as log:
        process = subprocess.Popen(['quickshell', '--path', str(app)], env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            def ipc(action, *args):
                result = subprocess.run(['quickshell', 'ipc', '--path', str(app), 'call', 'test', action, *args],
                                        env=env, capture_output=True, text=True, timeout=5)
                if result.returncode:
                    raise RuntimeError(result.stderr + result.stdout)
                return result.stdout.strip()

            def settled(predicate=lambda result: True):
                deadline = time.monotonic() + 10
                while time.monotonic() < deadline:
                    try:
                        result = json.loads(ipc('status'))
                        if result['error']:
                            raise AssertionError(result['error'])
                        if result['ready'] and not result['busy'] and not result['pending'] and predicate(result):
                            return result
                    except (RuntimeError, json.JSONDecodeError):
                        pass
                    time.sleep(.05)
                log.seek(0)
                raise AssertionError(log.read())

            result = settled()
            assert all(not t['enabled'] for t in result['targets'])
            assert (config / 'ghostty/config').read_text() == 'font-size=16\ntheme=before\n'
            ipc('enable')
            settled(lambda r: next(t for t in r['targets'] if t['id'] == 'ghostty')['enabled'])
            path = config / 'ghostty/themes/quickshell-config'
            assert 'background = #191724' in path.read_text()
            ipc('palette', '#112233')
            time.sleep(.3)
            ipc('palette', '#223344')
            ipc('palette', '#334455')
            settled()
            assert 'background = #334455' in path.read_text()
            modified = path.stat().st_mtime_ns
            ipc('unrelated')
            time.sleep(.4)
            settled()
            assert modified == path.stat().st_mtime_ns
            ipc('disable')
            settled(lambda r: not next(t for t in r['targets'] if t['id'] == 'ghostty')['enabled'])
            assert (config / 'ghostty/config').read_text() == 'font-size=16\ntheme=before\n'
            assert not path.exists()
            ipc('lockEnable')
            ipc('lockColor', '#445566')
            settled(lambda r: next(t for t in r['targets'] if t['id'] == 'hyprlock')['enabled'])
            lock = config / 'hypr/hyprlock.conf'
            assert 'color = rgb(445566)' in lock.read_text()
            ipc('lockColor', '#abcdef')
            ipc('lockColor', '#123456')
            settled()
            assert 'color = rgb(123456)' in lock.read_text()
            ipc('enable')
            settled(lambda r: next(t for t in r['targets'] if t['id'] == 'ghostty')['enabled'])
            modified = path.stat().st_mtime_ns
            ipc('hyprEnable')
            settled(lambda r: next(t for t in r['targets'] if t['id'] == 'hyprland')['enabled'])
            hypr = config / 'hypr/quickshell-appearance.lua'
            before_style = hypr.stat().st_mtime_ns
            ipc('widgetStyle')
            time.sleep(.4)
            settled()
            assert hypr.stat().st_mtime_ns == before_style
            assert path.stat().st_mtime_ns == modified
            ipc('barStyle', '12')
            ipc('barStyle', '18')
            time.sleep(.4)
            settled()
            content = hypr.read_text()
            assert 'rounding = 18' in content and 'active_opacity = 0.7' in content, content
            assert 'top = 10' in content and 'left = 24' in content, content
            assert path.stat().st_mtime_ns == modified
            ipc('vertical')
            time.sleep(.4)
            settled()
            content = hypr.read_text()
            assert 'top = 24' in content and 'left = 10' in content, content
            ipc('hyprDisable')
            settled(lambda r: not next(t for t in r['targets'] if t['id'] == 'hyprland')['enabled'])
            ipc('barStyle', '8')
            time.sleep(.4)
            settled()
            assert not hypr.exists()
            assert (config / 'hypr/hyprland.lua').read_text() == '-- user styling\n'
            ipc('hyprColorsEnable')
            settled(lambda r: next(t for t in r['targets'] if t['id'] == 'hyprland-colors')['enabled'])
            colors = config / 'hypr/quickshell-colors.lua'
            assert colors.exists() and not hypr.exists()
            modified = colors.stat().st_mtime_ns
            ipc('barStyle', '16')
            time.sleep(.4)
            settled()
            assert colors.stat().st_mtime_ns == modified
            ipc('accent', '#556677')
            time.sleep(.4)
            settled()
            assert 'rgb(556677)' in colors.read_text()
            assert 'shadow' not in colors.read_text()
            assert not hypr.exists()
            ipc('hyprColorsDisable')
            settled(lambda r: not next(t for t in r['targets'] if t['id'] == 'hyprland-colors')['enabled'])
            assert not colors.exists()
            assert (config / 'hypr/hyprland.lua').read_text() == '-- user styling\n'
            log.flush(); log.seek(0)
            output = log.read()
            assert not any(message in output for message in ['TypeError', 'ReferenceError', 'Binding loop']), output
            print('PASS: native worker startup, opt-in, latest palette wins, unrelated settings, and restore', flush=True)
        finally:
            process.terminate()
            process.wait(timeout=5)
