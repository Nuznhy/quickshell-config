#!/usr/bin/env python3
"""Hyprlock's persistent Caps Lock label. Never reads keypresses or passwords."""
import json
import subprocess


def caps_status(devices):
    keyboards = devices.get('keyboards', [])
    keyboard = next((kb for kb in keyboards if kb.get('main')), None)
    if keyboard is None or not isinstance(keyboard.get('capsLock'), bool):
        return 'Caps Lock: unknown'
    return '<b>Caps Lock: ON</b>' if keyboard['capsLock'] else 'Caps Lock: off'


def main():
    try:
        result = subprocess.run(['hyprctl', 'devices', '-j'], capture_output=True,
                                text=True, timeout=1, check=True)
        print(caps_status(json.loads(result.stdout)))
    except (OSError, ValueError, TypeError, AttributeError, subprocess.SubprocessError):
        print('Caps Lock: unknown')


if __name__ == '__main__':
    main()
