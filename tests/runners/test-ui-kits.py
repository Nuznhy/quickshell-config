#!/usr/bin/env python3
"""Test the real kit picker and Theme persistence without desktop state or IPC."""
from pathlib import Path
from design_test_support import prepare_script_dirs
import json
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='qs-kits-test-') as directory:
    base = Path(directory)
    prepare_script_dirs(base)
    for name in ['config', 'kits']:
        shutil.copytree(ROOT / name, base / name)
    shutil.copytree(ROOT / 'components/ui', base / 'components/ui')
    (base / 'modules/appearance').mkdir(parents=True)
    shutil.copyfile(ROOT / 'modules/appearance/UiKitPicker.qml', base / 'modules/appearance/UiKitPicker.qml')
    (base / 'runtime').mkdir(mode=0o700)
    state = base / 'theme.json'
    theme = base / 'config/Theme.qml'
    theme.write_text(theme.read_text().replace('Quickshell.statePath("theme.json")', json.dumps(str(state))))
    (base / 'shell.qml').write_text('''import QtQuick
import Quickshell
import qs.config
import qs.modules.appearance
import qs.components.ui as UI

ShellRoot {
    property bool started: false
    property int ticks: 0
    property int settled: 0
    function find(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const found = find(child, name);
            if (found) return found;
        }
        return null;
    }
    FloatingWindow {
        visible: true
        implicitWidth: 480; implicitHeight: 300
        UiKitPicker { id: picker; width: 300 }
        UI.Button { id: first; y: 120; text: "First monitor" }
        UI.Button { id: second; y: 180; text: "Second monitor" }
    }
    Timer {
        interval: 50; repeat: true; running: true
        onTriggered: {
            if (++ticks > 100) { console.log("KIT_TEST_TIMEOUT"); Qt.quit(); return; }
            if (!Theme.ready) return;
            if (!started) {
                started = true;
                const choice = Quickshell.env("KIT_TEST_SELECT");
                if (choice) {
                    const selector = find(picker, "ui-kit-selector");
                    selector.currentIndex = UiKit.kits.findIndex(kit => kit.id === choice);
                    selector.activated(selector.currentIndex);
                }
                // An invalid request must not replace the accepted kit.
                Theme.selectUiKit("missing");
                const palette = Quickshell.env("KIT_TEST_PALETTE");
                if (palette) Theme.selectPreset(palette);
            }
            if (++settled < 8) return;
            console.log("KIT_TEST_RESULT " + JSON.stringify({
                id: Theme.uiKit, active: UiKit.activeId, radius: Design.radiusControl,
                firstRadius: first.background.radius, secondRadius: second.background.radius,
                selector: find(picker, "ui-kit-selector").currentValue,
                preset: Theme.preset, mode: Theme.mode, font: Theme.barFontFamily,
                uiFont: Design.fontFamily,
                presets: Theme.presets.map(p => p.id), palette: Theme.palette,
                swatches: Theme.preview(Theme.preset),
                position: Theme.barPosition, opacity: Theme.barOpacity,
                margin: Theme.barTopMargin, barRadius: Theme.barRadius,
                widgetStyle: Theme.widgetStyle, error: Theme.errorMessage
            }));
            Qt.quit();
        }
    }
}
''')
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
               XDG_RUNTIME_DIR=str(base / 'runtime'), XDG_STATE_HOME=str(base / 'state'),
               XDG_CACHE_HOME=str(base / 'cache'))
    env.pop('WAYLAND_DISPLAY', None)

    def run(expected, choice='', palette=''):
        result = subprocess.run(['quickshell', '--path', str(base), '--no-color'],
                                env=dict(env, KIT_TEST_SELECT=choice, KIT_TEST_PALETTE=palette), capture_output=True,
                                text=True, timeout=12)
        output = result.stdout + result.stderr
        assert result.returncode == 0, output
        for error in ['ReferenceError', 'TypeError', 'Binding loop', 'Failed to load configuration',
                      'invalid characters', 'KIT_TEST_TIMEOUT']:
            assert error not in output, output
        lines = [line.split('KIT_TEST_RESULT ', 1)[1] for line in output.splitlines()
                 if 'KIT_TEST_RESULT ' in line]
        assert len(lines) == 1, output
        snapshot = json.loads(lines[0])
        assert snapshot['id'] == snapshot['active'] == snapshot['selector'] == expected, snapshot
        assert snapshot['firstRadius'] == snapshot['secondRadius'] == snapshot['radius'], snapshot
        assert snapshot['radius'] == dict(default=8, minimal=2, rounded=16, windows7=3, windowsxp=3)[expected], snapshot
        if expected == 'windows7':
            assert snapshot['uiFont'] in ['Segoe UI', 'sans-serif'], snapshot
        elif expected == 'windowsxp':
            assert snapshot['uiFont'] in ['Tahoma', 'DejaVu Sans', 'sans-serif'], snapshot
        else:
            assert snapshot['uiFont'] == 'JetBrainsMono Nerd Font', snapshot
        return snapshot

    assert not run('default')['error']
    assert not state.exists(), 'Loading defaults should not create preferences'
    legacy = dict(preset='catppuccin', mode='light', barFontFamily='DejaVu Sans',
                  barPosition='left', barOpacity=0.8, barTopMargin=9, barRadius=11,
                  widgetStyle=dict(lines='off', background='instant', duration=420, strength=23))
    state.write_text(json.dumps(legacy))
    previous = run('default')
    assert 'uiKit' not in json.loads(state.read_text())
    keys = ['preset', 'mode', 'font', 'position', 'opacity', 'margin', 'barRadius', 'widgetStyle']
    for kit in ['minimal', 'rounded', 'windows7', 'windowsxp', 'default']:
        changed = run(kit, kit)
        assert not changed['error'], changed
        assert json.loads(state.read_text())['uiKit'] == kit
        restored = run(kit)
        for key in keys:
            assert changed[key] == restored[key] == previous[key], (key, changed, restored, previous)
        assert ('windows7-aero' in restored['presets']) == (kit == 'windows7'), restored
        assert ('windowsxp-luna' in restored['presets']) == (kit == 'windowsxp'), restored
    native = run('windows7', 'windows7', 'windows7-aero')
    assert native['preset'] == 'windows7-aero', native
    assert native['palette']['bg'] == '#dedede' and native['palette']['iris'] == '#3399ff', native
    assert native['swatches'] == native['palette'], native
    assert run('windows7')['palette'] == native['palette']
    retained = run('default', 'default')
    assert retained['preset'] == 'windows7-aero' and 'windows7-aero' in retained['presets'], retained
    assert retained['palette'] == native['palette'], retained
    assert 'windows7-aero' not in run('default', palette='catppuccin')['presets']
    native = run('windowsxp', 'windowsxp', 'windowsxp-luna')
    assert native['preset'] == 'windowsxp-luna', native
    assert native['palette']['bg'] == '#ece9d8' and native['palette']['iris'] == '#245edb', native
    assert native['swatches'] == native['palette'], native
    assert run('windowsxp')['palette'] == native['palette']
    retained = run('default', 'default')
    assert retained['preset'] == 'windowsxp-luna' and 'windowsxp-luna' in retained['presets'], retained
    assert retained['palette'] == native['palette'], retained
    assert 'windowsxp-luna' not in run('default', palette='catppuccin')['presets']
    for invalid in ['removed-kit', None, 42, {}]:
        state.write_text(json.dumps(dict(legacy, uiKit=invalid)))
        assert not run('default')['error']
    state.write_text('{invalid json')
    assert run('default')['error']
    state.unlink()
    state.mkdir()
    failed = run('minimal', 'minimal')
    assert 'could not save' in failed['error'].lower(), failed
    print('PASS: kit picker, live shared visuals, defaults, legacy/invalid state, restart persistence, and save errors')
