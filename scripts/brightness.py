#!/usr/bin/env python3
"""Discover hardware brightness controls and change one display (no configuration)."""
import concurrent.futures
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

BACKLIGHT = Path('/sys/class/backlight')


def command(args, timeout=20):
    result = subprocess.run(args, capture_output=True, text=True, timeout=timeout,
                            env=dict(os.environ, LC_ALL='C'))
    if result.returncode:
        raise RuntimeError((result.stderr or result.stdout).strip()[-500:] or 'Brightness command failed.')
    return result.stdout


def parse_displays(text):
    displays = []
    for block in re.split(r'(?m)^(?=Display \d+|Invalid display)', text):
        bus = re.search(r'I2C bus:\s*/dev/i2c-(\d+)', block)
        if not bus:
            continue
        monitor = re.search(r'Monitor:\s*(.+)', block)
        connector = re.search(r'DRM connector:\s*(.+)', block)
        displays.append(dict(id='ddc:' + bus[1], name=monitor[1].strip() if monitor else 'External monitor',
                             connection=re.sub(r'^card\d+-', '', connector[1].strip()) if connector else 'DDC/CI',
                             supported=not block.startswith('Invalid display'), value=0))
    return displays


def parse_level(text):
    match = re.search(r'(?m)^VCP 10 C\s+(\d+)\s+(\d+)', text)
    if not match or int(match[2]) <= 0:
        raise RuntimeError('This display does not expose brightness through DDC/CI.')
    return int(match[1]), int(match[2])


def ddc_level(bus):
    return parse_level(command(['ddcutil', '--bus', bus, 'getvcp', '10', '--brief']))


def read_display(display):
    if not display['supported']:
        display['error'] = 'DDC/CI unavailable. Check the monitor’s on-screen settings.'
        return display
    try:
        current, maximum = ddc_level(display['id'].split(':')[1])
        display['value'] = round(current * 100 / maximum)
    except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        display.update(supported=False, error=str(error))
    return display


def discover():
    displays, warnings = [], []
    for device in sorted(BACKLIGHT.iterdir()) if BACKLIGHT.exists() else []:
        try:
            maximum = int((device / 'max_brightness').read_text())
            if maximum <= 0:
                continue
            current = int((device / 'brightness').read_text())
            supported = bool(shutil.which('brightnessctl'))
            displays.append(dict(id='backlight:' + device.name, name='Built-in display', connection=device.name,
                                 value=round(current * 100 / maximum), supported=supported,
                                 error='' if supported else 'Install brightnessctl to adjust this screen.'))
        except (OSError, ValueError) as error:
            warnings.append(str(error))
    if not shutil.which('ddcutil'):
        warnings.append('Install ddcutil for external monitor brightness.')
    else:
        try:
            output = command(['ddcutil', 'detect', '--brief'], timeout=45)
            detected = parse_displays(output)
            if not detected and output.strip():
                warnings.append(output.strip()[-500:])
            with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
                displays.extend(pool.map(read_display, detected))
        except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
            warnings.append(str(error))
    return dict(displays=displays, error='\n'.join(warnings))


def read_levels(identifiers):
    """Read known devices without discovery or changes to their capabilities."""
    if not isinstance(identifiers, list) or any(not isinstance(item, str) for item in identifiers):
        raise ValueError('Expected a list of brightness device IDs.')

    def read_one(identifier):
        result = dict(id=identifier)
        try:
            if re.fullmatch(r'ddc:\d+', identifier):
                current, maximum = ddc_level(identifier.split(':')[1])
            elif re.fullmatch(r'backlight:[^/]+', identifier) and identifier.split(':')[1] not in ('.', '..'):
                device = BACKLIGHT / identifier.split(':')[1]
                current = int((device / 'brightness').read_text())
                maximum = int((device / 'max_brightness').read_text())
            else:
                raise ValueError('Unknown brightness device.')
            if maximum <= 0:
                raise ValueError('Invalid maximum brightness.')
            result['value'] = round(current * 100 / maximum)
        except (RuntimeError, OSError, ValueError, subprocess.TimeoutExpired) as error:
            result['error'] = str(error)
        return result

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        return dict(levels=list(pool.map(read_one, identifiers)))


def set_level(identifier, percent):
    percent = int(percent)
    if not 0 <= percent <= 100:
        raise ValueError('Brightness must be between 0 and 100%.')
    if re.fullmatch(r'ddc:\d+', identifier):
        bus = identifier.split(':')[1]
        _, maximum = ddc_level(bus)
        command(['ddcutil', '--bus', bus, 'setvcp', '10', str(round(percent * maximum / 100))])
    elif identifier.startswith('backlight:'):
        name = identifier.split(':', 1)[1]
        if not name or '/' in name or name in ('.', '..') or not (BACKLIGHT / name).is_dir():
            raise ValueError('Backlight device is no longer available.')
        # Keep the backlight lit even if its minimum percentage rounds to zero.
        maximum = int((BACKLIGHT / name / 'max_brightness').read_text())
        command(['brightnessctl', '--device', name, '--class', 'backlight', 'set', str(max(1, round(percent * maximum / 100)))])
    else:
        raise ValueError('Unknown brightness device.')


if __name__ == '__main__':
    try:
        if len(sys.argv) == 4 and sys.argv[1] == 'set':
            set_level(sys.argv[2], sys.argv[3])
            result = dict(ok=True)
        elif len(sys.argv) == 3 and sys.argv[1] == 'levels':
            result = read_levels(json.loads(sys.argv[2]))
        elif len(sys.argv) == 1:
            result = discover()
        else:
            raise ValueError('Usage: brightness.py [set DEVICE PERCENT | levels JSON_IDS]')
        print(json.dumps(result))
    except Exception as error:
        print(json.dumps(dict(error=str(error))))
        sys.exit(1)
