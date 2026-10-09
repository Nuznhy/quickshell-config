#!/usr/bin/env python3
"""Read-only labels for Hyprlock. Never reads keypresses or passwords."""
import json
import subprocess
import html
import os
import sqlite3
import sys
import time
import unicodedata
from datetime import datetime
from contextlib import closing
from pathlib import Path


def caps_status(devices):
    keyboards = devices.get('keyboards', [])
    keyboard = next((kb for kb in keyboards if kb.get('main')), None)
    if keyboard is None or not isinstance(keyboard.get('capsLock'), bool):
        return 'Caps Lock: unknown'
    return '<b>Caps Lock: ON</b>' if keyboard['capsLock'] else 'Caps Lock: off'


def safe_text(value, limit=32):
    # Pango markup, line breaks and bidi/control characters cannot alter the card.
    value = ' '.join(str(value).split())
    value = ''.join(c for c in value if not unicodedata.category(c).startswith('C'))
    width = sum(2 if unicodedata.east_asian_width(c) in ('W', 'F') else 1 for c in value)
    if width > limit:
        clipped, width = '', 0
        for char in value:
            width += 2 if unicodedata.east_asian_width(char) in ('W', 'F') else 1
            if width > limit - 1:
                break
            clipped += char
        value = clipped + '…'
    return html.escape(value)


def bus_call(*args):
    result = subprocess.run(['busctl', '--user', '--timeout=1', '--json=short',
                             'call', *args], capture_output=True, text=True,
                            timeout=2, check=True)
    return json.loads(result.stdout)['data'][0]


def unwrap(value):
    if isinstance(value, dict):
        if set(value) == {'type', 'data'}:
            return unwrap(value['data'])
        return {k: unwrap(v) for k, v in value.items()}
    if isinstance(value, list):
        return [unwrap(v) for v in value]
    return value


def media_label(players):
    player = next((p for p in players if p.get('PlaybackStatus') == 'Playing'), None)
    if player is None:
        player = next((p for p in players if p.get('PlaybackStatus') == 'Paused'
                       and p.get('Metadata', {}).get('xesam:title')), None)
    if player is None:
        return '<b>MEDIA</b>\nNothing playing'
    metadata = player.get('Metadata', {})
    title = safe_text(metadata.get('xesam:title') or 'Unknown track')
    artists = metadata.get('xesam:artist') or []
    artist = safe_text(' · '.join(artists) if isinstance(artists, list) else artists)
    heading = 'NOW PLAYING' if player['PlaybackStatus'] == 'Playing' else 'PAUSED'
    return f'<b>{heading}</b>\n{title}\n{artist or "Unknown artist"}'


def media_status():
    names = bus_call('org.freedesktop.DBus', '/org/freedesktop/DBus',
                     'org.freedesktop.DBus', 'ListNames')
    players = []
    for name in sorted(n for n in names if n.startswith('org.mpris.MediaPlayer2.'))[:8]:
        try:
            players.append(unwrap(bus_call(name, '/org/mpris/MediaPlayer2',
                                          'org.freedesktop.DBus.Properties', 'GetAll',
                                          's', 'org.mpris.MediaPlayer2.Player')))
        except (OSError, ValueError, KeyError, subprocess.SubprocessError):
            continue  # A disappearing player must not hide another active player.
    return media_label(players)


def rollout_status(path, now):
    # Bound work even when a conversation contains many megabytes of tool output.
    with path.open('rb') as stream:
        stream.seek(max(0, path.stat().st_size - 262144))
        lines = stream.read().splitlines()
    for line in reversed(lines):
        try:
            event = json.loads(line)
            if event.get('type') != 'event_msg':
                continue
            kind = event['payload'].get('type')
            state = {'task_complete': 'Completed', 'turn_aborted': 'Interrupted',
                     'task_started': 'Working', 'item_completed': 'Active recently'}.get(kind)
            if state is None:
                continue
            stamp = datetime.fromisoformat(event['timestamp'].replace('Z', '+00:00')).timestamp()
            age = max(0, now - stamp)
            if age > 86400:
                return None
            if state in ('Working', 'Active recently') and age > 120:
                state = 'Awaiting update'
            return stamp, state
        except (ValueError, KeyError, TypeError, AttributeError):
            continue
    return None


def codex_status(home=None, now=None):
    home = Path(home or os.environ.get('CODEX_HOME', str(Path.home() / '.codex')))
    now = time.time() if now is None else now
    databases = sorted(home.glob('state_*.sqlite'),
                       key=lambda p: int(p.stem.split('_')[-1]) if p.stem.split('_')[-1].isdigit() else -1)
    if not databases:
        return '<b>CODEX</b>\nNo local task data'
    # Local compatibility adapter, not a stable public Codex API. Read-only and
    # query only paths: prompts, replies, task titles and auth are never displayed.
    with closing(sqlite3.connect(databases[-1].resolve().as_uri() + '?mode=ro', uri=True, timeout=0.2)) as db:
        paths = db.execute('SELECT rollout_path FROM threads WHERE archived = 0 '
                           'ORDER BY updated_at DESC LIMIT 16').fetchall()
    states = []
    for (path,) in paths:
        try:
            state = rollout_status(Path(path), now)
            if state:
                states.append(state)
        except OSError:
            continue
    if not states:
        return '<b>CODEX</b>\nNo recent task activity'
    active = [s for s in states if s[1] in ('Working', 'Active recently')]
    stamp, state = max(active or states)
    age = max(0, int(now - stamp))
    elapsed = 'just now' if age < 60 else (f'{age // 60}m ago' if age < 3600 else f'{age // 3600}h ago')
    extra = f' · {len(active)} tasks' if len(active) > 1 else ''
    return f'<b>CODEX</b>\n{state}{extra} · {elapsed}'


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else 'caps'
    if mode != 'caps':
        try:
            if mode == 'media':
                print(media_status())
            elif mode == 'codex':
                print(codex_status())
            elif mode == 'date':
                print(safe_text(datetime.now().strftime('%A, %d %B')))
        except (OSError, ValueError, TypeError, AttributeError, KeyError,
                sqlite3.Error, subprocess.SubprocessError):
            print('<b>' + mode.upper() + '</b>\nStatus unavailable')
        return

    try:
        result = subprocess.run(['hyprctl', 'devices', '-j'], capture_output=True,
                                text=True, timeout=1, check=True)
        print(caps_status(json.loads(result.stdout)))
    except (OSError, ValueError, TypeError, AttributeError, subprocess.SubprocessError):
        print('Caps Lock: unknown')


if __name__ == '__main__':
    main()
