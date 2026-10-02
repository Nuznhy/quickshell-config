import fcntl
import hashlib
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('launcher', ROOT / 'scripts/launch-hyprlock.py')
launcher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(launcher)


class LauncherTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.runtime = Path(self.temp.name)

    def test_existing_compositor_lock_is_untouched(self):
        with patch.object(launcher, 'is_locked', return_value=True), \
                patch.object(launcher.subprocess, 'Popen') as spawn:
            launcher.launch(self.runtime, 'session')
            spawn.assert_not_called()

    def test_relock_does_not_depend_on_previous_process_exit(self):
        with patch.object(launcher, 'is_locked', side_effect=[False, True, False, True]), \
                patch.object(launcher.subprocess, 'Popen') as spawn:
            # The first child remains alive even after its compositor unlocks.
            spawn.return_value.poll.return_value = None
            launcher.launch(self.runtime, 'session')
            launcher.launch(self.runtime, 'session')
            self.assertEqual(spawn.call_count, 2)
            spawn.return_value.terminate.assert_not_called()
            spawn.return_value.kill.assert_not_called()
            self.assertTrue(spawn.call_args.kwargs['close_fds'])

    def test_duplicate_startup_is_ignored(self):
        key = hashlib.sha256(b'session').hexdigest()[:16]
        with (self.runtime / f'quickshell-hyprlock-{key}.lock').open('a') as guard:
            fcntl.flock(guard, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with patch.object(launcher, 'is_locked') as state:
                launcher.launch(self.runtime, 'session')
                state.assert_not_called()

    def test_unknown_state_does_not_start_or_kill_a_locker(self):
        for output in ('{}', '{"locked": "false"}', 'unknown request'):
            with self.subTest(output=output), \
                    patch.object(launcher.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, output)), \
                    patch.object(launcher.subprocess, 'Popen') as spawn:
                with self.assertRaises((ValueError, RuntimeError)):
                    launcher.launch(self.runtime, 'session')
                spawn.assert_not_called()

    def test_failed_locker_reports_log(self):
        with patch.object(launcher, 'is_locked', return_value=False), \
                patch.object(launcher.subprocess, 'Popen') as spawn:
            spawn.return_value.poll.return_value = 1
            with self.assertRaisesRegex(RuntimeError, r'status 1.*\.log'):
                launcher.launch(self.runtime, 'session')

    def test_startup_timeout_keeps_locker_intact(self):
        with patch.object(launcher, 'is_locked', return_value=False), \
                patch.object(launcher.subprocess, 'Popen') as spawn:
            with self.assertRaisesRegex(RuntimeError, 'did not lock'):
                launcher.launch(self.runtime, 'session', timeout=0)
            spawn.return_value.kill.assert_not_called()
            spawn.return_value.terminate.assert_not_called()

    def test_fast_successful_unlock(self):
        with patch.object(launcher, 'is_locked', return_value=False), \
                patch.object(launcher.subprocess, 'Popen') as spawn:
            spawn.return_value.poll.return_value = 0
            launcher.launch(self.runtime, 'session')
