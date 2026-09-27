import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch, call

spec = importlib.util.spec_from_file_location('power', Path(__file__).resolve().parents[2] / 'scripts/power-action.py')
power = importlib.util.module_from_spec(spec)
spec.loader.exec_module(power)


class PowerTests(unittest.TestCase):
    def test_sleep_waits_for_secure_lock(self):
        with patch.object(power, 'run', side_effect=['', 'pending', 'secure', '']) as run, patch.object(power.time, 'sleep'):
            power.perform('sleep')
            self.assertEqual(run.call_args_list[-1], call(['systemctl', 'suspend'], timeout=120))
            self.assertEqual(run.call_count, 4)

    def test_lock_failure_prevents_sleep(self):
        with patch.object(power, 'run', return_value='pending') as run, patch.object(power.time, 'sleep'):
            with self.assertRaises(RuntimeError):
                power.perform('sleep')
            self.assertFalse(any(item.args[0][0] == 'systemctl' for item in run.call_args_list))

    def test_failed_locker_launch_prevents_sleep(self):
        with patch.object(power, 'run', side_effect=RuntimeError('Lock could not start')) as run:
            with self.assertRaises(RuntimeError):
                power.perform('sleep')
            self.assertEqual(run.call_count, 1)

    def test_reboot_shutdown_and_invalid_action(self):
        with patch.object(power, 'run') as run:
            power.perform('reboot')
            self.assertEqual(run.call_args.args[0], ['systemctl', 'reboot'])
            power.perform('shutdown')
            self.assertEqual(run.call_args.args[0], ['systemctl', 'poweroff'])
            with self.assertRaises(ValueError):
                power.perform('invalid')
            self.assertEqual(run.call_count, 2)


if __name__ == '__main__':
    unittest.main()
