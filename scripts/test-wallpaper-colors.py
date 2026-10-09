#!/usr/bin/env python3
"""Isolated wallpaper generation, real QML service, UI and persistence checks."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parent.parent
subprocess.run(['python3', '-m', 'unittest', 'discover', '-s', str(ROOT / 'tests/wallpaper_colors'), '-v'], check=True)
with tempfile.TemporaryDirectory(prefix='qs-wallpaper-colors-') as directory:
    base = Path(directory)
    for name in ('config', 'components', 'services', 'scripts'):
        shutil.copytree(ROOT / name, base / name)
    (base / 'runtime').mkdir(mode=0o700)
    # Mock screen topology only; use production Theme persistence and service.
    path = base / 'config/Theme.qml'
    path.write_text(path.read_text().replace('readonly property var connectedScreens: Quickshell.screens',
                                           'property var connectedScreens: [{name: "TEST"}]'))
    for name, color in [('blue', '#1478cf'), ('red', '#cf1838'), ('slow', '#18ab48')]:
        (base / (name + '.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><rect width="32" height="32" fill="{color}"/></svg>')
    original = (base / 'scripts/wallpaper-palette.py').read_text()
    (base / 'scripts/wallpaper-palette.py').write_text(original.replace("    method, variant =", "    import time\n    if 'slow.svg' in request.get('source', ''): time.sleep(1)\n    method, variant ="))
    (base / 'shell.qml').write_text('''import QtQuick
import Quickshell
import Quickshell.Io
import "config"
import "services"
import "components"
ShellRoot {
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 760; implicitHeight: 720
        color: Theme.bg
        WallpaperThemeSettings { id: controls; x: 20; y: 20; width: parent.width - 40 }
    }
    IpcHandler {
        target: "test"
        function status(): string {
            return JSON.stringify({ready: Theme.ready, busy: WallpaperTheme.busy,
                error: WallpaperTheme.errorMessage, preview: WallpaperTheme.preview,
                palette: Theme.generatedPalette, preset: Theme.preset,
                mode: Theme.mode,
                method: Theme.wallpaperColorMethod, variant: Theme.wallpaperColorVariant,
                auto: Theme.wallpaperColorAuto, monitor: Theme.wallpaperColorMonitor});
        }
        function wallpaper(name: string): void { Theme.setWallpaper("TEST", Qt.resolvedUrl(name + ".svg").toString()); }
        function monitor(value: string): void { WallpaperTheme.setOption("monitor", value); }
        function autoUpdate(value: bool): void { WallpaperTheme.setOption("auto", value); }
        function method(value: string): void { WallpaperTheme.setOption("method", value); }
        function variant(value: string): void { WallpaperTheme.setOption("variant", value); }
        function preset(value: string): void { Theme.selectPreset(value); }
        function separate(): void {
            Theme.setWallpaper("TEST", Qt.resolvedUrl("blue.svg").toString(), "dark");
            Theme.setWallpaper("TEST", Qt.resolvedUrl("red.svg").toString(), "light");
            Theme.setSeparateWallpapers(true);
        }
        function mode(value: string): void { Theme.selectMode(value); }
        function disconnect(): void { Theme.connectedScreens = []; }
        function reconnect(): void { Theme.connectedScreens = [{name: "TEST"}]; }
        function screenshot(narrow: bool): void {
            controls.width = narrow ? 320 : 720;
            shot.restart();
        }
    }
    Timer {
        id: shot; interval: 200
        onTriggered: controls.grabToImage(result => result.saveToFile(controls.width < 400 ? "/tmp/qs-wallpaper-colors-narrow.png" : "/tmp/qs-wallpaper-colors-wide.png"))
    }
}
''')
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
               XDG_RUNTIME_DIR=str(base / 'runtime'), XDG_STATE_HOME=str(base / 'state'), XDG_CACHE_HOME=str(base / 'cache'))
    with (base / 'log').open('w+') as log:
        def start():
            return subprocess.Popen(['quickshell', '--path', str(base)], env=env, stdout=log, stderr=subprocess.STDOUT)
        def ipc(action, *args):
            result = subprocess.run(['quickshell', 'ipc', '--path', str(base), 'call', 'test', action, *map(str, args)],
                                    env=env, capture_output=True, text=True, timeout=5)
            if result.returncode:
                raise RuntimeError(result.stderr + result.stdout)
            return result.stdout.strip()
        def wait_for(predicate):
            deadline = time.monotonic() + 10
            while time.monotonic() < deadline:
                try:
                    current = json.loads(ipc('status'))
                    if current['ready'] and predicate(current):
                        return current
                except (RuntimeError, json.JSONDecodeError):
                    pass
                time.sleep(.06)
            log.flush(); log.seek(0)
            raise AssertionError(log.read())
        def settled():
            return wait_for(lambda s: not s['busy'])
        process = start()
        try:
            initial = wait_for(lambda s: s['ready'])
            assert initial['preset'] == 'rose-pine' and not initial['auto']
            ipc('wallpaper', 'blue'); ipc('monitor', 'TEST')
            blue = wait_for(lambda s: not s['busy'] and bool(s['palette']))
            assert blue['preset'] == 'wallpaper' and blue['palette'] == blue['preview']
            ipc('wallpaper', 'red')
            unchanged = settled()
            assert unchanged['palette'] == blue['palette']
            ipc('method', 'average')
            red = wait_for(lambda s: not s['busy'] and s['palette'] != blue['palette'])
            assert red['palette'] == red['preview']
            ipc('autoUpdate', 'true'); settled()
            ipc('wallpaper', 'slow'); time.sleep(.5); ipc('wallpaper', 'blue')
            blue = wait_for(lambda s: not s['busy'] and s['palette'] != red['palette'])
            ipc('wallpaper', 'slow'); time.sleep(.5); ipc('autoUpdate', 'false')
            stopped = settled()
            assert stopped['palette'] == blue['palette']
            ipc('wallpaper', 'blue'); ipc('autoUpdate', 'true'); settled()
            ipc('wallpaper', 'slow'); time.sleep(.5); ipc('preset', 'gruvbox')
            suspended = settled()
            assert suspended['preset'] == 'gruvbox' and suspended['palette'] == blue['palette']
            ipc('wallpaper', 'red')
            assert settled()['preset'] == 'gruvbox'
            # Explicit setting edits activate wallpaper colors even from a built-in preset.
            ipc('variant', 'vivid')
            vivid = wait_for(lambda s: not s['busy'] and s['preset'] == 'wallpaper')
            assert vivid['palette'] != red['palette']
            ipc('wallpaper', 'missing')
            failure = wait_for(lambda s: not s['busy'] and bool(s['error']))
            assert failure['palette'] == vivid['palette']
            ipc('disconnect'); lost = wait_for(lambda s: not s['busy'] and 'Connect' in s['error'])
            assert lost['monitor'] == 'TEST' and lost['palette'] == vivid['palette']
            ipc('reconnect'); ipc('separate'); ipc('mode', 'dark')
            dark = wait_for(lambda s: not s['busy'] and not s['error'])
            ipc('mode', 'light')
            light = wait_for(lambda s: not s['busy'] and s['palette'] != dark['palette'])
            ipc('autoUpdate', 'false'); ipc('mode', 'dark')
            assert settled()['palette'] == light['palette']
            # A settings edit still regenerates/applies with follow-wallpaper disabled.
            ipc('method', 'dominant')
            changed = wait_for(lambda s: not s['busy'] and s['palette'] != light['palette'])
            ipc('method', 'average')
            saved_palette = wait_for(lambda s: not s['busy'] and s['palette'] != changed['palette'])['palette']
            ipc('screenshot', 'false'); time.sleep(.4)
            ipc('screenshot', 'true'); time.sleep(.4)
            assert Path('/tmp/qs-wallpaper-colors-narrow.png').exists()
            process.terminate(); process.wait(timeout=5)
            process = start()
            restored = settled()
            assert restored['palette'] == saved_palette and restored['preset'] == 'wallpaper'
            assert restored['method'] == 'average' and restored['variant'] == 'vivid' and not restored['auto']
            process.terminate(); process.wait(timeout=5)
            state, = (base / 'state').rglob('theme.json')
            saved = json.loads(state.read_text())
            saved['wallpaperColors']['palettes'] = {'dark': {'bg': 'invalid'}}
            state.write_text(json.dumps(saved))
            process = start()
            fallback = settled()
            assert fallback['preset'] == 'rose-pine' and fallback['palette'] is None
            print('PASS: automatic settings application, wallpaper following, cancellation, presets, failures, UI, and persistence')
            log.flush(); log.seek(0)
            output = log.read()
            if any(word in output for word in ('ReferenceError', 'TypeError', 'Binding loop', 'Failed to load configuration')):
                raise AssertionError(output)
        finally:
            process.terminate(); process.wait(timeout=5)
