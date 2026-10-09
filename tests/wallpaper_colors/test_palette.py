import importlib.util
import itertools
import re
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('palette', ROOT / 'scripts/wallpaper-palette.py')
palette = importlib.util.module_from_spec(spec)
spec.loader.exec_module(palette)


def rgb(value):
    return tuple(int(value[i:i + 2], 16) / 255 for i in (1, 3, 5))


class PaletteTests(unittest.TestCase):
    def test_methods_choose_different_seeds(self):
        pixels = bytes([100, 110, 120, 255] * 100 + [240, 30, 60, 255] * 30)
        seeds = [palette.extract(pixels, method) for method in ('dominant', 'vibrant', 'average')]
        self.assertEqual(len(set(seeds)), 3)
        self.assertEqual(seeds, [palette.extract(pixels, method) for method in ('dominant', 'vibrant', 'average')])

    def test_variants_roles_and_contrast(self):
        for seed in [(1, 0, 0), (0, 1, 0), (0, 0, 1), (.4, .4, .4), (0, 0, 0), (1, 1, 1), (.9, .8, .1)]:
            for variant in ('neutral', 'tonal', 'vivid'):
                for mode, colors in palette.palettes(seed, variant).items():
                    self.assertEqual(set(colors), set(palette.ROLES))
                    self.assertTrue(all(re.fullmatch('#[0-9a-f]{6}', c) for c in colors.values()))
                    for foreground, background in itertools.product(
                            ('text', 'subtle', 'muted', 'love', 'gold', 'rose', 'pine', 'foam', 'iris'),
                            ('bg', 'surface', 'overlay')):
                        self.assertGreaterEqual(palette.contrast(rgb(colors[foreground]), rgb(colors[background])), 4.5)
        variants = [palette.palettes((.8, .2, .4), v) for v in ('neutral', 'tonal', 'vivid')]
        self.assertNotEqual(variants[0], variants[1])
        self.assertNotEqual(variants[1], variants[2])

    def test_transparency_and_grayscale(self):
        self.assertEqual(palette.extract(bytes([255, 0, 0, 0, 0, 255, 0, 255]), 'average'), (0, 1, 0))
        with self.assertRaisesRegex(ValueError, 'transparent'):
            palette.extract(bytes([255, 0, 0, 0]), 'dominant')
        colors = palette.palettes((.5, .5, .5), 'vivid')['dark']
        self.assertEqual(len(set(rgb(colors['iris']))), 1)

    def test_decoder_and_errors(self):
        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / 'wall paper.svg'
            image.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8"><rect width="8" height="8" fill="#0088aa"/></svg>')
            request = dict(source=image.as_uri(), method='dominant', variant='tonal')
            self.assertEqual(set(palette.generate(request)), {'dark', 'light'})
            with patch.object(palette.subprocess, 'run', side_effect=FileNotFoundError):
                with self.assertRaisesRegex(ValueError, 'Install ImageMagick'):
                    palette.generate(request)
            image.write_text('not an image')
            with self.assertRaisesRegex(ValueError, 'decode'):
                palette.generate(request)
            image.unlink()
            with self.assertRaisesRegex(ValueError, 'missing'):
                palette.generate(request)
        with self.assertRaises(ValueError):
            palette.generate(dict(source='https://example.com/wall.png'))
