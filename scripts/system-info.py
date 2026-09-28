#!/usr/bin/env python3
"""Read system details; repository update checks use a separate pacman database."""
import argparse
import json
import os
from pathlib import Path
import platform
import re
import shlex
import shutil
import struct
import subprocess


def gib(value):
    return f'{value / 1024**3:.1f} GiB'


def memory(proc=Path('/proc/meminfo'), dmi=Path('/sys/firmware/dmi/entries')):
    try:
        usable = next(int(line.split()[1]) * 1024 for line in proc.read_text().splitlines() if line.startswith('MemTotal:'))
    except (OSError, ValueError, StopIteration):
        return 'Unavailable'
    installed = 0
    # udev caches SMBIOS memory sizes at boot, making installed capacity
    # readable without granting access to the raw firmware tables.
    if shutil.which('udevadm'):
        try:
            result = subprocess.run(['udevadm', 'info', '--query=property', '--path=/sys/devices/virtual/dmi/id'],
                                    capture_output=True, text=True, timeout=3)
            if result.returncode == 0:
                installed = sum(int(size) for size in re.findall(r'^MEMORY_DEVICE_\d+_SIZE=(\d+)$', result.stdout, re.MULTILINE))
        except (OSError, subprocess.SubprocessError):
            pass
    if installed:
        return f'{gib(installed)} installed · {gib(usable)} usable'
    try:
        for entry in dmi.glob('17-*/raw'):
            raw = entry.read_bytes()
            size = struct.unpack_from('<H', raw, 12)[0]
            if size == 0xffff:
                installed = 0
                break
            if size == 0x7fff:
                size = (struct.unpack_from('<I', raw, 28)[0] & 0x7fffffff) * 1024**2
            else:
                size = (size & 0x7fff) * (1024 if size & 0x8000 else 1024**2)
            installed += size
    except (OSError, struct.error):
        installed = 0
    return f'{gib(installed)} installed · {gib(usable)} usable' if installed else f'{gib(usable)} usable'


def snapshot():
    try:
        os_name = platform.freedesktop_os_release().get('PRETTY_NAME', 'Linux')
    except OSError:
        os_name = 'Linux'
    cpu = 'Unavailable'
    try:
        for line in Path('/proc/cpuinfo').read_text().splitlines():
            if line.split(':', 1)[0].strip() in ('model name', 'Hardware'):
                cpu = line.split(':', 1)[1].strip()
                break
    except OSError:
        pass
    gpus = []
    if shutil.which('lspci'):
        try:
            result = subprocess.run(['lspci', '-mm'], capture_output=True, text=True, timeout=5,
                                    env=dict(os.environ, LC_ALL='C'))
            for line in result.stdout.splitlines():
                fields = shlex.split(line)
                if len(fields) >= 4 and fields[1] in ('VGA compatible controller', '3D controller', 'Display controller'):
                    gpus.append(' '.join(fields[2:4]))
        except (OSError, ValueError, subprocess.SubprocessError):
            pass
    try:
        disk = shutil.disk_usage(Path.home())
        storage = f'{gib(disk.free)} free / {gib(disk.total)} total'
    except OSError:
        storage = 'Unavailable'
    return dict(os=os_name, kernel=platform.release(), cpu=cpu,
                gpu='\n'.join(gpus) or ('Unavailable' if shutil.which('lspci') else 'Install pciutils'),
                ram=memory(), disk=storage)


def updates(runner=subprocess.run):
    if not shutil.which('checkupdates'):
        return dict(count=None, error='Install pacman-contrib to check repository updates.')
    result = runner(['checkupdates', '--nocolor'], capture_output=True, text=True, timeout=90,
                    env=dict(os.environ, LC_ALL='C'))
    if result.returncode == 2:
        return dict(count=0, error='')
    if result.returncode != 0:
        return dict(count=None, error='Update check failed. Check connectivity and mirrors.')
    return dict(count=len([line for line in result.stdout.splitlines() if line.strip()]), error='')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', nargs='?', choices=['info', 'updates'], default='info')
    args = parser.parse_args()
    try:
        data = updates() if args.action == 'updates' else snapshot()
    except (OSError, subprocess.SubprocessError) as exc:
        data = dict(count=None, error=f'Update check unavailable: {exc}')
    print(json.dumps(data))


if __name__ == '__main__':
    main()
