#!/usr/bin/env python3
"""Check tmux palette updates on isolated servers, never the desktop server."""
import importlib.util
import os
from pathlib import Path
import re
import json
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'scripts'))
import app_theme_formats as fmt
spec = importlib.util.spec_from_file_location('app_themes', ROOT / 'scripts/app-themes.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

with tempfile.TemporaryDirectory(prefix='qs-tmux-test-') as directory:
    base = Path(directory)
    config = base / 'config'
    (config / 'tmux').mkdir(parents=True)
    shutil.copyfile(ROOT / 'integrations/tmux/theme.conf', config / 'tmux/theme.conf')
    env = dict(os.environ, HOME=str(base), XDG_CONFIG_HOME=str(config), TMUX_TMPDIR=str(base))
    env.pop('TMUX', None)
    sockets = [base / 'themed.sock', base / 'unrelated.sock', base / 'new.sock']
    def run(args):
        result = subprocess.run(args, env=env, text=True, capture_output=True, timeout=10)
        if result.returncode: raise RuntimeError(result.stderr or result.stdout)
        return result.stdout.strip()
    def tmux(socket, *args):
        return run(['tmux', '-S', str(socket), *args])
    def start(socket):
        tmux(socket, '-f', '/dev/null', 'new-session', '-d', '-s', 'theme-test', '/bin/sleep 120')
    engine = module.Themes(base / 'state', base, config, base / 'data', run, shutil.which)
    engine.tmux_sockets = lambda: [p for p in sockets if p.exists()]
    palettes = [dict(zip(fmt.ROLES, json.loads(colors))) for colors in re.findall(
        r'(?:dark|light):\s*(\[[^\]]+\])', (ROOT / 'config/Palettes.js').read_text())]
    def apply(enabled=True, palette=None, action='set'):
        response = engine.handle(dict(action=action, target='tmux', enabled=enabled,
                                      palette=palette or palettes[0], mode='dark'))
        state = next(t for t in response['targets'] if t['id'] == 'tmux')
        assert state['state'] != 'error', state
    try:
        start(sockets[0]); start(sockets[1])
        tmux(sockets[0], 'source-file', str(config / 'tmux/theme.conf'))
        tmux(sockets[0], 'set-option', '-g', 'status-position', 'top')
        tmux(sockets[0], 'set-option', '-g', 'status', '2')
        original = tmux(sockets[0], 'display-message', '-p', '#{E:status-style}')
        assert original == 'bg=#191724,fg=#e0def4', original
        for palette in palettes:
            apply(palette=palette)
            actual = tmux(sockets[0], 'display-message', '-p', '#{E:status-style}')
            assert actual == f'bg={palette["bg"]},fg={palette["text"]}', actual
            current = tmux(sockets[0], 'display-message', '-p', '#{E:window-status-current-format}')
            assert palette['iris'] in current and fmt.on_color(palette['iris']) in current, current
            assert '' in current and '' in current
            assert tmux(sockets[0], 'show-options', '-gv', 'status-position') == 'top'
            assert tmux(sockets[0], 'show-options', '-gv', 'status') == '2'
            assert tmux(sockets[1], 'show-options', '-gqv', '@quickshell_bg') == ''
        print('PASS: all 12 palettes, contrast, status layout and unrelated-server isolation', flush=True)
        start(sockets[2])
        tmux(sockets[2], 'source-file', str(config / 'tmux/theme.conf'))
        assert tmux(sockets[2], 'show-options', '-gqv', '@quickshell_bg') == palettes[-1]['bg']
        apply(False)
        for socket in [sockets[0], sockets[2]]:
            assert tmux(socket, 'display-message', '-p', '#{E:status-style}') == original
            assert tmux(socket, 'show-options', '-gqv', '@quickshell_bg') == ''
        assert not (config / 'tmux/quickshell-config.conf').exists()
        print('PASS: newly started servers load the palette; disabling restores Rosé Pine live', flush=True)
        for socket in sockets:
            tmux(socket, 'kill-server')
        apply()
        assert (config / 'tmux/quickshell-config.conf').exists()
        apply(False)
        print('PASS: enabling and restoring without a running server', flush=True)
    finally:
        for socket in sockets:
            subprocess.run(['tmux', '-S', str(socket), 'kill-server'], env=env, capture_output=True)
