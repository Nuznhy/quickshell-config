import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('focus_notification', Path(__file__).resolve().parents[2] / 'scripts/focus-notification.py')
focus = importlib.util.module_from_spec(spec)
spec.loader.exec_module(focus)


def client(address, app, rank=0, **extra):
    return dict(address=address, **{'class': app}, focusHistoryID=rank, **extra)


class FocusTests(unittest.TestCase):
    def test_desktop_ids_and_initial_class(self):
        windows = [client('0x1', 'changed-class', initialClass='org.telegram.desktop')]
        self.assertEqual(focus.choose_window(windows, ['org.telegram.desktop.desktop']), '0x1')

    def test_most_recent_sender_window(self):
        windows = [client('0x1', 'discord', 7), client('0x2', 'discord', 0), client('0x3', 'zen', 1)]
        self.assertEqual(focus.choose_window(windows, ['Discord']), '0x2')

    def test_no_partial_or_title_matches(self):
        windows = [client('0x1', 'discord-helper'), client('0x2', 'terminal', title='Discord')]
        self.assertIsNone(focus.choose_window(windows, ['Discord']))
        self.assertIsNone(focus.choose_window(windows, ['']))

    def test_closed_hidden_invalid_addresses(self):
        windows = [client('0x1', 'app', mapped=False), client('0x2', 'app', hidden=True), client('bad; command', 'app')]
        self.assertIsNone(focus.choose_window(windows, ['app']))

    def test_unranked_window_is_last(self):
        self.assertEqual(focus.choose_window([client('0x1', 'app', -1), client('0x2', 'app', 2)], ['app']), '0x2')


if __name__ == '__main__': unittest.main()
