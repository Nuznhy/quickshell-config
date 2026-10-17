#!/usr/bin/env python3
"""Temporarily mirror laptop displays, or restore Hyprland's saved config."""
import argparse
import json
import re
import subprocess
import time


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


def internal(monitor):
    return bool(re.match(r'^(eDP|LVDS|DSI)-?\d', monitor['name'], re.I))


def mirrors(monitor, laptop):
    # Hyprland reports the source ID (including zero), not always its name.
    source = monitor.get('mirrorOf', 'none')
    return str(source) in (str(laptop['id']), laptop['name'])


def status(outputs):
    laptops = [m for m in outputs if internal(m) and not m.get('disabled', False)]
    external = [m for m in outputs if not internal(m) and not m.get('disabled', False)]
    laptop = laptops[0] if len(laptops) == 1 else None
    mirrored = bool(laptop and any(mirrors(m, laptop) for m in external))
    reason = ''
    if not laptop:
        reason = 'One active laptop display is required.'
    elif not external:
        reason = 'Connect an external monitor to duplicate the laptop screen.'
    elif not laptop.get('dpmsStatus', True) and not mirrored:
        reason = 'Turn on the laptop display before duplicating it.'
    elif laptop.get('mirrorOf', 'none') not in ('none', None, -1, '-1'):
        reason = 'The laptop display is already mirroring another output.'
    return dict(available=not reason, mirrored=mirrored,
                laptop=laptop['name'] if laptop else '',
                outputs=[m['name'] for m in external], reason=reason, error='')


def mirror_command(output, laptop):
    # Connector names are interpolated into Lua, never into a shell command.
    for name in (output['name'], laptop):
        if not re.fullmatch(r'[A-Za-z0-9_.:-]+', name):
            raise ValueError('Unsupported monitor connector name.')
    return ('hl.monitor({ output = "%s", mode = "preferred", position = "auto", '
            'scale = "auto", mirror = "%s" })') % (output['name'], laptop)


def change(*args):
    reply = ipc(*args)
    if reply.lower() != 'ok':
        raise RuntimeError(reply or 'Hyprland did not acknowledge the display change.')


def toggle(outputs):
    current = status(outputs)
    if not current['available']:
        raise RuntimeError(current['reason'])
    if current['mirrored']:
        # Re-evaluate the user's own Lua rules, including mode, placement,
        # bitdepth, color settings and any changes made while mirroring.
        change('reload')
    else:
        commands = [mirror_command(m, current['laptop']) for m in outputs
                    if m['name'] in current['outputs']]
        try:
            change('eval', '; '.join(commands))
            for _ in range(15):
                time.sleep(0.1)
                actual = monitors()
                laptop = next((m for m in actual if m['name'] == current['laptop']), None)
                targets = [m for m in actual if m['name'] in current['outputs']]
                if (laptop and len(targets) == len(commands)
                        and all(mirrors(m, laptop) for m in targets)):
                    return actual
            raise RuntimeError('Hyprland did not enable mirroring on every external monitor.')
        except (RuntimeError, ValueError, OSError, subprocess.SubprocessError) as error:
            try:
                change('reload')
            except (RuntimeError, OSError, subprocess.SubprocessError) as restore_error:
                raise RuntimeError(f'{error} Restore also failed: {restore_error}') from error
            raise RuntimeError(f'{error} Reloaded your configured layout.') from error
    time.sleep(0.3)
    actual = monitors()
    errors = ipc('configerrors')
    if errors:
        raise RuntimeError(f'Hyprland configuration errors: {errors}')
    return actual


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['status', 'toggle'], default='status', nargs='?')
    args = parser.parse_args()
    result = dict(available=False, mirrored=False, laptop='', outputs=[], reason='', error='')
    try:
        outputs = monitors()
        result = status(outputs)
        if args.action == 'toggle':
            result = status(toggle(outputs))
    except (RuntimeError, ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        result['error'] = str(error)
        # Do not leave the icon claiming success after a partial change.
        try:
            result.update(status(monitors()), error=str(error))
        except (RuntimeError, ValueError, KeyError, OSError, subprocess.SubprocessError):
            result['available'] = False
    print(json.dumps(result))


if __name__ == '__main__':
    main()
