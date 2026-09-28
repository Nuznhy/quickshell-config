#!/usr/bin/env python3
"""Read-only, unprivileged PC monitoring. One JSON snapshot per line."""
import argparse
import json
import math
import re
import shutil
import subprocess
import time
from pathlib import Path


def read(path):
    try:
        return path.read_text().strip()
    except OSError:
        return ""


def number(value):
    try:
        result = float(value)
        return result if math.isfinite(result) else None
    except (TypeError, ValueError):
        return None


def metric(identifier, label, unit, value=None, maximum=None, total=None, reason="Sensor unavailable"):
    return dict(id=identifier, label=label, unit=unit, value=value, maximum=maximum,
                total=total, available=value is not None, reason="" if value is not None else reason)


class Collector:
    def __init__(self, proc=Path('/proc'), sys=Path('/sys'), runner=subprocess.run):
        self.proc, self.sys, self.runner = proc, sys, runner
        self.previous_cpu = None
        self.energy = {}

    def cpu(self):
        lines = read(self.proc / 'stat').splitlines()
        values = [number(v) for v in lines[0].split()[1:9]] if lines else []
        usage = None
        if len(values) >= 4 and all(v is not None for v in values):
            # Guest times are already included in user/nice. Include steal once.
            total, idle = sum(values), values[3] + (values[4] if len(values) > 4 else 0)
            if self.previous_cpu:
                dt, di = total - self.previous_cpu[0], idle - self.previous_cpu[1]
                if dt > 0 and di >= 0:
                    usage = max(0, min(100, 100 * (dt - di) / dt))
            self.previous_cpu = total, idle
        return metric('cpu.load', 'CPU load', '%', usage, 100, reason='Waiting for CPU sample')

    def memory(self):
        fields = {}
        for line in read(self.proc / 'meminfo').splitlines():
            key, _, value = line.partition(':')
            fields[key] = number(value.strip().split()[0]) if value.strip() else None
        total, available = fields.get('MemTotal'), fields.get('MemAvailable')
        used = max(0, total - available) * 1024 if total and available is not None else None
        return metric('ram.usage', 'RAM', 'B', used, total * 1024 if total else None,
                      total * 1024 if total else None)

    def temperatures(self, selected):
        sources = []
        for chip in sorted((self.sys / 'class/hwmon').glob('hwmon*')):
            name = read(chip / 'name')
            # Resolve device identity rather than persist changing hwmon numbers.
            identity = str((chip / 'device').resolve()) if (chip / 'device').exists() else str(chip.resolve().parent)
            identity = re.sub(r'/hwmon/hwmon\d+$', '', identity)
            for path in sorted(chip.glob('temp*_input')):
                stem = path.name[:-6]
                value = number(read(path))
                label = read(chip / (stem + '_label')) or stem
                value = value / 1000 if value is not None else None
                if value is None or not -10 <= value <= 150:
                    continue
                rank = 100
                if name in ('coretemp', 'k10temp', 'zenpower'):
                    rank = 0 if re.search('package|tdie', label, re.I) else 1 if 'tctl' in label.lower() else 2
                elif label.upper() == 'CPUTIN':
                    rank = 10
                elif label.upper().startswith('TSI'):
                    rank = 11
                limit = number(read(chip / (stem + '_crit'))) or number(read(chip / (stem + '_max')))
                sources.append(dict(id=identity + ':' + name + ':' + stem,
                                    label=name + ' · ' + label, value=value, rank=rank,
                                    maximum=limit / 1000 if limit and 0 < limit <= 150000 else 100))
        candidates = [s for s in sources if s['id'] == selected] if selected else sorted(
            [s for s in sources if s['rank'] < 100], key=lambda s: (s['rank'], -s['value']))
        source = candidates[0] if candidates else None
        result = metric('cpu.temperature', 'CPU temperature', '°C',
                        source['value'] if source else None, source['maximum'] if source else 100,
                        reason='Selected sensor unavailable' if selected else 'CPU temperature sensor not found')
        result['source'] = source['label'] if source else ''
        return result, sources

    def cpu_power(self, now):
        watts, limits = [], []
        packages = []
        for path in sorted((self.sys / 'class/powercap').glob('*')):
            if read(path / 'name').startswith('package-') and path.resolve() not in packages:
                packages.append(path.resolve())
                energy, span = number(read(path / 'energy_uj')), number(read(path / 'max_energy_range_uj'))
                previous = self.energy.get(str(path.resolve()))
                if energy is not None:
                    self.energy[str(path.resolve())] = (energy, now)
                    if previous and 0 < now - previous[1] <= 10:
                        delta = energy - previous[0]
                        if delta < 0 and span:
                            delta += span
                        if delta >= 0:
                            watts.append(delta / (now - previous[1]) / 1e6)
                cap = number(read(path / 'constraint_0_power_limit_uw'))
                if cap and cap > 0:
                    limits.append(cap / 1e6)
        if not packages:
            # A few CPU drivers expose direct package power through hwmon.
            # Only use recognised CPU chips; motherboard rails are not CPU power.
            direct, caps = [], []
            for chip in sorted((self.sys / 'class/hwmon').glob('hwmon*')):
                if read(chip / 'name') != 'fam15h_power':
                    continue
                value = number(read(chip / 'power1_average'))
                if value is None:
                    value = number(read(chip / 'power1_input'))
                if value is not None and value >= 0:
                    direct.append(value / 1e6)
                    cap = number(read(chip / 'power1_cap'))
                    if cap and cap > 0:
                        caps.append(cap / 1e6)
            if direct:
                return metric('cpu.power', 'CPU package power', 'W', sum(direct),
                              sum(caps) if len(caps) == len(direct) else None)
        return metric('cpu.power', 'CPU package power', 'W',
                      sum(watts) if packages and len(watts) == len(packages) else None,
                      sum(limits) if packages and len(limits) == len(packages) else None,
                      reason='Power sensor unavailable, restricted, or waiting for sample')

    def nvidia(self):
        if not shutil.which('nvidia-smi'):
            return {}, 'nvidia-smi is not installed'
        try:
            result = self.runner(['nvidia-smi', '--query-gpu=pci.bus_id,name,utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw,power.limit',
                                  '--format=csv,noheader,nounits'], capture_output=True, text=True, timeout=1.5)
            if result.returncode:
                return {}, 'NVIDIA driver query failed'
            devices = {}
            for line in result.stdout.splitlines():
                row = [v.strip() for v in line.split(',')]
                if len(row) == 8:
                    devices[row[0].lower()[-12:]] = (row[1], [number(v) for v in row[2:]])
            return devices, 'NVIDIA sensor unavailable'
        except (OSError, subprocess.TimeoutExpired):
            return {}, 'NVIDIA query unavailable or timed out'

    def gpus(self):
        cards = [p for p in sorted((self.sys / 'class/drm').glob('card*')) if re.fullmatch(r'card\d+', p.name)]
        nv, nv_error = self.nvidia() if any(read(p / 'device/vendor') == '0x10de' for p in cards) else ({}, '')
        results = []
        for card in cards:
            device = card / 'device'
            identity = device.resolve().name
            vendor = read(device / 'vendor')
            if not vendor:
                continue
            prefix = 'gpu.' + identity
            name, load, temp, used, total, power, limit, temp_limit = 'GPU ' + identity, None, None, None, None, None, None, 100
            reason = 'Metric not exposed by this GPU driver'
            if vendor == '0x10de':
                reason = nv_error
                if identity.lower() in nv:
                    name, values = nv[identity.lower()]
                    load, temp, used, total, power, limit = values
                    used = used * 1048576 if used is not None else None
                    total = total * 1048576 if total is not None else None
            else:
                load = number(read(device / 'gpu_busy_percent'))
                used = number(read(device / 'mem_info_vram_used'))
                total = number(read(device / 'mem_info_vram_total'))
                for chip in sorted((device / 'hwmon').glob('hwmon*')):
                    value = number(read(chip / 'temp1_input'))
                    if value is not None:
                        temp = value / 1000
                    cap = number(read(chip / 'temp1_crit'))
                    if cap and cap > 0:
                        temp_limit = cap / 1000
                    value = number(read(chip / 'power1_average'))
                    if value is None:
                        value = number(read(chip / 'power1_input'))
                    if value is not None:
                        power = value / 1e6
                    cap = number(read(chip / 'power1_cap'))
                    if cap and cap > 0:
                        limit = cap / 1e6
            if len(cards) > 1 and vendor == '0x10de':
                name += ' (' + identity + ')'
            if not total or total <= 0:
                used = None
            for suffix, label, unit, value, maximum, capacity in [
                ('load', 'load', '%', load, 100, None),
                ('temperature', 'temperature', '°C', temp, temp_limit, None),
                ('memory', 'VRAM', 'B', used, total, total),
                ('power', 'power', 'W', power, limit, None),
            ]:
                entry = metric(prefix + '.' + suffix, name + ' · ' + label, unit, value, maximum, capacity, reason)
                entry['shortLabel'] = 'GPU ' + label
                results.append(entry)
        return results

    def batteries(self):
        result = []
        for supply in sorted((self.sys / 'class/power_supply').glob('*')):
            if read(supply / 'type') != 'Battery' or read(supply / 'scope') == 'Device':
                continue
            power = number(read(supply / 'power_now'))
            if power is None:
                current, voltage = number(read(supply / 'current_now')), number(read(supply / 'voltage_now'))
                power = abs(current * voltage) / 1e6 if current is not None and voltage is not None else None
            entry = metric('battery.' + supply.name + '.power', supply.name + ' battery power', 'W',
                           abs(power) / 1e6 if power is not None else None)
            entry['source'] = read(supply / 'status')
            result.append(entry)
        return result

    def snapshot(self, detailed=True, selected='', now=None):
        now = time.monotonic() if now is None else now
        metrics = [self.cpu(), self.memory()]
        sources = []
        if detailed:
            temperature, sources = self.temperatures(selected)
            metrics.extend([temperature, self.cpu_power(now), *self.gpus(), *self.batteries()])
        return dict(timestamp=time.time() * 1000, metrics=metrics, temperatureSources=sources)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--watch', type=float, default=0)
    parser.add_argument('--basic', action='store_true')
    parser.add_argument('--cpu-sensor', default='')
    args = parser.parse_args()
    collector = Collector()
    while True:
        started = time.monotonic()
        print(json.dumps(collector.snapshot(not args.basic, args.cpu_sensor)), flush=True)
        if not args.watch:
            break
        time.sleep(max(0.05, max(0.5, args.watch) - (time.monotonic() - started)))


if __name__ == '__main__':
    main()
