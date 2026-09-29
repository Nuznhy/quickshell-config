import importlib.util
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('display_mode', ROOT / 'scripts/display-mode.py')
backend = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backend)


def displays(source='none'):
    return [dict(id=0, name='eDP-1', mirrorOf='none', disabled=False, dpmsStatus=True),
            dict(id=1, name='HDMI-A-1', mirrorOf=source, disabled=False, dpmsStatus=True)]


class DisplayModeTests(unittest.TestCase):
    def setUp(self):
        self.enterContext(patch.object(backend.time, 'sleep'))

    def test_discover_extended_and_mirrored_including_id_zero(self):
        self.assertTrue(backend.status(displays())['available'])
        self.assertFalse(backend.status(displays())['mirrored'])
        for source in [0, '0', 'eDP-1']:
            self.assertTrue(backend.status(displays(source))['mirrored'])

    def test_missing_external_or_internal_or_disabled_laptop(self):
        for outputs in [[], displays()[:1], displays()[1:]]:
            self.assertFalse(backend.status(outputs)['available'])
        outputs = displays()
        outputs[0]['disabled'] = True
        self.assertFalse(backend.status(outputs)['available'])

    def test_laptop_as_mirror_cannot_be_source(self):
        outputs = displays()
        outputs[0]['mirrorOf'] = 1
        self.assertFalse(backend.status(outputs)['available'])

    def test_screen_off_blocks_mirror_but_allows_restore(self):
        for source, available in [('none', False), ('0', True)]:
            outputs = displays(source)
            outputs[0]['dpmsStatus'] = False
            self.assertEqual(backend.status(outputs)['available'], available)

    def test_missing_hardware_never_issues_changes(self):
        with patch.object(backend, 'change') as change:
            with self.assertRaisesRegex(RuntimeError, 'Connect'):
                backend.toggle(displays()[:1])
            change.assert_not_called()

    def test_automatic_resolution_only_changes_external_outputs(self):
        with patch.object(backend, 'change') as change, \
                patch.object(backend, 'monitors', side_effect=[displays(), displays('0')]):
            result = backend.toggle(displays())
        self.assertTrue(backend.status(result)['mirrored'])
        change.assert_called_once()
        command, lua = change.call_args.args
        self.assertEqual(command, 'eval')
        self.assertIn('output = "HDMI-A-1"', lua)
        self.assertIn('mode = "preferred"', lua)
        self.assertIn('scale = "auto"', lua)
        self.assertIn('mirror = "eDP-1"', lua)
        self.assertNotIn('output = "eDP-1"', lua)

    def test_restore_reloads_saved_rules_without_guessing_resolution(self):
        with patch.object(backend, 'change') as change, \
                patch.object(backend, 'ipc', return_value='') as ipc, \
                patch.object(backend, 'monitors', return_value=displays()):
            self.assertFalse(backend.status(backend.toggle(displays('0')))['mirrored'])
        change.assert_called_once_with('reload')
        ipc.assert_called_once_with('configerrors')

    def test_restore_reports_broken_configuration(self):
        with patch.object(backend, 'change'), \
                patch.object(backend, 'ipc', return_value='bad monitor rule'), \
                patch.object(backend, 'monitors', return_value=displays()):
            with self.assertRaisesRegex(RuntimeError, 'configuration errors'):
                backend.toggle(displays('0'))

    def test_failed_or_unconfirmed_mirror_restores_config(self):
        for failure in [None, RuntimeError('bad mode'), subprocess.TimeoutExpired('hyprctl', 5)]:
            with self.subTest(failure=failure), \
                    patch.object(backend, 'change', side_effect=[failure, None]) as change, \
                    patch.object(backend, 'monitors', return_value=displays()):
                with self.assertRaisesRegex(RuntimeError, 'Reloaded your configured layout'):
                    backend.toggle(displays())
                self.assertEqual(change.call_args.args, ('reload',))

    def test_multiple_externals_and_hot_unplug_rollback(self):
        outputs = displays() + [dict(id=2, name='DP-2', mirrorOf='none')]
        mirrored = [dict(m, mirrorOf='0') if m['id'] else m for m in outputs]
        with patch.object(backend, 'change') as change, \
                patch.object(backend, 'monitors', return_value=mirrored):
            backend.toggle(outputs)
            self.assertEqual(change.call_args.args[1].count('hl.monitor('), 2)
        with patch.object(backend, 'change') as change, \
                patch.object(backend, 'monitors', return_value=mirrored[:2]):
            with self.assertRaisesRegex(RuntimeError, 'Reloaded'):
                backend.toggle(outputs)
            self.assertEqual(change.call_args.args, ('reload',))

    def test_failed_rollback_is_reported(self):
        with patch.object(backend, 'change', side_effect=RuntimeError('socket failed')):
            with self.assertRaisesRegex(RuntimeError, 'Restore also failed'):
                backend.toggle(displays())

    def test_reject_lua_in_connector(self):
        with self.assertRaises(ValueError):
            backend.mirror_command(dict(name='DP-1"}); os.execute("bad")'), 'eDP-1')

    def test_reject_ipc_failure_and_error_reply(self):
        result = subprocess.CompletedProcess([], 1, '', 'socket failed')
        with patch.object(backend.subprocess, 'run', return_value=result):
            with self.assertRaisesRegex(RuntimeError, 'socket failed'):
                backend.ipc('reload')
        with patch.object(backend, 'ipc', return_value='Lua error'):
            with self.assertRaisesRegex(RuntimeError, 'Lua error'):
                backend.change('eval', 'bad')


if __name__ == '__main__':
    unittest.main()
