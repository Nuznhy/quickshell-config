import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('quick_controls', ROOT / 'scripts/quick-controls.py')
backend = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backend)


class NightShiftTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.enterContext(patch.dict(os.environ, XDG_RUNTIME_DIR=self.directory.name, HYPRLAND_INSTANCE_SIGNATURE='test'))
        self.enterContext(patch.object(backend.shutil, 'which', return_value='/usr/bin/test'))
        self.launch = self.enterContext(patch.object(backend.subprocess, 'Popen'))
        self.enterContext(patch.object(backend.time, 'sleep'))

    def test_missing_dependency(self):
        with patch.object(backend.shutil, 'which', return_value=None):
            result = backend.night_shift('on')
        self.assertFalse(result['available'])
        self.assertIn('pacman', result['error'])
        self.launch.assert_not_called()

    def test_status_and_off_never_start_daemon(self):
        with patch.object(backend, 'ipc', return_value=''):
            for action in ['status', 'off']:
                self.assertFalse(backend.night_shift(action)['enabled'])
        self.launch.assert_not_called()

    def test_reuse_existing_and_preserve_gamma(self):
        with patch.object(backend, 'ipc', side_effect=['true', 'ok', 'false']) as ipc:
            self.assertTrue(backend.night_shift('on')['enabled'])
        self.assertEqual([c.args for c in ipc.call_args_list], [('identity', 'get'), ('temperature', '4000'), ('identity', 'get')])
        self.launch.assert_not_called()

    def test_disable_resets_identity(self):
        with patch.object(backend, 'ipc', side_effect=['false', 'ok', 'true']) as ipc:
            self.assertFalse(backend.night_shift('off')['enabled'])
        self.assertEqual(ipc.call_args_list[1].args, ('identity',))

    def test_failed_write_preserves_actual_state(self):
        with patch.object(backend, 'ipc', side_effect=['false', 'error']):
            result = backend.night_shift('off')
        self.assertTrue(result['enabled'])
        self.assertTrue(result['error'])

    def test_start_then_enable(self):
        with patch.object(backend, 'ipc', side_effect=['', 'true', 'ok', 'false']):
            result = backend.night_shift('on')
        self.assertTrue(result['enabled'])
        self.assertEqual(self.launch.call_args.args[0], ['hyprsunset', '--identity'])

    def test_failed_daemon(self):
        self.launch.return_value.poll.return_value = 1
        with patch.object(backend, 'ipc', return_value=''):
            result = backend.night_shift('on')
        self.assertFalse(result['enabled'])
        self.assertIn('Could not start', result['error'])

    def test_external_state(self):
        for identity, expected in [('true', False), ('false', True)]:
            with patch.object(backend, 'ipc', return_value=identity):
                self.assertEqual(backend.night_shift('status')['enabled'], expected)

    def test_summary(self):
        info = backend.summary()
        self.assertTrue(info['hostname'])
        self.assertIn('Up ', info['uptime'])

    def test_selected_temperature(self):
        for temperature in [1500, 2750, 6500]:
            with patch.object(backend, 'ipc', side_effect=['true', 'ok', 'false']) as ipc:
                self.assertTrue(backend.night_shift('on', temperature)['enabled'])
                self.assertEqual(ipc.call_args_list[1].args, ('temperature', str(temperature)))

    def test_adjust_active_filter(self):
        with patch.object(backend, 'ipc', side_effect=['false', 'ok', 'false']) as ipc:
            self.assertTrue(backend.night_shift('adjust', 2000)['enabled'])
        self.assertEqual(ipc.call_args_list[1].args, ('temperature', '2000'))
        self.launch.assert_not_called()

    def test_adjust_cannot_reenable_filter(self):
        for identity in ['true', '']:
            with patch.object(backend, 'ipc', return_value=identity) as ipc:
                self.assertFalse(backend.night_shift('adjust', 2000)['enabled'])
            ipc.assert_called_once_with('identity', 'get')
        self.launch.assert_not_called()

    def test_reject_invalid_temperature(self):
        for value in [1499, 6501, 'warm', 3500.5]:
            with self.assertRaises(ValueError):
                backend.night_shift('adjust', value)


if __name__ == '__main__':
    unittest.main()
