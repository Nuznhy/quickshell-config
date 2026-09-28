#!/usr/bin/env python3
"""Opt-in package-energy read access for one existing local group."""
import argparse
import grp
import os
from pathlib import Path
import subprocess

RULE = Path('/etc/udev/rules.d/80-quickshell-cpu-power.rules')
MARKER = '# Quickshell CPU package energy access\n'


def rule_text(gid):
    return (MARKER + '# Read access only; power limits and subdomain counters are untouched.\n'
            'ACTION=="add|change", SUBSYSTEM=="powercap", ATTR{name}=="package-*", '
            'TEST=="energy_uj", RUN+="/usr/bin/chgrp ' + str(gid) + ' /sys%p/energy_uj", '
            'RUN+="/usr/bin/chmod 0440 /sys%p/energy_uj"\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--group', required=True, help='Existing group allowed to read CPU package energy')
    parser.add_argument('--print-rule', action='store_true', help='Preview the rule without making changes')
    args = parser.parse_args()
    try:
        group = grp.getgrnam(args.group)
    except KeyError:
        parser.error('Group does not exist: ' + args.group)
    content = rule_text(group.gr_gid)
    if args.print_rule:
        print(content, end='')
        return
    if os.geteuid() != 0:
        parser.error('Run this opt-in setup with sudo to install the system rule.')
    if RULE.is_symlink() or (RULE.exists() and not RULE.read_text().startswith(MARKER)):
        parser.error('Refusing to replace an existing unmanaged rule: ' + str(RULE))
    RULE.parent.mkdir(parents=True, exist_ok=True)
    RULE.write_text(content)
    RULE.chmod(0o644)
    subprocess.run(['udevadm', 'control', '--reload-rules'], check=True)
    count = 0
    for package in sorted(Path('/sys/class/powercap').glob('*')):
        try:
            if not (package / 'name').read_text().strip().startswith('package-'):
                continue
            energy = package / 'energy_uj'
            if energy.is_file():
                os.chown(energy, 0, group.gr_gid)
                energy.chmod(0o440)
                count += 1
        except FileNotFoundError:
            continue
    print(f'Installed {RULE}; enabled package energy reads for group {group.gr_name} on {count} CPU package(s).')


if __name__ == '__main__':
    main()
