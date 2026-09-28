#!/usr/bin/env python3
"""Small system summary and on-demand hyprsunset control; no root access."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import time


def summary():
    try:
        minutes = int(float(Path('/proc/uptime').read_text().split()[0])) // 60
        days, hours = divmod(minutes // 60, 24)
        uptime = 'Up ' + (f'{days}d ' if days else '') + f'{hours}h {minutes % 60}m'
    except (OSError, ValueError, IndexError):
        uptime = ''
    try:
        os_name = platform.freedesktop_os_release().get('PRETTY_NAME', 'Linux')
    except OSError:
        os_name = 'Linux'
    return dict(hostname=platform.node(), osName=os_name, uptime=uptime)


def ipc(*args):
    result = subprocess.run(['hyprctl', 'hyprsunset', *args], capture_output=True,
                            text=True, timeout=2)
    return result.stdout.strip() if result.returncode == 0 else ''


def night_shift(action, temperature=4000):
    if not isinstance(temperature, int) or not 1500 <= temperature <= 6500:
        raise ValueError('Night Shift temperature must be between 1500 and 6500 K.')
    if not shutil.which('hyprsunset'):
        return dict(available=False, enabled=False, error='Night Shift needs hyprsunset. Install: sudo pacman -S hyprsunset')
    if not shutil.which('hyprctl') or not os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'):
        return dict(available=False, enabled=False, error='Night Shift requires a Hyprland session.')
    runtime = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}'))
    # Serialize requests before starting a daemon, including from other bars.
    with (runtime / 'quickshell-night-shift.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        identity = ipc('identity', 'get')
        if identity not in ('true', 'false'):
            if action != 'on':
                return dict(available=True, enabled=False, error='')
            # Start neutral, then apply the requested temperature over IPC.
            # hyprsunset 0.4.0 mishandles --config's argument; use its default
            # config discovery, which also respects the user's own schedule.
            daemon = subprocess.Popen(['hyprsunset', '--identity'],
                                      stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                                      stderr=subprocess.DEVNULL, start_new_session=True)
            for _ in range(20):
                time.sleep(0.1)
                identity = ipc('identity', 'get')
                if identity in ('true', 'false'):
                    break
                if daemon.poll() is not None:
                    break
            else:
                daemon.terminate()
            if identity not in ('true', 'false'):
                return dict(available=True, enabled=False, error='Could not start Night Shift. Check hyprsunset and other screen color filters.')
        # A delayed slider write must not turn a filter back on after it was
        # disabled by another control or a scheduled profile.
        if action in ('on', 'off') or (action == 'adjust' and identity == 'false'):
            reply = ipc('identity') if action == 'off' else ipc('temperature', str(temperature))
            if reply != 'ok':
                return dict(available=True, enabled=identity == 'false', error='Could not change Night Shift.')
            identity = ipc('identity', 'get')
            if identity not in ('true', 'false'):
                return dict(available=True, enabled=False, error='Could not confirm Night Shift state.')
        return dict(available=True, enabled=identity == 'false', error='')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['status', 'on', 'off', 'adjust'], default='status', nargs='?')
    parser.add_argument('--temperature', type=int, default=4000, choices=range(1500, 6501), metavar='1500..6500')
    args = parser.parse_args()
    result = summary()
    try:
        result.update(night_shift(args.action, args.temperature))
    except (OSError, subprocess.SubprocessError) as error:
        result.update(available=True, enabled=False, error=f'Night Shift unavailable: {error}')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
