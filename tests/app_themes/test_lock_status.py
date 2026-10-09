"""Read-only lock cards: escaping, player choice and bounded local task status."""
import importlib.util
from contextlib import closing
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('lock_status', Path(__file__).resolve().parents[2] / 'scripts/hyprlock-status.py')
status = importlib.util.module_from_spec(spec)
spec.loader.exec_module(status)


class LockStatusTests(unittest.TestCase):
    def test_media_priority_and_markup(self):
        paused = {'PlaybackStatus': 'Paused', 'Metadata': {'xesam:title': 'Old'}}
        playing = {'PlaybackStatus': 'Playing', 'Metadata': {
            'xesam:title': '<b>Track</b>\nnext', 'xesam:artist': ['A & B']}}
        label = status.media_label([paused, playing])
        self.assertIn('NOW PLAYING', label)
        self.assertIn('&lt;b&gt;Track&lt;/b&gt; next', label)
        self.assertIn('A &amp; B', label)
        self.assertEqual(len(label.splitlines()), 3)
        self.assertIn('PAUSED', status.media_label([paused]))
        self.assertIn('Nothing playing', status.media_label([{'PlaybackStatus': 'Stopped'}]))

    def test_disappearing_player(self):
        with patch.object(status, 'bus_call', side_effect=[
                ['org.mpris.MediaPlayer2.a', 'org.mpris.MediaPlayer2.b'], OSError(),
                {'PlaybackStatus': {'type': 's', 'data': 'Playing'},
                 'Metadata': {'type': 'a{sv}', 'data': {'xesam:title': {'type': 's', 'data': 'Live'}}}}]):
            self.assertIn('Live', status.media_status())

    def test_long_and_control_text(self):
        self.assertEqual(status.safe_text('x' * 100), 'x' * 31 + '…')
        self.assertEqual(status.safe_text('界' * 100), '界' * 15 + '…')
        self.assertEqual(status.safe_text('A\u202eB\x00C'), 'ABC')

    def test_local_task_lifecycle_and_stale_data(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            self.assertIn('No local task data', status.codex_status(home, 1000))
            rollout = home / 'rollout.jsonl'
            with closing(sqlite3.connect(home / 'state_5.sqlite')) as db:
                db.execute('CREATE TABLE threads (rollout_path TEXT, archived INT, updated_at INT)')
                db.execute('INSERT INTO threads VALUES (?, 0, 1000)', (str(rollout),))
                db.commit()
            def write(kind):
                rollout.write_text(json.dumps({'type': 'event_msg', 'timestamp': '1970-01-01T00:16:40Z',
                    'payload': {'type': kind, 'last_agent_message': 'PRIVATE'}}) + '\n{"partial":')
            write('task_started')
            self.assertIn('Working', status.codex_status(home, 1001))
            self.assertIn('Awaiting update', status.codex_status(home, 1201))
            write('task_complete')
            self.assertIn('Completed', status.codex_status(home, 1001))
            self.assertNotIn('PRIVATE', status.codex_status(home, 1001))
            write('turn_aborted')
            self.assertIn('Interrupted', status.codex_status(home, 1001))
            self.assertIn('No recent task activity', status.codex_status(home, 100000))
            rollout.unlink()
            self.assertIn('No recent task activity', status.codex_status(home, 1001))

    def test_bounded_tail_ignores_truncated_record(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / 'rollout.jsonl'
            path.write_text('x' * 300000 + '\n' + json.dumps({'type': 'event_msg',
                'timestamp': '1970-01-01T00:16:40Z', 'payload': {'type': 'task_complete'}}) + '\n')
            self.assertEqual(status.rollout_status(path, 1001), (1000, 'Completed'))
