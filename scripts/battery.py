#!/usr/bin/env python3
"""Discover system batteries and apply driver charge thresholds."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path('/sys/class/power_supply')


def read(path):
    try:
        return path.read_text().strip()
    except OSError:
        return ''


def number(path):
    try:
        return int(read(path))
    except ValueError:
        return None


def batteries(root=ROOT):
    result = []
    for path in sorted(root.glob('*')):
        if read(path/'type') != 'Battery' or read(path/'scope') == 'Device' or read(path/'present') == '0':
            continue
        # Scope is absent on many ACPI laptop batteries. Require a standard
        # battery name or energy/charge data before treating those as system power.
        if read(path/'scope') != 'System' and not (re.fullmatch(r'BAT\w*', path.name) or (path/'energy_full').exists() or (path/'charge_full').exists()):
            continue
        full = design = now = None
        unit = ''
        for kind in ['energy', 'charge']:
            full = number(path/f'{kind}_full')
            design = number(path/f'{kind}_full_design')
            now = number(path/f'{kind}_now')
            if full and full > 0:
                unit = 'Wh' if kind == 'energy' else 'Ah'
                break
        capacity = number(path/'capacity')
        if capacity is None and full and now is not None:
            capacity = round(100 * now / full)
        end = number(path/'charge_control_end_threshold')
        start = number(path/'charge_control_start_threshold')
        result.append(dict(id=path.name, model=read(path/'model_name') or path.name,
                           manufacturer=read(path/'manufacturer'), status=read(path/'status') or 'Unknown',
                           percent=max(0, min(100, capacity)) if capacity is not None else None,
                           health=round(100 * full / design, 1) if full and design and design > 0 else None,
                           full=full / 1e6 if full else None, design=design / 1e6 if design else None,
                           unit=unit, cycles=number(path/'cycle_count'), limit=end, start=start,
                           limitSupported=end is not None and (path/'charge_control_end_threshold').exists()))
    return result


def write_threshold(path, value):
    try:
        path.write_text(f'{value}\n')
    except PermissionError:
        if not shutil.which('pkexec'):
            raise RuntimeError('Install polkit and run a polkit authentication agent to change the charge limit.')
        # Only tee needs elevated privileges, not this user-editable Python file.
        result = subprocess.run(['pkexec', '/usr/bin/tee', str(path)], input=f'{value}\n',
                                capture_output=True, text=True, timeout=120)
        if result.returncode:
            raise RuntimeError('Charge limit authorization was cancelled or the driver rejected the value. ' + result.stderr.strip()[-240:])
    actual = number(path)
    if actual is None:
        raise RuntimeError('Could not read back the charge threshold.')
    return actual


def set_limit(name, limit, root=ROOT, writer=write_threshold):
    if not re.fullmatch(r'[A-Za-z0-9_-]+', name) or not isinstance(limit, int) or not 50 <= limit <= 100:
        raise ValueError('Choose a battery and a charge limit from 50% to 100%.')
    battery = next((entry for entry in batteries(root) if entry['id'] == name), None)
    if not battery or not battery['limitSupported']:
        raise RuntimeError('This battery does not expose a hardware charge limit.')
    path = root/name
    # Keep a valid start/end pair on drivers (e.g. ThinkPad) that expose both.
    old_start = battery['start']
    lowered = old_start is not None and old_start >= limit
    if lowered:
        actual_start = writer(path/'charge_control_start_threshold', max(0, limit - 5))
        if actual_start >= limit:
            writer(path/'charge_control_start_threshold', old_start)
            raise RuntimeError('The driver cannot set a start threshold below this limit.')
    try:
        actual = writer(path/'charge_control_end_threshold', limit)
    except Exception:
        if lowered:
            try:
                writer(path/'charge_control_start_threshold', old_start)
            except Exception as rollback:
                raise RuntimeError(f'Limit failed and the previous start threshold could not be restored: {rollback}')
        raise
    return actual


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', nargs='?', choices=['status', 'set'], default='status')
    parser.add_argument('battery', nargs='?')
    parser.add_argument('limit', nargs='?', type=int)
    args = parser.parse_args()
    error = message = ''
    try:
        if args.action == 'set':
            actual = set_limit(args.battery or '', args.limit)
            message = f'Charge limit applied: {actual}%.'
            if actual != args.limit:
                message += ' The driver rounded to a supported value.'
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as exc:
        error = str(exc)
    print(json.dumps(dict(batteries=batteries(), error=error, message=message)))


if __name__ == '__main__':
    main()
