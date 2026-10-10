#!/usr/bin/env python3
"""Display a private HTTPS iCalendar feed; keep its URL only in Secret Service."""
import argparse
from datetime import date, datetime, time, timedelta
import getpass
import json
import resource
import signal
import ssl
import sys
import unicodedata
from urllib.parse import urlsplit
from urllib.request import HTTPSHandler, HTTPRedirectHandler, ProxyHandler, Request, build_opener
import warnings

MAX_BYTES = 5 * 1024 * 1024
MAX_EVENTS = 2000
ATTRIBUTES = {'application': 'quickshell', 'purpose': 'ical-feed', 'slot': 'default'}


class FeedError(Exception):
    """Only fixed, non-sensitive messages may cross the helper boundary."""


def plain(value, limit=300):
    return ''.join(c for c in str(value or '') if not unicodedata.category(c).startswith('C'))[:limit]


def validate_url(value):
    try:
        if len(value) > 8192 or any(c.isspace() or ord(c) < 32 or ord(c) == 127 for c in value):
            raise ValueError
        parts = urlsplit(value)
        if (parts.scheme != 'https' or not parts.hostname or parts.username is not None
                or parts.password is not None or parts.fragment or '\\' in value):
            raise ValueError
        if parts.port is not None and not 1 <= parts.port <= 65535:
            raise ValueError
        value.encode('ascii')
    except (ValueError, UnicodeError):
        raise FeedError('Use a valid HTTPS iCalendar URL without userinfo, spaces or a fragment.') from None
    return value


def secret_api():
    try:
        import gi
        gi.require_version('Secret', '1')
        from gi.repository import Secret
        schema = Secret.Schema.new('org.quickshell.CalendarFeed', Secret.SchemaFlags.NONE,
                                   {key: Secret.SchemaAttributeType.STRING for key in ATTRIBUTES})
        return Secret, schema
    except (ImportError, ValueError):
        raise FeedError('Install libsecret and python-gobject, and run GNOME Keyring.') from None


def keyring(action, value=None):
    secret, schema = secret_api()
    try:
        if action == 'store':
            if not secret.password_store_sync(schema, ATTRIBUTES, secret.COLLECTION_DEFAULT,
                                              'Quickshell private iCalendar feed', value, None):
                raise RuntimeError
        elif action == 'forget':
            if not secret.password_clear_sync(schema, ATTRIBUTES, None):
                raise FeedError('No unlocked feed was removed. Unlock your keyring, or check that a feed is configured.')
        else:
            return secret.password_lookup_sync(schema, ATTRIBUTES, None)
    except FeedError:
        raise
    except Exception:
        raise FeedError('Keyring unavailable or locked. Unlock GNOME Keyring and try again.') from None


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise FeedError('Calendar feed redirected. Configure its direct HTTPS iCalendar address.')


class SafeArgumentParser(argparse.ArgumentParser):
    def error(self, _message):
        # Accidental URL arguments must not be echoed by argparse either.
        self.exit(2, 'Invalid arguments. Use --help; enter secret URLs only at the configure prompt.\n')


def download(url):
    validate_url(url)
    # Never inherit proxy credentials or follow redirects with a secret URL.
    opener = build_opener(ProxyHandler({}), HTTPSHandler(context=ssl.create_default_context()), NoRedirect())
    request = Request(url, headers={'Accept': 'text/calendar', 'Accept-Encoding': 'identity',
                                    'User-Agent': 'Quickshell-Calendar/1'})
    try:
        with opener.open(request, timeout=12) as response:
            if response.status != 200:
                raise FeedError('Calendar server did not return a feed. Check or replace its secret URL.')
            if response.headers.get('Content-Encoding', 'identity').lower() != 'identity':
                raise FeedError('Compressed calendar responses are not supported.')
            length = response.headers.get('Content-Length')
            if length is not None and int(length) > MAX_BYTES:
                raise FeedError('Calendar feed exceeds the 5 MiB limit.')
            data = response.read(MAX_BYTES + 1)
            if len(data) > MAX_BYTES:
                raise FeedError('Calendar feed exceeds the 5 MiB limit.')
            return data
    except FeedError:
        raise
    except Exception:
        # urllib exceptions contain the full secret URL. Never print them.
        raise FeedError('Could not download calendar securely. Check the connection and secret feed URL.') from None


def bounds(start, end):
    try:
        first, last = date.fromisoformat(start), date.fromisoformat(end)
        if not 1 <= (last - first).days <= 62:
            raise ValueError
        return first, last
    except ValueError:
        raise FeedError('Invalid calendar date range (maximum 62 days).') from None


def event_record(component, name):
    start, end = component.decoded('DTSTART'), component.decoded('DTEND')
    all_day = isinstance(start, date) and not isinstance(start, datetime)
    record = {'title': plain(component.get('SUMMARY')) or '(Untitled event)',
              'calendar': name, 'allDay': all_day}
    if all_day:
        if end <= start:
            end = start + timedelta(days=1)
        record.update(startDay=start.isoformat(), endDay=end.isoformat())
    else:
        # Naive (floating) times use the system timezone, including date-specific DST.
        first, last = int(start.timestamp() * 1000), int(end.timestamp() * 1000)
        record.update(start=first, end=max(first, last))
    return record


def parse_events(data, first, last):
    try:
        from icalendar import Calendar
        import recurring_ical_events
        from dateutil.tz import gettz
    except ImportError:
        raise FeedError('Install python-icalendar and python-recurring-ical-events. See README → iCalendar feed.') from None
    if len(data) > MAX_BYTES:
        raise FeedError('Calendar feed exceeds the 5 MiB limit.')
    try:
        calendar = Calendar.from_ical(data)
        if calendar.name != 'VCALENDAR' or any(item.errors for item in calendar.walk()):
            raise ValueError
        name = plain(calendar.get('X-WR-CALNAME'), 100) or 'Calendar'
        local = gettz()
        lower = datetime.combine(first, time(), local)
        upper = datetime.combine(last, time(), local)
        lower_ms, upper_ms = int(lower.timestamp() * 1000), int(upper.timestamp() * 1000)
        # Include a margin for all-day dates in feeds with a different timezone.
        pages = recurring_ical_events.of(calendar).paginate(
            100, earliest_end=lower - timedelta(days=1), latest_start=upper + timedelta(days=1))
        events, inspected, truncated = [], 0, False
        for page in pages:
            for component in page:
                inspected += 1
                if inspected > 10000 or len(events) >= MAX_EVENTS:
                    truncated = True
                    break
                if str(component.get('STATUS', '')).upper() == 'CANCELLED':
                    continue
                event = event_record(component, name)
                if event['allDay']:
                    include = event['startDay'] < last.isoformat() and event['endDay'] > first.isoformat()
                else:
                    include = event['start'] < upper_ms and (event['end'] > lower_ms or
                              event['start'] == event['end'] and event['start'] >= lower_ms)
                if include:
                    events.append(event)
            if truncated:
                break
        events.sort(key=lambda event: (event.get('startDay', '') if event['allDay'] else
                                      datetime.fromtimestamp(event['start'] / 1000).strftime('%Y-%m-%d'),
                                      not event['allDay'], event.get('start', 0), event['title']))
        return {'events': events, 'error': 'Event limit reached; some events are omitted.' if truncated else ''}
    except FeedError:
        raise
    except Exception:
        raise FeedError('Calendar feed is invalid or could not be expanded safely.') from None


def snapshot(start, end):
    try:
        first, last = bounds(start, end)
        url = keyring('lookup')
        if not url:
            raise FeedError('No unlocked iCalendar feed found. Open Settings → Bar layout → Clock settings to save an address, or unlock your keyring.')
        return parse_events(download(url), first, last)
    except FeedError as error:
        return {'events': [], 'error': str(error)}
    except Exception:
        return {'events': [], 'error': 'Calendar unavailable. Unlock your keyring and check the feed setup.'}


def manage(stream):
    """Private stdin IPC for the UI; never return the stored URL."""
    try:
        raw = stream.read(20001)
        if len(raw) > 20000:
            raise ValueError
        request = json.loads(raw)
        if request.get('action') == 'store' and isinstance(request.get('url'), str):
            keyring('store', validate_url(request['url']))
        elif request.get('action') == 'forget':
            keyring('forget')
        else:
            raise ValueError
        return {'ok': True, 'error': ''}
    except FeedError as error:
        return {'ok': False, 'error': str(error)}
    except Exception:
        return {'ok': False, 'error': 'Could not update the calendar feed. Check your keyring and try again.'}


def configure():
    # Never accept the URL on argv, in env vars, or via an echoing stdin fallback.
    if not sys.stdin.isatty():
        raise FeedError('Run configure in an interactive terminal; the URL prompt is hidden.')
    with warnings.catch_warnings():
        warnings.simplefilter('error', getpass.GetPassWarning)
        try:
            url = getpass.getpass('Private HTTPS iCalendar URL (hidden): ')
        except (getpass.GetPassWarning, EOFError):
            raise FeedError('A hidden terminal prompt is required.') from None
    keyring('store', validate_url(url))
    print('Feed saved in your keyring. Enable iCalendar in Settings → Bar layout → Clock settings.')


def main():
    # Do not let this process leave a core file containing the feed URL or events.
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    parser = SafeArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='action', required=True)
    sub.add_parser('configure', help='Store/replace the private URL using a hidden terminal prompt')
    sub.add_parser('forget', help='Remove the stored feed URL from the keyring')
    sub.add_parser('manage', help='Private UI IPC over stdin')
    fetch = sub.add_parser('events', help='Read events as JSON (no URL argument)')
    fetch.add_argument('start')
    fetch.add_argument('end')
    args = parser.parse_args()
    if args.action == 'manage':
        print(json.dumps(manage(sys.stdin)))
        return 0
    if args.action == 'events':
        # Contain hostile or accidentally enormous recurrence rules in this child.
        for kind, budget in [(resource.RLIMIT_AS, 512 * 1024 * 1024), (resource.RLIMIT_CPU, 25)]:
            _, hard = resource.getrlimit(kind)
            cap = budget if hard == resource.RLIM_INFINITY else min(budget, hard)
            resource.setrlimit(kind, (cap, cap))
        signal.signal(signal.SIGALRM, lambda *_: sys.exit(1))
        signal.alarm(40)
        print(json.dumps(snapshot(args.start, args.end), ensure_ascii=True))
        return 0
    try:
        if args.action == 'configure':
            configure()
        else:
            keyring('forget')
            print('Feed URL removed. Turn off iCalendar to clear displayed events. Revocation is managed by the calendar provider.')
        return 0
    except FeedError as error:
        print(str(error), file=sys.stderr)
    except (Exception, KeyboardInterrupt):
        print('Calendar setup could not complete. Check your keyring and try again.', file=sys.stderr)
    return 1


if __name__ == '__main__':
    sys.exit(main())
