import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch, call

spec = importlib.util.spec_from_file_location('power', Path(__file__).resolve().parents[2] / 'scripts/power-action.py')
power = importlib.util.module_from_spec(spec)
spec.loader.exec_module(power)


class PowerTests(unittest.TestCase):
    def setUp(self):
        available = patch.object(power.shutil, 'which', side_effect=lambda name: '/usr/bin/' + name)
        available.start()
        self.addCleanup(available.stop)

    def test_lock_uses_hypridle(self):
        with patch.object(power, 'run') as run:
            power.perform('lock')
            self.assertEqual(run.call_args_list, [
                call(['pgrep', '-u', str(os.getuid()), '-x', 'hypridle']),
                call(['loginctl', 'lock-session'])])

    def test_sleep_requests_lock_before_logind_suspend(self):
        with patch.object(power, 'run') as run:
            power.perform('sleep')
            self.assertEqual(run.call_args_list, [
                call(['pgrep', '-u', str(os.getuid()), '-x', 'hypridle']),
                call(['loginctl', 'lock-session']),
                call(['systemctl', 'suspend'], timeout=120)])

    def test_lock_failure_prevents_sleep(self):
        with patch.object(power, 'run', side_effect=['123', RuntimeError('Lock request failed')]) as run:
            with self.assertRaises(RuntimeError):
                power.perform('sleep')
            self.assertFalse(any(item.args[0][0] == 'systemctl' for item in run.call_args_list))

    def test_missing_hypridle_listener_prevents_sleep(self):
        with patch.object(power, 'run', side_effect=RuntimeError('No process')) as run:
            with self.assertRaisesRegex(RuntimeError, 'Hypridle is not running'):
                power.perform('sleep')
            self.assertEqual(run.call_count, 1)

    def test_missing_dependencies_prevent_lock_and_sleep(self):
        for missing in ('hyprlock', 'hypridle', 'pgrep', 'loginctl'):
            for action in ('lock', 'sleep'):
                with self.subTest(missing=missing, action=action), patch.object(power.shutil, 'which', side_effect=lambda name: None if name == missing else '/bin/' + name), patch.object(power, 'run') as run:
                    with self.assertRaisesRegex(RuntimeError, missing): power.perform(action)
                    run.assert_not_called()

    def test_reboot_shutdown_and_invalid_action(self):
        with patch.object(power, 'run') as run:
            power.perform('reboot')
            self.assertEqual(run.call_args.args[0], ['systemctl', 'reboot'])
            power.perform('shutdown')
            self.assertEqual(run.call_args.args[0], ['systemctl', 'poweroff'])
            with self.assertRaises(ValueError):
                power.perform('invalid')
            self.assertEqual(run.call_count, 2)

    def test_cli_with_fake_session_commands(self):
        import json
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            log = root / 'calls.jsonl'
            command = '''#!/usr/bin/python3
import json, os, sys
from pathlib import Path
with Path(os.environ['POWER_TEST_LOG']).open('a') as stream:
    stream.write(json.dumps([Path(sys.argv[0]).name] + sys.argv[1:]) + '\\n')
if Path(sys.argv[0]).name == os.environ.get('POWER_TEST_FAIL'): sys.exit(1)
'''
            for name in ('hyprlock', 'hypridle', 'pgrep', 'loginctl', 'systemctl'):
                path = root / name
                path.write_text(command)
                path.chmod(0o700)
            env = dict(os.environ, PATH=str(root), POWER_TEST_LOG=str(log))
            result = subprocess.run(['/usr/bin/python3', str(Path(power.__file__)), 'sleep'], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual([json.loads(line)[0] for line in log.read_text().splitlines()], ['pgrep', 'loginctl', 'systemctl'])
            log.write_text('')
            result = subprocess.run(['/usr/bin/python3', str(Path(power.__file__)), 'sleep'], env=dict(env, POWER_TEST_FAIL='loginctl'), capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn('systemctl', log.read_text())


if __name__ == '__main__':
    unittest.main()
