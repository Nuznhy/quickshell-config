#!/usr/bin/env python3
"""Suspend only after the custom session lock is confirmed secure."""
from pathlib import Path
import subprocess
import sys
import time

LOCK = str(Path(__file__).resolve().parents[1] / 'modules/lock')


def run(args, timeout=15):
    result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError((result.stderr or result.stdout).strip() or 'Command failed.')
    return result.stdout.strip()


def lock():
    run(['quickshell', '--no-duplicate', '--daemonize', '--path', LOCK])
    for _ in range(40):
        try:
            if run(['quickshell', 'ipc', '--path', LOCK, 'call', 'lock', 'status'], timeout=2) == 'secure':
                return
        except (RuntimeError, subprocess.TimeoutExpired):
            pass
        time.sleep(0.25)
    raise RuntimeError('The lock screen did not become secure. Sleep was not started.')


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
