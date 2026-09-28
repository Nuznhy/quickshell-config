import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
def load(name, file):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'scripts' / file)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module
m = load('monitoring', 'monitoring.py')
t = load('terminal', 'monitoring-terminal.py')

class CollectorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.c = m.Collector(self.base / 'proc', self.base / 'sys')
    def put(self, path, value):
        path = self.base / path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(str(value))
        return path
    def test_cpu_delta_steal_and_guest(self):
        self.put('proc/stat', 'cpu 100 0 100 500 50 0 0 20 100 0\n')
        self.assertIsNone(self.c.cpu()['value'])
        self.put('proc/stat', 'cpu 120 0 100 540 50 0 0 60 120 0\n')
        self.assertAlmostEqual(self.c.cpu()['value'], 60)
        self.assertIsNone(self.c.cpu()['value'])
        self.put('proc/stat', 'cpu 1 0 1 2 0 0 0 0\n')
        self.assertIsNone(self.c.cpu()['value'])
    def test_memory_available(self):
        self.put('proc/meminfo', 'MemTotal: 1000 kB\nMemFree: 100 kB\nMemAvailable: 400 kB\n')
        value = self.c.memory()
        self.assertEqual(value['value'], 600 * 1024)
        self.assertEqual(value['total'], 1000 * 1024)
    def test_sensor_selection_and_invalid(self):
        for chip, name, label, value in [('hwmon0','coretemp','Package id 0',51000), ('hwmon1','nct','CPUTIN',40000), ('hwmon2','nct','AUXTIN',-62000)]:
            self.put(f'sys/class/hwmon/{chip}/name', name)
            self.put(f'sys/class/hwmon/{chip}/temp1_label', label)
            self.put(f'sys/class/hwmon/{chip}/temp1_input', value)
        value, sources = self.c.temperatures('')
        self.assertEqual(value['value'], 51)
        self.assertEqual(len(sources), 2)
        value, _ = self.c.temperatures(sources[1]['id'])
        self.assertEqual(value['value'], 40)
        self.assertFalse(self.c.temperatures('missing')[0]['available'])
    def test_rapl_wrap_and_resume(self):
        self.put('sys/class/powercap/intel-rapl:0/name', 'package-0')
        energy = self.put('sys/class/powercap/intel-rapl:0/energy_uj', 90000000)
        self.put('sys/class/powercap/intel-rapl:0/max_energy_range_uj', 100000000)
        self.assertFalse(self.c.cpu_power(1)['available'])
        energy.write_text('10000000')
        self.assertEqual(self.c.cpu_power(3)['value'], 10)
        self.assertFalse(self.c.cpu_power(100)['available'])
    def test_cpu_hwmon_power(self):
        self.put('sys/class/hwmon/hwmon0/name', 'fam15h_power')
        self.put('sys/class/hwmon/hwmon0/power1_input', 52000000)
        self.put('sys/class/hwmon/hwmon1/name', 'motherboard')
        self.put('sys/class/hwmon/hwmon1/power1_input', 999000000)
        self.assertEqual(self.c.cpu_power(1)['value'], 52)
    def gpu(self, vendor='0x10de'):
        device = self.base / 'sys/devices/0000:0b:00.0'
        device.mkdir(parents=True)
        card = self.base / 'sys/class/drm/card1'
        card.mkdir(parents=True)
        (card / 'device').symlink_to(device)
        (device / 'vendor').write_text(vendor)
        return device
    @patch('shutil.which', return_value='/usr/bin/nvidia-smi')
    def test_nvidia_units_and_na(self, which):
        self.gpu()
        self.c.runner = lambda *a, **k: subprocess.CompletedProcess([],0,'00000000:0B:00.0, RTX 4090, 30, 43, 2000, 24000, 45.5, 450\n')
        entries = self.c.gpus()
        self.assertEqual(entries[0]['id'], 'gpu.0000:0b:00.0.load')
        self.assertEqual(entries[2]['value'], 2000 * 1048576)
        self.assertEqual(entries[3]['value'], 45.5)
        self.c.runner = lambda *a, **k: subprocess.CompletedProcess([],0,'00000000:0B:00.0, RTX 4090, N/A, 43, N/A, 24000, [Not Supported], 450\n')
        entries = self.c.gpus()
        self.assertFalse(entries[0]['available'])
        self.assertTrue(entries[1]['available'])
        self.assertFalse(entries[3]['available'])
    @patch('shutil.which', return_value='/usr/bin/nvidia-smi')
    def test_nvidia_timeout(self, which):
        self.gpu()
        def timeout(*a, **k): raise subprocess.TimeoutExpired('nvidia-smi', 1.5)
        self.c.runner = timeout
        self.assertTrue(all(not value['available'] for value in self.c.gpus()))
    def test_amd_and_multiple_devices(self):
        device = self.gpu('0x1002')
        (device / 'gpu_busy_percent').write_text('55')
        chip = device / 'hwmon/hwmon3'
        chip.mkdir(parents=True)
        (chip / 'temp1_input').write_text('65000')
        (chip / 'power1_average').write_text('52000000')
        values = self.c.gpus()
        self.assertEqual([v['value'] for v in values], [55,65,None,52])
        self.assertFalse(values[2]['available'])
        (self.base / 'sys/class/drm/card1').rename(self.base / 'sys/class/drm/card8')
        self.assertEqual(self.c.gpus()[0]['id'], values[0]['id'])
        second = self.base / 'sys/devices/0000:0c:00.0'
        second.mkdir()
        (second / 'vendor').write_text('0x8086')
        card = self.base / 'sys/class/drm/card2'
        card.mkdir()
        (card / 'device').symlink_to(second)
        entries = self.c.gpus()
        self.assertEqual(len(entries), 8)
        self.assertEqual(len({entry['id'] for entry in entries}), 8)
    def test_battery_conversion_and_peripherals(self):
        for name, scope in [('BAT0','System'),('mouse','Device')]:
            for key, value in [('type','Battery'),('scope',scope),('current_now',2000000),('voltage_now',12000000)]:
                self.put(f'sys/class/power_supply/{name}/{key}',value)
        entries = self.c.batteries()
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0]['value'], 24)
    def test_empty_system_and_basic_mode(self):
        result = self.c.snapshot()
        self.assertTrue(all(not entry['available'] for entry in result['metrics']))
        self.assertEqual(len(self.c.snapshot(False)['metrics']), 2)

class TerminalTests(unittest.TestCase):
    def which(self, *names): return lambda name: '/usr/bin/' + name if name in names else None
    def test_xdg_preferred(self):
        self.assertEqual(t.terminal_command({'TERMINAL':'kitty'}, '/nonexistent', self.which('btop','xdg-terminal-exec','kitty')), ['xdg-terminal-exec','btop'])
    def test_env_and_no_shell(self):
        self.assertEqual(t.terminal_command({'TERMINAL':'foot --title "hello world"'}, '/nonexistent', self.which('btop','foot')), ['foot','--title','hello world','--','btop'])
    def test_hypr_default(self):
        with tempfile.TemporaryDirectory() as base:
            path = Path(base) / '.config/hypr/config/vars.lua'
            path.parent.mkdir(parents=True)
            path.write_text('return {\n    terminal = "ghostty",\n}')
            self.assertEqual(t.terminal_command({},base,self.which('btop','ghostty','kitty')), ['ghostty','-e','btop'])
    def test_missing_dependency(self):
        with self.assertRaisesRegex(RuntimeError, 'Install btop'):
            t.terminal_command({},'/nonexistent',self.which('ghostty'))
        with self.assertRaisesRegex(RuntimeError, 'No supported terminal'):
            t.terminal_command({},'/nonexistent',self.which('btop'))

if __name__ == '__main__': unittest.main()
