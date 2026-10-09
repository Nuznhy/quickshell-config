#!/usr/bin/env python3
"""Generate deterministic semantic light/dark palettes from a local wallpaper."""
import colorsys
from collections import defaultdict
import json
import math
from pathlib import Path
import subprocess
import sys
from urllib.parse import unquote, urlsplit

ROLES = ('bg', 'surface', 'overlay', 'muted', 'subtle', 'text', 'love', 'gold',
         'rose', 'pine', 'foam', 'iris', 'highlightLow', 'highlightMed', 'highlightHigh')


def luminance(rgb):
    return sum(w * (c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4)
               for c, w in zip(rgb, (.2126, .7152, .0722)))


def contrast(a, b):
    x, y = sorted((luminance(a), luminance(b)))
    return (y + .05) / (x + .05)


def hexcolor(rgb):
    return '#' + ''.join(f'{round(max(0, min(1, c)) * 255):02x}' for c in rgb)


def readable(hue, saturation, lightness, surfaces, dark):
    for _ in range(101):
        rgb = colorsys.hls_to_rgb(hue % 1, lightness, saturation)
        # Check the actual rounded output, not only floating-point colors.
        rounded = tuple(round(c * 255) / 255 for c in rgb)
        if min(contrast(rounded, surface) for surface in surfaces) >= 4.5:
            return hexcolor(rgb)
        lightness = min(1, lightness + .01) if dark else max(0, lightness - .01)
    return '#ffffff' if dark else '#000000'


def extract(pixels, method):
    histogram = defaultdict(float)
    average = [0., 0., 0.]
    total = 0.
    for r, g, b, a in zip(*[iter(pixels)] * 4):
        weight = a / 255
        if not weight:
            continue
        total += weight
        for i, value in enumerate((r, g, b)):
            average[i] += value / 255 * weight
        histogram[(r // 16, g // 16, b // 16)] += weight
    if not total:
        raise ValueError('The wallpaper is fully transparent. Choose another image.')
    if method == 'average':
        return tuple(c / total for c in average)
    def rgb(bucket):
        return tuple((c * 16 + 7.5) / 255 for c in bucket)
    def score(bucket):
        if method == 'dominant':
            return histogram[bucket]
        _, light, sat = colorsys.rgb_to_hls(*rgb(bucket))
        return math.sqrt(histogram[bucket]) * (.02 + sat ** 2) * (.2 + 4 * light * (1 - light))
    winner = max(sorted(histogram), key=score)
    return rgb(winner)


def palettes(seed, variant):
    hue, _, saturation = colorsys.rgb_to_hls(*seed)
    gray = saturation < .08
    tint, accent = {'neutral': (.025, .40), 'tonal': (.13, .55), 'vivid': (.26, .75)}[variant]
    if gray:
        tint = accent = 0
    result = {}
    for mode in ('dark', 'light'):
        dark = mode == 'dark'
        levels = (.085, .12, .16) if dark else (.98, .95, .91)
        surfaces = [colorsys.hls_to_rgb(hue, light, tint) for light in levels]
        surfaces = [tuple(round(c * 255) / 255 for c in rgb) for rgb in surfaces]
        p = dict(zip(('bg', 'surface', 'overlay'), map(hexcolor, surfaces)))
        for role, light in zip(('muted', 'subtle', 'text'), (.62, .73, .92) if dark else (.42, .32, .16)):
            p[role] = readable(hue, tint, light, surfaces, dark)
        # Semantic danger/warning remain recognizable across source images.
        for role, h, s in [('love', .98, .65), ('gold', .12, .70),
                           ('rose', hue + .08, accent), ('pine', hue - .12, accent),
                           ('foam', hue + .16, accent), ('iris', hue, accent)]:
            p[role] = readable(h, s, .68 if dark else .38, surfaces, dark)
        for role, light in zip(('highlightLow', 'highlightMed', 'highlightHigh'),
                               (.19, .25, .32) if dark else (.87, .81, .74)):
            p[role] = hexcolor(colorsys.hls_to_rgb(hue, light, tint))
        result[mode] = p
    return result


def generate(request):
    method, variant = request.get('method', 'dominant'), request.get('variant', 'tonal')
    if method not in ('dominant', 'vibrant', 'average') or variant not in ('neutral', 'tonal', 'vivid'):
        raise ValueError('Unknown extraction method or color variant.')
    url = urlsplit(request['source'])
    if url.scheme != 'file' or url.netloc or url.query or url.fragment:
        raise ValueError('Choose a local wallpaper first.')
    path = Path(unquote(url.path))
    if not path.is_file():
        raise ValueError('The wallpaper is missing or unreadable.')
    # Explicit argument list; fixed output size and bounded decoder resources.
    command = ['magick', '-limit', 'memory', '128MiB', '-limit', 'map', '256MiB',
               '-limit', 'disk', '256MiB', '-limit', 'time', '10', str(path) + '[0]',
               '-auto-orient', '-thumbnail', '64x64!', '-colorspace', 'sRGB', '-depth', '8', 'rgba:-']
    try:
        process = subprocess.run(command, capture_output=True, timeout=15, check=True)
    except FileNotFoundError:
        raise ValueError('Install ImageMagick to generate wallpaper themes.') from None
    except subprocess.TimeoutExpired:
        raise ValueError('Wallpaper decoding timed out. Try a smaller image.') from None
    except subprocess.CalledProcessError:
        raise ValueError('Could not decode this wallpaper. Try another image.') from None
    if len(process.stdout) != 64 * 64 * 4:
        raise ValueError('Could not read wallpaper pixels.')
    return palettes(extract(process.stdout, method), variant)


if __name__ == '__main__':
    try:
        print(json.dumps({'palettes': generate(json.load(sys.stdin))}))
    except (ValueError, KeyError, TypeError, OSError) as error:
        print(json.dumps({'error': str(error)}))
        sys.exit(1)
