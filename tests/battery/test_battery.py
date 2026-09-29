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
        values = dict(dict(type='Battery', scope='System', status='Charging', present='1'), **values)
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

    def test_energy_charge_and_discharge_times(self):
        path = self.device(energy_full=60000000, energy_now=30000000, power_now=15000000)
        self.assertEqual(battery.batteries(self.root)[0]['timeRemaining'], 7200)
        (path/'status').write_text('Discharging')
        (path/'power_now').write_text('10000000')
        self.assertEqual(battery.batteries(self.root)[0]['timeRemaining'], 10800)

    def test_charge_units_signed_current_and_average_fallback(self):
        self.device(status='Discharging', charge_full=4000000, charge_now=2000000,
                    current_now=0, current_avg=-500000)
        self.assertEqual(battery.batteries(self.root)[0]['timeRemaining'], 14400)

    def test_native_estimates_and_applied_charge_limit(self):
        path = self.device(energy_full=60000000, energy_now=30000000, power_now=12000000,
                           time_to_full_now=8500)
        self.assertEqual(battery.batteries(self.root)[0]['timeRemaining'], 8500)
        (path/'charge_control_end_threshold').write_text('80')
        entry = battery.batteries(self.root)[0]
        self.assertEqual(entry['chargeTarget'], 80)
        self.assertEqual(entry['timeRemaining'], 5400)
        (path/'status').write_text('Discharging')
        (path/'time_to_empty_avg').write_text('1234')
        self.assertEqual(battery.batteries(self.root)[0]['timeRemaining'], 1234)

    def test_missing_idle_and_zero_rate_estimates(self):
        path = self.device(energy_full=60000000, energy_now=30000000)
        self.assertIsNone(battery.batteries(self.root)[0]['timeRemaining'])
        (path/'power_now').write_text('0')
        self.assertIsNone(battery.batteries(self.root)[0]['timeRemaining'])
        (path/'time_to_full_now').write_text('500')
        for status in ('Full', 'Not charging', 'Unknown'):
            (path/'status').write_text(status)
            self.assertIsNone(battery.batteries(self.root)[0]['timeRemaining'])
        (path/'status').write_text('Charging')
        (path/'charge_control_end_threshold').write_text('50')
        (path/'power_now').write_text('1000000')
        self.assertEqual(battery.batteries(self.root)[0]['timeRemaining'], 0)

    def test_power_profiles_discovery_switch_and_external_change(self):
        self.assertFalse(battery.power_profiles(self.root)['available'])
        (self.root/'platform_profile_choices').write_text('low-power balanced performance unknown')
        path = self.root/'platform_profile'
        path.write_text('balanced')
        state = battery.power_profiles(self.root)
        self.assertTrue(state['available'])
        self.assertEqual([p['id'] for p in state['profiles']], ['low-power', 'balanced', 'performance'])
        self.assertEqual(battery.set_profile('performance', self.root), 'performance')
        self.assertEqual(path.read_text(), 'performance\n')
        path.write_text('low-power')
        self.assertEqual(battery.power_profiles(self.root)['current'], 'low-power')
        for name in ('../performance', 'quiet', 'unknown', ''):
            with self.assertRaises(ValueError): battery.set_profile(name, self.root)
        self.assertEqual(path.read_text(), 'low-power')

    def test_profile_rejection_and_authorization(self):
        (self.root/'platform_profile_choices').write_text('balanced performance')
        path = self.root/'platform_profile'
        path.write_text('balanced')
        with self.assertRaisesRegex(RuntimeError, 'did not apply'):
            battery.set_profile('performance', self.root, lambda path, value: 'balanced')
        with patch.object(Path, 'write_text', side_effect=PermissionError), patch.object(battery.shutil, 'which', return_value='/usr/bin/pkexec'), patch.object(battery.subprocess, 'run', return_value=subprocess.CompletedProcess([], 126, '', 'cancelled')) as run:
            with self.assertRaisesRegex(RuntimeError, 'authorization'):
                battery.set_profile('performance', self.root)
        self.assertEqual(run.call_args.args[0], ['pkexec', '/usr/bin/tee', str(path)])
        self.assertEqual(run.call_args.kwargs['input'], 'performance\n')
        self.assertEqual(path.read_text(), 'balanced')

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
