import importlib.util
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('desktop_tv', ROOT / 'scripts/desktop-tv.py')
backend = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backend)


def outputs(*names):
    return [dict(name=name, disabled=False) for name in names]


class DesktopTvTests(unittest.TestCase):
    def setUp(self):
        self.enterContext(patch.object(backend.time, 'sleep'))

    def test_status_from_actual_outputs(self):
        self.assertEqual(backend.status(outputs('DP-1', 'DP-2'))['mode'], 'desktop')
        self.assertEqual(backend.status(outputs('DP-1'))['mode'], 'desktop')
        self.assertEqual(backend.status(outputs('HDMI-A-1'))['mode'], 'tv')
        self.assertEqual(backend.status(outputs('DP-1', 'HDMI-A-1'))['mode'], 'transition')
        self.assertEqual(backend.status(outputs())['mode'], 'unavailable')
        self.assertFalse(backend.status(outputs('DP-2'))['available'])

    def test_toggle_waits_for_confirmed_target(self):
        with patch.object(backend, 'ipc', return_value='ok') as ipc, \
                patch.object(backend, 'monitors', side_effect=[
                    outputs('DP-1', 'DP-2', 'HDMI-A-1'),
                    outputs('HDMI-A-1'), outputs('HDMI-A-1'), outputs('HDMI-A-1')]):
            result = backend.toggle(outputs('DP-1', 'DP-2'))
        self.assertEqual(backend.status(result)['mode'], 'tv')
        ipc.assert_called_once_with('eval', 'require("config.monitors").toggleMons()')

    def test_return_to_desktop(self):
        with patch.object(backend, 'ipc', return_value='ok'), \
                patch.object(backend, 'monitors', return_value=outputs('DP-1', 'DP-2')):
            self.assertEqual(backend.status(backend.toggle(outputs('HDMI-A-1')))['mode'], 'desktop')

    def test_confirmation_requires_pending_tv(self):
        with patch.object(backend, 'pending_confirmation', side_effect=[True, False]), \
                patch.object(backend, 'ipc', return_value='ok') as ipc, \
                patch.object(backend, 'monitors', return_value=outputs('HDMI-A-1')):
            self.assertEqual(backend.status(backend.confirm())['mode'], 'tv')
        ipc.assert_called_once_with('eval', 'require("config.monitors").confirmTv()')
        with patch.object(backend, 'pending_confirmation', return_value=False):
            with self.assertRaisesRegex(RuntimeError, 'not awaiting'):
                backend.confirm()

    def test_reject_transition_and_timeout(self):
        with patch.object(backend, 'ipc') as ipc:
            with self.assertRaisesRegex(RuntimeError, 'changing'):
                backend.toggle(outputs('DP-1', 'HDMI-A-1'))
            ipc.assert_not_called()
        with patch.object(backend, 'ipc', side_effect=lambda *args: 'ok' if args[0] == 'eval' else ''), \
                patch.object(backend, 'monitors', return_value=outputs('DP-1')):
            with self.assertRaisesRegex(RuntimeError, 'did not complete'):
                backend.toggle(outputs('DP-1'))
        with patch.object(backend, 'ipc', side_effect=lambda *args: 'ok' if args[0] == 'eval' else 'TV unavailable'), \
                patch.object(backend, 'monitors', return_value=outputs('DP-1')):
            with self.assertRaisesRegex(RuntimeError, 'TV unavailable'):
                backend.toggle(outputs('DP-1'))

    def test_ipc_errors(self):
        result = subprocess.CompletedProcess([], 1, '', 'socket failed')
        with patch.object(backend.subprocess, 'run', return_value=result):
            with self.assertRaisesRegex(RuntimeError, 'socket failed'):
                backend.ipc('reload')
        with patch.object(backend, 'ipc', return_value='Lua error'):
            with self.assertRaisesRegex(RuntimeError, 'Lua error'):
                backend.toggle(outputs('DP-1'))


if __name__ == '__main__':
    unittest.main()
