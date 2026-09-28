#!/usr/bin/env python3
"""Launch btop in the user's terminal without evaluating shell config."""
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess


def terminal_command(env=None, home=None, which=shutil.which):
    env = os.environ if env is None else env
    home = Path.home() if home is None else Path(home)
    if not which('btop'):
        raise RuntimeError('Install btop to open the process monitor.')
    if which('xdg-terminal-exec'):
        return ['xdg-terminal-exec', 'btop']
    candidates = [env.get('TERMINAL', '')]
    config = Path(env.get('XDG_CONFIG_HOME') or home / '.config')
    for path in [config / 'hypr/config/vars.lua', config / 'hypr/hyprland.conf']:
        try:
            content = path.read_text()
        except OSError:
            continue
        pattern = r'(?m)^\s*terminal\s*=\s*[\"\x27]([^\"\x27]+)[\"\x27]' if path.suffix == '.lua' else r'(?m)^\s*\$terminal\s*=\s*([^\n#]+)'
        match = re.search(pattern, content)
        if match:
            candidates.append(match.group(1))
    candidates.extend(['ghostty', 'foot', 'kitty', 'alacritty', 'konsole', 'gnome-terminal', 'xterm'])
    for candidate in candidates:
        try:
            command = shlex.split(candidate)
        except ValueError:
            continue
        if not command or not which(command[0]):
            continue
        name = Path(command[0]).name
        separators = {'ghostty': '-e', 'foot': '--', 'footclient': '--', 'kitty': '--',
                      'alacritty': '-e', 'konsole': '-e', 'gnome-terminal': '--',
                      'xterm': '-e', 'wezterm': 'start', 'xfce4-terminal': '-x'}
        if name in separators:
            return command + [separators[name], 'btop']
    raise RuntimeError('No supported terminal found. Configure xdg-terminal-exec or $TERMINAL.')


def main():
    try:
        subprocess.Popen(terminal_command(), stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                         stderr=subprocess.DEVNULL, start_new_session=True)
        print(json.dumps({'error': ''}))
    except (OSError, RuntimeError) as error:
        print(json.dumps({'error': str(error)}))


if __name__ == '__main__':
    main()
