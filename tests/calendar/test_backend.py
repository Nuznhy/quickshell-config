import contextlib
from datetime import date
import importlib.util
import io
import json
import os
from pathlib import Path
import ssl
import subprocess
import sys
import time
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('ical_calendar', ROOT / 'scripts/ical-calendar.py')
feed = importlib.util.module_from_spec(spec)
spec.loader.exec_module(feed)
PRIVATE_URL = 'https://calendar.example.test/private-test-token/basic.ics'


def calendar(*events, extra=''):
    return ('BEGIN:VCALENDAR\r\nVERSION:2.0\r\n' + extra + ''.join(
        'BEGIN:VEVENT\r\n' + event + '\r\nEND:VEVENT\r\n' for event in events) + 'END:VCALENDAR\r\n').encode()


class SecurityTests(unittest.TestCase):
    def test_ui_keyring_requests_use_private_input_and_redacted_responses(self):
        with patch.object(feed, 'keyring') as keyring:
            result = feed.manage(io.StringIO(json.dumps({'action': 'store', 'url': PRIVATE_URL})))
            self.assertTrue(result['ok'])
            keyring.assert_called_once_with('store', PRIVATE_URL)
            self.assertNotIn(PRIVATE_URL, str(result))
            keyring.reset_mock()
            self.assertTrue(feed.manage(io.StringIO('{"action":"forget"}'))['ok'])
            keyring.assert_called_once_with('forget')
            keyring.side_effect = RuntimeError(PRIVATE_URL)
            result = feed.manage(io.StringIO(json.dumps({'action': 'store', 'url': PRIVATE_URL})))
            self.assertFalse(result['ok'])
            self.assertNotIn(PRIVATE_URL, str(result))

    def test_invalid_ui_requests_cannot_modify_keyring(self):
        with patch.object(feed, 'keyring') as keyring:
            for request in ['not json', 'x' * 20001, '{"action":"lookup"}',
                            '{"action":"store","url":"http://example.test/secret"}']:
                self.assertFalse(feed.manage(io.StringIO(request))['ok'])
            keyring.assert_not_called()

    def test_only_valid_https_urls(self):
        self.assertEqual(feed.validate_url(PRIVATE_URL), PRIVATE_URL)
        for url in ['http://example.test/a.ics', 'file:///etc/passwd', 'https://user:pass@example.test/a',
                    'https:///a', 'https://example.test:bad/a', 'https://example.test/a#fragment',
                    'https://example.test/a\nSecret: data', 'https://example.test/a b',
                    'https://example.test\\@evil.test/a']:
            with self.assertRaises(feed.FeedError) as raised:
                feed.validate_url(url)
            self.assertNotIn(url, str(raised.exception))

    def test_redirects_are_never_followed(self):
        for target in ['http://example.test/a', PRIVATE_URL, 'https://evil.test/leak']:
            with self.assertRaises(feed.FeedError) as raised:
                feed.NoRedirect().redirect_request(None, None, 302, 'Found', {}, target)
            self.assertNotIn(target, str(raised.exception))

    def test_network_errors_do_not_disclose_url(self):
        with patch.object(feed, 'build_opener') as build:
            build.return_value.open.side_effect = RuntimeError(PRIVATE_URL)
            with self.assertRaises(feed.FeedError) as raised:
                feed.download(PRIVATE_URL)
            self.assertNotIn('private-test-token', str(raised.exception))

    def test_download_tls_proxy_and_size_limits(self):
        response = Mock(status=200, headers={})
        response.read.return_value = b'feed'
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        with patch.object(feed, 'build_opener') as build:
            build.return_value.open.return_value = response
            self.assertEqual(feed.download(PRIVATE_URL), b'feed')
            proxy, https, redirects = build.call_args.args
            self.assertEqual(proxy.proxies, {})
            self.assertTrue(https._context.check_hostname)
            self.assertEqual(https._context.verify_mode, ssl.CERT_REQUIRED)
            self.assertIsInstance(redirects, feed.NoRedirect)
            response.read.assert_called_once_with(feed.MAX_BYTES + 1)
            response.headers = {'Content-Length': str(feed.MAX_BYTES + 1)}
            with self.assertRaises(feed.FeedError):
                feed.download(PRIVATE_URL)
            response.headers = {'Content-Encoding': 'gzip'}
            with self.assertRaises(feed.FeedError):
                feed.download(PRIVATE_URL)

    def test_keyring_secret_is_not_metadata(self):
        secret = Mock(COLLECTION_DEFAULT='default')
        with patch.object(feed, 'secret_api', return_value=(secret, 'schema')):
            feed.keyring('store', PRIVATE_URL)
            args = secret.password_store_sync.call_args.args
            self.assertEqual(args[4], PRIVATE_URL)
            self.assertNotIn('private-test-token', str(args[:4]))
            secret.password_lookup_sync.return_value = PRIVATE_URL
            self.assertEqual(feed.keyring('lookup'), PRIVATE_URL)
            feed.keyring('forget')
            secret.password_clear_sync.assert_called_once_with('schema', feed.ATTRIBUTES, None)

    def test_keyring_failures_are_redacted_and_removal_is_verified(self):
        secret = Mock()
        with patch.object(feed, 'secret_api', return_value=(secret, 'schema')):
            secret.password_store_sync.side_effect = RuntimeError(PRIVATE_URL)
            with self.assertRaises(feed.FeedError) as raised:
                feed.keyring('store', PRIVATE_URL)
            self.assertNotIn('private-test-token', str(raised.exception))
            secret.password_clear_sync.return_value = False
            with self.assertRaises(feed.FeedError):
                feed.keyring('forget')

    def test_no_network_when_keyring_empty_and_no_url_in_errors(self):
        with patch.object(feed, 'keyring', return_value=None), patch.object(feed, 'download') as download:
            result = feed.snapshot('2026-10-01', '2026-11-01')
            self.assertEqual(result['events'], [])
            self.assertTrue(result['error'])
            download.assert_not_called()
        with patch.object(feed, 'keyring', side_effect=RuntimeError(PRIVATE_URL)):
            self.assertNotIn('private-test-token', str(feed.snapshot('2026-10-01', '2026-11-01')))

    def test_configure_requires_hidden_input(self):
        with patch.object(feed.sys.stdin, 'isatty', return_value=False), patch.object(feed.getpass, 'getpass') as prompt:
            with self.assertRaises(feed.FeedError):
                feed.configure()
            prompt.assert_not_called()
        with patch.object(feed.sys.stdin, 'isatty', return_value=True), \
                patch.object(feed.getpass, 'getpass', return_value=PRIVATE_URL), \
                patch.object(feed, 'keyring') as keyring, contextlib.redirect_stdout(io.StringIO()) as output:
            feed.configure()
            keyring.assert_called_once_with('store', PRIVATE_URL)
            self.assertNotIn('private-test-token', output.getvalue())

    def test_accidental_url_argument_is_not_echoed(self):
        result = subprocess.run([sys.executable, str(ROOT / 'scripts/ical-calendar.py'), 'configure', PRIVATE_URL],
                                text=True, capture_output=True, timeout=5)
        self.assertEqual(result.returncode, 2)
        self.assertNotIn('private-test-token', result.stdout + result.stderr)

    def test_bounded_ranges_and_untrusted_text(self):
        self.assertEqual(feed.bounds('2026-10-01', '2026-11-12'), (date(2026, 10, 1), date(2026, 11, 12)))
        for start, end in [('2026-10-01', '2026-10-01'), ('2026-10-01', '2026-09-30'),
                           ('2026-01-01', '2027-01-01'), ('bad', '2026-10-01')]:
            with self.assertRaises(feed.FeedError):
                feed.bounds(start, end)
        self.assertEqual(feed.plain('a\x00\n\u202eb'), 'ab')
        self.assertEqual(len(feed.plain('x' * 10000)), 300)


@unittest.skipUnless(importlib.util.find_spec('icalendar') and importlib.util.find_spec('recurring_ical_events'),
                     'Install optional iCalendar parser packages')
class ParserTests(unittest.TestCase):
    def setUp(self):
        self.env = patch.dict(os.environ, TZ='UTC')
        self.env.start()
        time.tzset()

    def tearDown(self):
        self.env.stop()
        time.tzset()

    def parse(self, data, first='2026-10-01', last='2026-11-01'):
        return feed.parse_events(data, date.fromisoformat(first), date.fromisoformat(last))

    def test_recurrences_exclusions_and_moved_override(self):
        result = self.parse(calendar(
            'UID:test\r\nDTSTART:20261010T090000Z\r\nDTEND:20261010T100000Z\r\nRRULE:FREQ=DAILY;COUNT=4\r\nEXDATE:20261011T090000Z\r\nSUMMARY:Recurring',
            'UID:test\r\nRECURRENCE-ID:20261012T090000Z\r\nDTSTART:20261012T150000Z\r\nDTEND:20261012T160000Z\r\nSUMMARY:Moved',
            'UID:test\r\nRECURRENCE-ID:20261013T090000Z\r\nDTSTART:20261013T090000Z\r\nDTEND:20261013T100000Z\r\nSTATUS:CANCELLED'))
        self.assertFalse(result['error'])
        self.assertEqual([event['title'] for event in result['events']], ['Recurring', 'Moved'])
        self.assertEqual(result['events'][1]['start'] - result['events'][0]['start'], 54 * 3600000)

    def test_all_day_multiday_default_duration_and_exclusive_bounds(self):
        result = self.parse(calendar(
            'UID:multi\r\nDTSTART;VALUE=DATE:20260930\r\nDTEND;VALUE=DATE:20261002\r\nSUMMARY:Holiday',
            'UID:single\r\nDTSTART;VALUE=DATE:20261010',
            'UID:outside\r\nDTSTART;VALUE=DATE:20261101\r\nSUMMARY:Excluded'))
        self.assertEqual(len(result['events']), 2)
        self.assertEqual(result['events'][0]['endDay'], '2026-10-02')
        self.assertEqual(result['events'][1]['endDay'], '2026-10-11')
        self.assertEqual(result['events'][1]['title'], '(Untitled event)')

    def test_timezone_recurrence_across_dst(self):
        result = self.parse(calendar('UID:dst\r\nDTSTART;TZID=Europe/Kyiv:20261024T090000\r\nDTEND;TZID=Europe/Kyiv:20261024T100000\r\nRRULE:FREQ=DAILY;COUNT=3'))
        self.assertEqual(len(result['events']), 3)
        first, second, third = [event['start'] for event in result['events']]
        self.assertEqual(second - first, 25 * 3600000)
        self.assertEqual(third - second, 24 * 3600000)

    def test_floating_times_and_midnight_overlap(self):
        data = calendar('UID:float\r\nDTSTART:20261010T230000\r\nDTEND:20261011T000000')
        self.assertEqual(len(self.parse(data, '2026-10-10', '2026-10-11')['events']), 1)
        self.assertEqual(self.parse(data, '2026-10-11', '2026-10-12')['events'], [])

    def test_no_attachments_or_descriptions_in_output(self):
        result = self.parse(calendar('UID:private\r\nDTSTART:20261010T090000Z\r\nSUMMARY:<b>Plain text</b>\r\nDESCRIPTION:private-body\r\nATTACH:https://example.test/private-attachment'))
        self.assertEqual(result['events'][0]['title'], '<b>Plain text</b>')
        self.assertNotIn('private-body', str(result))
        self.assertNotIn('private-attachment', str(result))

    def test_invalid_feed_and_output_limit(self):
        for data in [b'<html>Login required</html>', b'not a calendar']:
            with self.assertRaises(feed.FeedError):
                self.parse(data)
        with patch.object(feed, 'MAX_EVENTS', 2):
            result = self.parse(calendar('UID:many\r\nDTSTART:20261001T090000Z\r\nRRULE:FREQ=DAILY;COUNT=20'))
            self.assertEqual(len(result['events']), 2)
            self.assertTrue(result['error'])


if __name__ == '__main__':
    unittest.main()
