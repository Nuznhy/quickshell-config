import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('battery', Path(__file__).resolve().parents[2]/'scripts/battery.py')
battery = importlib.util.module_from_spec(spec)
spec.loader.exec_module(battery)

class BatteryTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)

    def device(self, name='BAT0', **values):
        path = self.root/name
        path.mkdir(exist_ok=True)
        values = dict(type='Battery', scope='System', status='Charging', present='1', **values)
        for key, value in values.items():
            (path/key).write_text(str(value))
        return path

    def test_energy_health_and_fallback_charge(self):
        self.device(energy_full=45000000, energy_full_design=50000000, energy_now=22500000)
        self.device('BAT1', charge_full=3000000, charge_full_design=4000000, capacity=60)
        entries = battery.batteries(self.root)
        self.assertEqual([b['percent'] for b in entries], [50, 60])
        self.assertEqual([b['health'] for b in entries], [90, 75])
        self.assertEqual([b['unit'] for b in entries], ['Wh', 'Ah'])

    def test_filter_peripherals_and_absent_batteries(self):
        path = self.device('hidpp_battery_0', capacity=15)
        (path/'scope').write_text('Device')
        path = self.device('BAT0', capacity=60)
        (path/'present').write_text('0')
        self.assertEqual(battery.batteries(self.root), [])

    def test_missing_health_and_threshold(self):
        self.device(capacity=73)
        entry = battery.batteries(self.root)[0]
        self.assertIsNone(entry['health'])
        self.assertFalse(entry['limitSupported'])
        with self.assertRaises(RuntimeError): battery.set_limit('BAT0', 80, self.root)

    def test_start_threshold_then_end(self):
        path = self.device(capacity=90, charge_control_start_threshold=95, charge_control_end_threshold=100)
        calls = []
        def writer(path, value):
            calls.append((path.name, value)); path.write_text(str(value)); return value
        self.assertEqual(battery.set_limit('BAT0', 80, self.root, writer), 80)
        self.assertEqual(calls, [('charge_control_start_threshold', 75), ('charge_control_end_threshold', 80)])
        self.assertEqual(battery.batteries(self.root)[0]['limit'], 80)

    def test_failed_end_rolls_back_start(self):
        path = self.device(charge_control_start_threshold=95, charge_control_end_threshold=100)
        def writer(path, value):
            if path.name == 'charge_control_end_threshold': raise OSError('driver rejected')
            path.write_text(str(value)); return value
        with self.assertRaises(OSError): battery.set_limit('BAT0', 80, self.root, writer)
        self.assertEqual((path/'charge_control_start_threshold').read_text(), '95')

    def test_driver_rounding(self):
        self.device(charge_control_end_threshold=100)
        def writer(path, value): path.write_text('80'); return 80
        self.assertEqual(battery.set_limit('BAT0', 78, self.root, writer), 80)

    def test_input_validation(self):
        for name, value in [('../BAT0', 80), ('/etc/passwd', 80), ('BAT0', 49), ('BAT0', 101), ('BAT0', None)]:
            with self.assertRaises(ValueError): battery.set_limit(name, value, self.root)

    def test_auth_cancel(self):
        path = self.device(charge_control_end_threshold=100)/'charge_control_end_threshold'
        with patch.object(Path, 'write_text', side_effect=PermissionError), patch.object(battery.shutil, 'which', return_value='/usr/bin/pkexec'), patch.object(battery.subprocess, 'run', return_value=subprocess.CompletedProcess([], 126, '', 'cancelled')) as run:
            with self.assertRaisesRegex(RuntimeError, 'authorization'): battery.write_threshold(path, 80)
        self.assertEqual(run.call_args.args[0], ['pkexec', '/usr/bin/tee', str(path)])
        self.assertEqual(run.call_args.kwargs['input'], '80\n')

if __name__ == '__main__': unittest.main()
