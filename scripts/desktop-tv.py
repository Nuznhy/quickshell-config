#!/usr/bin/env python3
"""Report or toggle the Desktop / TV layout managed by Hyprland Lua."""
import argparse
import json
import subprocess
import time

DESKTOP = 'DP-1'
MICRO = 'DP-2'
TV = 'HDMI-A-1'


def ipc(*args):
    result = subprocess.run(['hyprctl', *args], capture_output=True, text=True, timeout=5)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or 'Hyprland is unavailable.')
    return result.stdout.strip()


def monitors():
    result = json.loads(ipc('-j', 'monitors', 'all'))
    if not isinstance(result, list):
        raise ValueError('Invalid monitor response.')
    return result


def status(outputs):
    active = {m['name'] for m in outputs if not m.get('disabled', False)}
    desktop = DESKTOP in active
    tv = TV in active
    if desktop and not tv:
        mode, reason = 'desktop', ''
    elif tv and not desktop and MICRO not in active:
        mode, reason = 'tv', ''
    elif desktop or tv or MICRO in active:
        mode, reason = 'transition', 'Display layout is changing.'
    else:
        mode, reason = 'unavailable', 'No configured main display is active.'
    return dict(mode=mode, available=mode in ('desktop', 'tv'),
                pending=False, reason=reason, error='')


def pending_confirmation():
    return ipc('repl', 'tostring(require("config.monitors").pending_confirmation)') == 'true'


def observe(outputs=None):
    result = status(monitors() if outputs is None else outputs)
    if result['mode'] == 'tv':
        result['pending'] = pending_confirmation()
    return result


def toggle(outputs):
    before = status(outputs)
    if not before['available']:
        raise RuntimeError(before['reason'])
    target = 'tv' if before['mode'] == 'desktop' else 'desktop'
    reply = ipc('eval', 'require("config.monitors").toggleMons()')
    if reply.lower() != 'ok':
        raise RuntimeError(reply or 'Hyprland rejected the display switch.')
    stable = 0
    for _ in range(145):
        time.sleep(0.1)
        actual = monitors()
        state = status(actual)
        if state['mode'] == target:
            stable += 1
            if stable == 3:
                return actual
        else:
            stable = 0
    try:
        detail = ipc('repl', 'require("config.monitors").last_error')
    except (RuntimeError, OSError, subprocess.SubprocessError):
        detail = ''
    if detail:
        raise RuntimeError(f'Display switch failed: {detail}')
    raise RuntimeError('Display switch did not complete; check the Hyprland notification.')


def confirm():
    if not pending_confirmation():
        raise RuntimeError('TV is not awaiting confirmation.')
    reply = ipc('eval', 'require("config.monitors").confirmTv()')
    if reply.lower() != 'ok':
        raise RuntimeError(reply or 'Hyprland rejected TV confirmation.')
    actual = monitors()
    if status(actual)['mode'] != 'tv' or pending_confirmation():
        raise RuntimeError('TV confirmation did not complete.')
    return actual


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['status', 'toggle', 'confirm'],
                        default='status', nargs='?')
    args = parser.parse_args()
    result = dict(mode='unavailable', available=False, pending=False, reason='', error='')
    try:
        outputs = monitors()
        result = observe(outputs)
        if args.action == 'toggle':
            result = observe(toggle(outputs))
        elif args.action == 'confirm':
            result = observe(confirm())
    except (RuntimeError, ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        try:
            result = observe()
        except (RuntimeError, ValueError, KeyError, OSError, subprocess.SubprocessError):
            result['available'] = False
        result['error'] = str(error)
    print(json.dumps(result))


if __name__ == '__main__':
    main()
