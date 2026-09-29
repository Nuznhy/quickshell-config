#!/usr/bin/env python3
"""Route session locking through Hypridle/Hyprlock and power actions through logind."""
import os
import shutil
import subprocess
import sys


def run(args, timeout=15):
    result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError((result.stderr or result.stdout).strip() or 'Command failed.')
    return result.stdout.strip()


def lock():
    for executable in ('hyprlock', 'hypridle', 'pgrep', 'loginctl'):
        if not shutil.which(executable):
            raise RuntimeError(f'{executable} is required for session locking. See DEPENDENCIES.md.')
    # loginctl only emits a signal; require the configured listener before
    # reporting success or requesting sleep. Hypridle owns lock_cmd and the
    # inhibit_sleep=3 delay until Hyprland confirms the session is locked.
    try:
        run(['pgrep', '-u', str(os.getuid()), '-x', 'hypridle'])
    except RuntimeError as error:
        raise RuntimeError('Hypridle is not running. Start hypridle in your Hyprland session and retry.') from error
    run(['loginctl', 'lock-session'])


def perform(action):
    if action in ('lock', 'sleep'):
        lock()
        if action == 'sleep':
            run(['systemctl', 'suspend'], timeout=120)
    elif action in ('reboot', 'shutdown'):
        run(['systemctl', 'reboot' if action == 'reboot' else 'poweroff'], timeout=120)
    else:
        raise ValueError('Unknown power action.')


if __name__ == '__main__':
    try:
        perform(sys.argv[1] if len(sys.argv) == 2 else '')
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
