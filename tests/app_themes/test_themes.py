import configparser
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
import app_theme_formats as formats
spec = importlib.util.spec_from_file_location('app_themes', ROOT / 'scripts/app-themes.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def palettes():
    source = (ROOT / 'config/Palettes.js').read_text()
    for colors in re.findall(r'(?:dark|light):\s*(\[[^\]]+\])', source):
        yield dict(zip(formats.ROLES, json.loads(colors)))


class ThemeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.config = self.home / '.config'
        self.data = self.home / '.local/share'
        self.state = self.home / 'state'
        self.commands = []
        self.settings = {'color-scheme': "'default'", 'gtk-theme': "'Adwaita'"}
        self.engine = module.Themes(self.state, self.home, self.config, self.data, self.run_command, lambda cmd: '/bin/' + cmd)
        self.engine.available = lambda target: (True, '')
        self.palette = next(palettes())
        self.env = patch.dict(os.environ, {'QT_QPA_PLATFORMTHEME': 'kde', 'VENCORD_USER_DATA_DIR': ''}, clear=False)
        self.env.start()
        self.addCleanup(self.env.stop)

    def run_command(self, args):
        self.commands.append(args)
        if args[:2] == ['gsettings', 'get']:
            return self.settings[args[3]]
        if args[:2] == ['gsettings', 'set']:
            self.settings[args[3]] = args[4]
        return ''

    def put(self, relative, text):
        path = self.config / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def apply(self, target, enabled=True, palette=None, action='set'):
        return self.engine.handle(dict(action=action, target=target, enabled=enabled,
                                       palette=palette or self.palette, mode='dark'))

    def status(self, result, target):
        return next(t for t in result['targets'] if t['id'] == target)

    def test_all_renderers_all_palettes(self):
        count = 0
        for p in palettes():
            count += 1
            for mode in ('light', 'dark'):
                formats.validate(p, mode)
                css = formats.zen(p, mode)
                self.assertIn(f'color-scheme: {mode} !important;', css)
                self.assertIn(f'--zen-main-browser-background: {p["bg"]} !important;', css)
                self.assertIn(f'--zen-primary-color: {p["iris"]} !important;', css)
                self.assertEqual(css.count('{'), css.count('}'))
            for text in [formats.qt(p), formats.ini(formats.kde(p)), formats.spotify(p), formats.terminal(p, 'foot')]:
                parser = configparser.RawConfigParser()
                parser.read_string(text)
                self.assertTrue(parser.sections())
                self.assertNotIn('{{', text)
            flavor, syntax = formats.yazi(p)
            self.assertIn('mgr', tomllib.loads(flavor))
            self.assertIn('settings', plistlib.loads(syntax.encode()))
            self.assertEqual(len(formats.ansi(p)), 16)
            self.assertIn(p['bg'], formats.terminal(p, 'ghostty'))
            self.assertIn(p['iris'], formats.discord(p))
            self.assertIn(p['bg'], formats.btop(p))
        self.assertEqual(count, 12)

    def test_discovery_is_read_only_all_off(self):
        before = list(self.home.rglob('*'))
        status = self.engine.handle({'action': 'discover'})
        self.assertTrue(all(not t['enabled'] for t in status['targets']))
        self.assertEqual(before, list(self.home.rglob('*')))
        self.assertEqual(self.commands, [])

    def test_hyprland_override_and_restore(self):
        for extension in ('lua', 'conf'):
            with self.subTest(extension=extension):
                original = '-- original appearance\n' if extension == 'lua' else '# original appearance\n'
                path = self.put('hypr/hyprland.' + extension, original)
                with patch.dict(os.environ, {'HYPRLAND_INSTANCE_SIGNATURE': 'test'}):
                    result = self.apply('hyprland')
                    self.assertEqual(self.status(result, 'hyprland')['state'], 'applied')
                    generated = path.with_name('quickshell-appearance.' + extension)
                    self.assertTrue(path.read_text().startswith(original))
                    self.assertEqual(path.read_text().count('quickshell-appearance-override'), 1)
                    self.assertNotIn('active_border', generated.read_text())
                    changed = dict(self.palette, iris='#123456')
                    self.apply('hyprland', palette=changed)
                    self.assertNotIn('123456', generated.read_text())
                    self.assertEqual(path.read_text().count('quickshell-appearance-override'), 1)
                    # User changes outside the managed import survive disabling.
                    extra = '-- new user setting\n' if extension == 'lua' else '# new user setting\n'
                    path.write_text(path.read_text() + extra)
                    self.assertEqual(self.status(self.apply('hyprland', False), 'hyprland')['state'], 'off')
                    self.assertEqual(path.read_text(), original + extra)
                    self.assertFalse(generated.exists())
                    self.assertIn(['hyprctl', 'reload'], self.commands)
                path.unlink()

    def test_hyprland_toggles_restore_independently(self):
        for extension in ('lua', 'conf'):
            for first in ('hyprland', 'hyprland-colors'):
                with self.subTest(extension=extension, first=first):
                    path = self.put('hypr/hyprland.' + extension, '-- original\n' if extension == 'lua' else '# original\n')
                    original = path.read_text()
                    for target in ('hyprland', 'hyprland-colors'):
                        self.assertEqual(self.status(self.apply(target), target)['state'], 'applied')
                    appearance = path.with_name('quickshell-appearance.' + extension)
                    colors = path.with_name('quickshell-colors.' + extension)
                    self.assertNotIn('active_border', appearance.read_text())
                    self.assertNotIn('color =', appearance.read_text())
                    self.assertNotIn('shadow', appearance.read_text())
                    self.assertNotIn('shadow', colors.read_text())
                    self.assertNotIn('rounding', colors.read_text())
                    self.assertNotIn('enabled =', colors.read_text())
                    self.assertIn(self.palette['iris'][1:], colors.read_text())
                    self.apply(first, False)
                    other = 'hyprland-colors' if first == 'hyprland' else 'hyprland'
                    remaining = colors if first == 'hyprland' else appearance
                    self.assertTrue(remaining.exists())
                    self.assertIn(other, self.engine.state['enabled'])
                    self.apply(other, False)
                    self.assertEqual(path.read_text(), original)
                    self.assertFalse(appearance.exists())
                    self.assertFalse(colors.exists())
                    path.unlink()

    def test_hyprland_combined_opt_in_migrates_without_losing_restore(self):
        path = self.put('hypr/hyprland.lua', '-- original\n')
        self.apply('hyprland')
        generated = path.with_name('quickshell-appearance.lua')
        # Simulate the previous combined override and its recovery journal.
        self.engine.current = 'hyprland'
        self.engine.generated(generated, formats.hyprland(self.palette, True) + formats.hyprland_colors(self.palette, True))
        self.engine.state.pop('hyprland_split')
        self.engine.save()
        self.engine = module.Themes(self.state, self.home, self.config, self.data, self.run_command, lambda cmd: '/bin/' + cmd)
        self.engine.available = lambda target: (True, '')
        result = self.engine.handle({'action': 'discover'})
        self.assertTrue(self.status(result, 'hyprland')['enabled'])
        self.assertTrue(self.status(result, 'hyprland-colors')['enabled'])
        self.assertIn('active_border', generated.read_text())  # Read-only discovery.
        self.apply('hyprland', action='sync')
        self.assertNotIn('active_border', generated.read_text())
        self.assertTrue(path.with_name('quickshell-colors.lua').exists())
        self.apply('hyprland-colors', False)
        self.assertTrue(generated.exists())
        self.apply('hyprland', False)
        self.assertEqual(path.read_text(), '-- original\n')

    def test_hyprland_discovery_and_conflicts(self):
        self.assertFalse(module.Themes.available(self.engine, 'hyprland')[0])
        path = self.put('hypr/hyprland.lua', '-- user config\n')
        target = self.home / 'hyprland.lua'
        path.rename(target)
        path.symlink_to(target)
        self.assertTrue(module.Themes.available(self.engine, 'hyprland')[0])
        self.apply('hyprland')
        self.assertTrue(path.is_symlink())
        generated = path.with_name('quickshell-appearance.lua')
        generated.write_text('-- manually edited\n')
        result = self.apply('hyprland', action='retry')
        self.assertEqual(self.status(result, 'hyprland')['state'], 'error')
        self.assertEqual(generated.read_text(), '-- manually edited\n')

    def test_hyprland_bar_appearance_mapping_and_validation(self):
        appearance = dict(radius=18, opacity=0.7, verticalGap=10, horizontalGap=24, innerGap=8, borderWidth=1)
        for lua in (True, False):
            rendered = formats.hyprland(self.palette, lua, appearance)
            self.assertIn('rounding = 18', rendered)
            self.assertIn('active_opacity = 0.7', rendered)
            self.assertIn('inactive_opacity = 0.7', rendered)
            self.assertIn('border_size = 1', rendered)
            self.assertIn('top = 10' if lua else 'gaps_out = 10, 24, 10, 24', rendered)
        for bad in [dict(radius=-1), dict(opacity=float('nan')), dict(horizontalGap='injected'), dict(borderWidth=True)]:
            with self.assertRaises(ValueError):
                formats.hyprland(self.palette, True, dict(appearance, **bad))

    def test_hyprland_reload_failure_can_restore(self):
        path = self.put('hypr/hyprland.lua', '-- user config\n')
        with patch.dict(os.environ, {'HYPRLAND_INSTANCE_SIGNATURE': 'test'}):
            self.engine.run = lambda args: 'test config error' if args[-1] == 'configerrors' else ''
            result = self.apply('hyprland')
            self.assertIn('test config error', self.status(result, 'hyprland')['message'])
            self.engine.run = self.run_command
            self.assertEqual(self.status(self.apply('hyprland', False), 'hyprland')['state'], 'off')
            self.assertEqual(path.read_text(), '-- user config\n')

    @unittest.skipUnless(shutil.which('lua'), 'Lua interpreter not installed')
    def test_hyprland_lua_all_palettes(self):
        for palette in palettes():
            source = 'hl = {config = function(c) assert(c.general.gaps_in == 8); assert(c.decoration.rounding == 0) end}\n'
            subprocess.run(['lua', '-'], input=source + formats.hyprland(palette, True), text=True, check=True)

    def test_hyprlock_palettes_warnings_and_restore_symlink(self):
        original = '# original lock screen\nbackground {\n color = rgb(123456)\n}\n'
        path = self.put('hypr/hyprlock.conf', original)
        real = self.home / 'lock-dotfile'
        path.rename(real)
        path.symlink_to(real)
        self.assertEqual(self.status(self.apply('hyprlock'), 'hyprlock')['state'], 'applied')
        for palette in palettes():
            self.engine.handle(dict(action='sync', palette=palette, mode='light'))
            text = path.read_text()
            self.assertIn('color = rgb(' + palette['bg'][1:] + ')', text)
            self.assertIn('capslock_color = rgb(' + palette['gold'][1:] + ')', text)
            self.assertIn('bothlock_color = rgb(' + palette['gold'][1:] + ')', text)
            self.assertIn('text = Keyboard layout: $LAYOUT\n', text)
            self.assertIn('fade_on_empty = false', text)
            self.assertIn('text = cmd[update:500] python3 ', text)
            self.assertNotIn('$LAYOUT[!]', text)
            self.assertTrue(path.is_symlink())
        self.assertEqual(self.status(self.apply('hyprlock', False), 'hyprlock')['state'], 'off')
        self.assertEqual(real.read_text(), original)
        self.assertEqual(self.commands, [])

    def test_hyprlock_background_options_and_invalid_paths(self):
        self.apply('hyprlock')
        path = self.config / 'hypr/hyprlock.conf'
        def sync(options):
            return self.engine.handle(dict(action='sync', palette=self.palette, mode='dark', lockScreen=options))
        sync({'background': 'color', 'color': '#abcdef'})
        self.assertIn('color = rgb(abcdef)', path.read_text())
        image = self.put('pictures/lock screen.png', 'image fixture')
        sync({'background': 'image', 'image': image.as_uri()})
        self.assertIn('path = ' + str(image), path.read_text())
        good = path.read_text()
        for options in [{'background': 'bad'}, {'background': 'color', 'color': '#123\nsource = evil'},
                        {'background': 'image', 'image': 'https://example.com/a.png'},
                        {'background': 'image', 'image': (image.parent / 'missing.png').as_uri()}]:
            result = sync(options)
            self.assertEqual(self.status(result, 'hyprlock')['state'], 'error')
            self.assertEqual(path.read_text(), good)
        for name in ['line\nbreak.png', '$TIME.png', 'comment#.png', 'braces{.png']:
            bad = self.put('pictures/' + name, 'fixture')
            result = sync({'background': 'image', 'image': bad.as_uri()})
            self.assertEqual(self.status(result, 'hyprlock')['state'], 'error')
            self.assertEqual(path.read_text(), good)
        sync({'background': 'theme'})
        self.assertIn('    path = \n', path.read_text())
        self.assertNotIn(str(image), path.read_text())

    def test_hyprlock_manual_edits_preserved(self):
        path = self.put('hypr/hyprlock.conf', '# before\n')
        self.apply('hyprlock')
        path.write_text('# manual edit\n')
        result = self.apply('hyprlock', False)
        self.assertEqual(self.status(result, 'hyprlock')['state'], 'error')
        self.assertEqual(path.read_text(), '# manual edit\n')

    def test_hyprlock_caps_status(self):
        spec = importlib.util.spec_from_file_location('lock_status', ROOT / 'scripts/hyprlock-status.py')
        status = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(status)
        self.assertEqual(status.caps_status({'keyboards': []}), 'Caps Lock: unknown')
        self.assertEqual(status.caps_status({'keyboards': [{'main': True}]}), 'Caps Lock: unknown')
        for enabled, expected in [(True, '<b>Caps Lock: ON</b>'), (False, 'Caps Lock: off')]:
            self.assertEqual(status.caps_status({'keyboards': [
                {'main': False, 'capsLock': not enabled}, {'main': True, 'capsLock': enabled}]}), expected)

    def test_rofi_roundtrip_sync_preserves_config_and_symlink(self):
        original = '@theme "default"\n* { font: "monospace 14"; }\nwindow { width: 700px; }\n'
        path = self.put('rofi/config.rasi', original)
        real = self.home / 'rofi-dotfile'
        path.rename(real)
        path.symlink_to(real)
        self.assertEqual(self.status(self.apply('rofi'), 'rofi')['state'], 'applied')
        generated = self.config / 'rofi/quickshell-config.rasi'
        self.assertIn(self.palette['bg'], generated.read_text())
        next_palette = list(palettes())[1]
        self.engine.handle(dict(action='sync', palette=next_palette, mode='light'))
        self.assertIn(next_palette['bg'], generated.read_text())
        self.assertEqual(path.read_text(), original + '@import "quickshell-config.rasi"\n')
        path.write_text(path.read_text() + 'listview { lines: 8; }\n')
        # Recovery must survive restarting the worker or uninstalling rofi.
        self.engine = module.Themes(self.state, self.home, self.config, self.data, self.run_command, lambda _: None)
        self.assertEqual(self.status(self.apply('rofi', False), 'rofi')['state'], 'off')
        self.assertTrue(path.is_symlink())
        self.assertEqual(path.read_text(), original + 'listview { lines: 8; }\n')
        self.assertFalse(generated.exists())
        self.assertEqual(self.commands, [])

    def test_rofi_manual_generated_edits_are_preserved(self):
        self.apply('rofi')
        generated = self.config / 'rofi/quickshell-config.rasi'
        generated.write_text('/* personal theme */\n')
        self.assertEqual(self.status(self.apply('rofi', False), 'rofi')['state'], 'error')
        self.assertEqual(generated.read_text(), '/* personal theme */\n')

    @unittest.skipUnless(shutil.which('rofi'), 'rofi is not installed')
    def test_rofi_native_parser_all_palettes_and_layout_preservation(self):
        path = self.put('rofi/config.rasi', '@theme "default"\n'
                        '* { font: "monospace 14"; }\nwindow { width: 700px; }\n'
                        'element selected.normal { text-color: #123456; }\n')
        for palette in palettes():
            self.apply('rofi', palette=palette)
            result = subprocess.run(['rofi', '-config', str(path), '-dump-theme'],
                                    capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn('Error', result.stderr)
            self.assertRegex(result.stdout, r'width:\s+700px\s*;')
            self.assertIn('"monospace 14"', result.stdout)
            selected = re.search(r'element selected\.normal\s*\{([^}]+)', result.stdout)[1]
            # Rofi serializes colors as rgba() or a standard color name.
            for prop, color in [('background-color', palette['iris']),
                                ('text-color', formats.on_color(palette['iris']))]:
                r, g, b = formats.rgb(color)
                color_pattern = rf'rgba\s*\(\s*{r},\s*{g},\s*{b},\s*100 %\s*\)'
                if color in ('#000000', '#ffffff'):
                    color_pattern = '(?:' + color_pattern + '|' + ('Black' if r == 0 else 'White') + ')'
                self.assertRegex(selected, rf'{prop}:\s+{color_pattern}')

    def test_ghostty_roundtrip_preserves_other_edits_and_symlink(self):
        original = '# personal\nfont-size = 15\ntheme = noctalia\n'
        path = self.put('ghostty/config', original)
        real = self.home / 'dotfiles/ghostty-config'
        real.parent.mkdir()
        path.rename(real)
        path.symlink_to(real)
        self.assertEqual(self.status(self.apply('ghostty'), 'ghostty')['state'], 'applied')
        self.apply('ghostty', palette=list(palettes())[2])
        real.write_text(real.read_text().replace('font-size = 15', 'font-size = 18'))
        self.apply('ghostty', False)
        self.assertTrue(path.is_symlink())
        self.assertEqual(path.read_text(), original.replace('15', '18'))
        self.assertFalse((self.config / 'ghostty/themes/quickshell-config').exists())

    def test_manual_theme_edit_conflict_keeps_file(self):
        path = self.put('ghostty/config', 'theme=old\n')
        self.apply('ghostty')
        path.write_text('theme=manual\n')
        result = self.apply('ghostty', False)
        self.assertEqual(path.read_text(), 'theme=manual\n')
        self.assertEqual(self.status(result, 'ghostty')['state'], 'error')
        self.assertTrue((self.config / 'ghostty/themes/quickshell-config').exists())

    def test_gtk_import_and_desktop_preferences_restore(self):
        path = self.put('gtk-3.0/gtk.css', '@import url("noctalia.css");\n/* mine */\n')
        shell = self.home / '.zshrc'
        shell.write_text('export EDITOR=nvim\nexport GTK_THEME="Adwaita:dark"\n')
        self.apply('gtk')
        self.assertIn('quickshell-config.css', path.read_text())
        self.assertNotIn('GTK_THEME', shell.read_text())
        self.assertEqual(self.settings['color-scheme'], "'prefer-dark'")
        self.apply('gtk', False)
        self.assertEqual(path.read_text(), '@import url("noctalia.css");\n/* mine */\n')
        self.assertIn('GTK_THEME="Adwaita:dark"', shell.read_text())
        self.assertEqual(self.settings['color-scheme'], "'default'")

    def test_kde_fields_and_session_setup_restore(self):
        path = self.put('kdeglobals', '[General]\nColorScheme=Before\nfont=custom\n')
        env = self.put('hypr/config/env.lua', 'hl.env("QT_STYLE_OVERRIDE", "kvantum")\nhl.env("TEST", "1")\n')
        result = self.apply('qt')
        self.assertEqual(self.status(result, 'qt')['state'], 'restart')
        self.assertIn('Fusion', env.read_text())
        self.assertIn('ColorScheme=quickshell-config', path.read_text())
        self.apply('qt', False)
        self.assertIn('ColorScheme=Before', path.read_text())
        self.assertIn('font=custom', path.read_text())
        self.assertEqual(env.read_text(), 'hl.env("QT_STYLE_OVERRIDE", "kvantum")\nhl.env("TEST", "1")\n')

    def test_gtk_reconciles_reinserted_imports_and_restores_original(self):
        old = '@import url("noctalia.css");\n'
        managed = '@import url("quickshell-config.css");\n'
        custom = '/* custom */\nbutton { border-radius: 7px; }\n'
        paths = [self.put(f'gtk-{version}/gtk.css', old + custom) for version in ('3.0', '4.0')]
        self.apply('gtk')
        # Reproduce the saved-journal conflict seen in both installed gtk.css files.
        for path in paths:
            path.write_text(managed + old + managed + custom)
        result = self.apply('gtk', palette=list(palettes())[1])
        self.assertEqual(self.status(result, 'gtk')['state'], 'restart')
        for path in paths:
            self.assertEqual(path.read_text(), managed + custom)
            self.assertIn(list(palettes())[1]['bg'], path.with_name('quickshell-config.css').read_text())
        self.apply('gtk', False)
        for path in paths:
            self.assertEqual(path.read_text(), old + custom)

    def test_gtk_reconciliation_rejects_unknown_import_edits(self):
        path = self.put('gtk-3.0/gtk.css', '@import url("noctalia.css");\n')
        self.apply('gtk')
        edited = '@import url("quickshell-config.css"); /* keep this edit */\n'
        path.write_text(edited)
        self.assertEqual(self.status(self.apply('gtk'), 'gtk')['state'], 'error')
        self.assertEqual(path.read_text(), edited)

    def test_all_other_targets_restore(self):
        originals = {
            'foot/foot.ini': 'include=~/.config/foot/themes/noctalia\nfont=monospace\n',
            'yazi/theme.toml': '[flavor]\ndark="noctalia"\nlight="noctalia"\n',
            'btop/btop.conf': '# example\ncolor_theme = "noctalia"\nupdate_ms=1000\n',
            'hypr/hyprtoolkit.conf': 'background=rgba(ffffffff)\nfont_size=12\n',
            'spicetify/config-xpui.ini': '[Setting]\ncurrent_theme=\ncolor_scheme=\nreplace_colors=1\ninject_css=1\n[AdditionalOptions]\nextensions=test.js\n',
            'Vencord/settings/settings.json': '{"enabledThemes": ["old.css"], "other": 42}\n'}
        for path, text in originals.items():
            self.put(path, text)
        for target in ['foot', 'yazi', 'btop', 'hyprtoolkit', 'spotify', 'discord']:
            with self.subTest(target=target):
                self.assertNotEqual(self.status(self.apply(target), target)['state'], 'error')
                self.assertNotEqual(self.status(self.apply(target, False), target)['state'], 'error')
        for path, text in originals.items():
            if path.endswith('.json'):
                self.assertEqual(json.loads((self.config / path).read_text()), json.loads(text))
            else:
                self.assertEqual((self.config / path).read_text(), text)
        self.assertEqual(sum(cmd[:4] == ['spicetify', '-q', 'apply', '--no-restart'] for cmd in self.commands), 2)

    def test_btop_reformatted_selection_syncs_and_restores(self):
        original = 'color_theme="noctalia"\nupdate_ms=1000\n'
        path = self.put('btop/btop.conf', original)
        self.apply('btop')
        # Simulate a legacy journal and btop's subsequent config rewrite.
        record = next(r for r in self.engine.state['journals']['btop'] if r['kind'] == 'lines')
        record['after'] = ['color_theme="quickshell-config"\n']
        self.engine.save()
        path.write_text('color_theme = "quickshell-config"\nupdate_ms=2000\n')
        self.engine = module.Themes(self.state, self.home, self.config, self.data,
                                   self.run_command, lambda cmd: '/bin/' + cmd)
        result = self.apply('btop', palette=list(palettes())[2], action='retry')
        self.assertEqual(self.status(result, 'btop')['state'], 'restart')
        self.assertEqual(path.read_text(), 'color_theme = "quickshell-config"\nupdate_ms=2000\n')
        path.write_text('color_theme  =  "quickshell-config"  \nupdate_ms=2000\n')
        self.assertEqual(self.status(self.apply('btop', False), 'btop')['state'], 'off')
        self.assertEqual(path.read_text(), original.replace('1000', '2000'))

    def test_btop_reformatted_original_theme_can_be_restored(self):
        path = self.put('btop/btop.conf', 'color_theme="noctalia"\n')
        self.apply('btop')
        path.write_text('color_theme = "noctalia"\n')
        self.assertEqual(self.status(self.apply('btop', False), 'btop')['state'], 'off')
        self.assertEqual(path.read_text(), 'color_theme="noctalia"\n')

    def test_btop_different_or_duplicate_selections_are_preserved(self):
        path = self.put('btop/btop.conf', 'color_theme="noctalia"\n')
        self.apply('btop')
        for edited in ['color_theme = "another-theme"\n',
                       'color_theme = "quickshell-config"\ncolor_theme = "quickshell-config"\n']:
            for enabled in [True, False]:
                with self.subTest(edited=edited, enabled=enabled):
                    path.write_text(edited)
                    result = self.status(self.apply('btop', enabled), 'btop')
                    self.assertEqual(result['state'], 'error')
                    self.assertIn('changed manually', result['message'])
                    self.assertEqual(path.read_text(), edited)
                    self.assertTrue((self.config / 'btop/themes/quickshell-config.theme').exists())

    def test_restart_state_and_missing_dependency(self):
        self.put('ghostty/config', 'theme=old\n')
        self.apply('ghostty')
        engine = module.Themes(self.state, self.home, self.config, self.data, self.run_command, lambda cmd: None)
        result = engine.handle({'action': 'discover'})
        self.assertTrue(self.status(result, 'ghostty')['enabled'])
        self.assertFalse(self.status(result, 'ghostty')['available'])
        result = engine.handle(dict(action='sync', palette=self.palette, mode='dark'))
        self.assertEqual(self.status(result, 'ghostty')['state'], 'error')

    def test_failed_hook_can_restore_and_retry(self):
        self.put('spicetify/config-xpui.ini', '[Setting]\ncurrent_theme=old\n')
        self.engine.run = lambda args: (_ for _ in ()).throw(RuntimeError('No write permission'))
        result = self.apply('spotify')
        self.assertEqual(self.status(result, 'spotify')['state'], 'error')
        self.engine.run = self.run_command
        result = self.apply('spotify', False)
        self.assertEqual(self.status(result, 'spotify')['state'], 'off')
        self.assertIn('current_theme=old', (self.config / 'spicetify/config-xpui.ini').read_text())

    def test_disabled_target_does_not_run_hooks(self):
        self.apply('spotify', False)
        self.assertEqual(self.commands, [])

    def test_failed_target_does_not_block_another(self):
        # A directory at the config path causes a real write/read failure.
        (self.config / 'ghostty/config').mkdir(parents=True)
        self.put('btop/btop.conf', 'color_theme="before"\n')
        self.apply('ghostty')
        self.apply('btop')
        result = self.engine.handle(dict(action='sync', palette=self.palette, mode='light'))
        self.assertEqual(self.status(result, 'ghostty')['state'], 'error')
        self.assertEqual(self.status(result, 'btop')['state'], 'restart')

    def test_corrupt_state_is_not_overwritten(self):
        self.state.mkdir()
        self.engine.file.write_text('{broken')
        with self.assertRaises(ValueError):
            module.Themes(self.state, self.home, self.config, self.data)
        self.assertEqual(self.engine.file.read_text(), '{broken')

    def test_invalid_palette_no_changes(self):
        with self.assertRaises(ValueError):
            self.apply('ghostty', palette={'bg': '$(bad)'})
        self.assertFalse(self.file_exists())

    def file_exists(self):
        return self.engine.file.exists()

    def test_symlink_retarget_is_preserved(self):
        path = self.put('ghostty/config', 'theme=old\n')
        self.apply('ghostty')
        path.unlink()
        other = self.home / 'other'
        other.write_text('theme=other\n')
        path.symlink_to(other)
        result = self.apply('ghostty', False)
        self.assertEqual(self.status(result, 'ghostty')['state'], 'error')
        self.assertEqual(other.read_text(), 'theme=other\n')

    def test_zen_profile_discovery(self):
        relative = self.config / 'zen/normal.profile'
        absolute = self.home / 'custom profile'
        flatpak = self.home / '.var/app/app.zen_browser.zen/.zen'
        for path in [relative, absolute, flatpak / 'flat.profile']:
            path.mkdir(parents=True)
        self.put('zen/profiles.ini', '[Profile0]\nPath=normal.profile\nIsRelative=1\n'
                 f'[Profile1]\nPath={absolute}\nIsRelative=0\n'
                 '[Profile2]\nPath=missing\nIsRelative=1\n'
                 '[InstallABC]\nDefault=normal.profile\n')
        (flatpak / 'profiles.ini').write_text('[Profile0]\nPath=flat.profile\nIsRelative=1\n')
        # The legacy location may link to XDG config; do not apply twice.
        (self.home / '.zen').symlink_to(self.config / 'zen', target_is_directory=True)
        self.assertEqual(self.engine.zen_profiles(), [relative, absolute, flatpak / 'flat.profile'])
        self.assertTrue(module.Themes.available(self.engine, 'zen')[0])
        (self.config / 'zen/profiles.ini').write_text('broken ini')
        self.assertEqual(self.engine.zen_profiles(), [flatpak / 'flat.profile'])
        (flatpak / 'profiles.ini').unlink()
        self.assertFalse(module.Themes.available(self.engine, 'zen')[0])

    def test_zen_roundtrip_updates_palette_preserves_css_and_preferences(self):
        self.put('zen/profiles.ini', '[Profile0]\nPath=active profile\nIsRelative=1\n')
        original = '@import "/home/example/.cache/noctalia/zen-browser/zen-userChrome.css";\n#custom { color: red; }\n'
        css = self.put('zen/active profile/chrome/userChrome.css', original)
        # A dotfile stylesheet must remain a symlink throughout sync/restore.
        real = self.home / 'custom.css'
        css.rename(real)
        css.symlink_to(real)
        preference = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);\n'
        user = self.put('zen/active profile/user.js', preference)
        prefs = self.put('zen/active profile/prefs.js', preference)
        before = self.status(self.apply('zen'), 'zen')
        self.assertEqual(before['state'], 'restart')
        self.assertNotIn('about:config', before['message'])
        self.assertEqual(css.read_text(), '@import url("quickshell-config.css");\n#custom { color: red; }\n')
        theme = css.parent / 'quickshell-config.css'
        self.assertIn(self.palette['bg'], theme.read_text())
        next_palette = list(palettes())[1]
        self.engine.handle(dict(action='sync', palette=next_palette, mode='light'))
        self.assertIn('color-scheme: light', theme.read_text())
        self.assertIn(next_palette['bg'], theme.read_text())
        self.assertEqual(css.read_text().count('@import'), 1)
        css.write_text(css.read_text() + '#personal { opacity: .9; }\n')
        # Reload recovery state, and restore even if profile registration changes.
        self.engine = module.Themes(self.state, self.home, self.config, self.data, self.run_command, lambda _: None)
        (self.config / 'zen/profiles.ini').unlink()
        self.assertEqual(self.status(self.apply('zen', False), 'zen')['state'], 'off')
        self.assertEqual(css.read_text(), original + '#personal { opacity: .9; }\n')
        self.assertTrue(css.is_symlink())
        self.assertFalse(theme.exists())
        self.assertEqual(user.read_text(), preference)
        self.assertEqual(prefs.read_text(), preference)
        self.assertEqual(self.commands, [])

    def test_zen_stylesheet_opt_in_and_manual_edit_conflict(self):
        self.put('zen/profiles.ini', '[Profile0]\nPath=profile\nIsRelative=1\n')
        profile = self.config / 'zen/profile'
        profile.mkdir()
        result = self.status(self.apply('zen'), 'zen')
        self.assertIn('about:config', result['message'])
        self.assertFalse((profile / 'prefs.js').exists())
        self.assertFalse((profile / 'user.js').exists())
        theme = profile / 'chrome/quickshell-config.css'
        theme.write_text('/* user edited the generated theme */\n')
        result = self.status(self.apply('zen', False), 'zen')
        self.assertEqual(result['state'], 'error')
        self.assertEqual(theme.read_text(), '/* user edited the generated theme */\n')

    def test_zen_reconciles_old_import_and_continues_to_other_profiles(self):
        self.put('zen/profiles.ini', '[Profile0]\nPath=active\n[Profile1]\nPath=other\n')
        old = '@import "/home/example/.cache/noctalia/zen-browser/zen-userChrome.css";\n'
        managed = '@import url("quickshell-config.css");\n'
        custom = '@import url("personal.css");\n#custom { color: red; }\n'
        active = self.put('zen/active/chrome/userChrome.css', old + custom)
        other = self.put('zen/other/chrome/userChrome.css', custom)
        self.apply('zen')
        active.write_text(old + managed + custom)
        next_palette = list(palettes())[1]
        self.assertEqual(self.status(self.apply('zen', palette=next_palette), 'zen')['state'], 'restart')
        for path in (active, other):
            self.assertEqual(path.read_text(), managed + custom)
            self.assertIn(next_palette['bg'], path.with_name('quickshell-config.css').read_text())
        self.apply('zen', False)
        self.assertEqual(active.read_text(), old + custom)
        self.assertEqual(other.read_text(), custom)

    def test_zen_user_preferences_override_cached_stylesheet_setting(self):
        profile = self.config / 'zen/profile'
        key = 'toolkit.legacyUserProfileCustomizations.stylesheets'
        self.put('zen/profile/prefs.js', f'user_pref("{key}", true);\n')
        self.put('zen/profile/user.js', f'user_pref("{key}", false);\n')
        self.assertFalse(self.engine.zen_styles_enabled(profile))

    def test_p10k_toggle_sync_and_restore_symlink(self):
        with patch.dict(os.environ, {'ZDOTDIR': str(self.home)}):
            self.assertFalse(module.Themes.available(self.engine, 'p10k')[0])
            original = "typeset -g POWERLEVEL9K_DIR_BACKGROUND=4\ntypeset -ga POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)\n"
            real = self.home / 'p10k-dotfile'
            real.write_text(original)
            path = self.home / '.p10k.zsh'
            path.symlink_to(real)
            self.assertTrue(module.Themes.available(self.engine, 'p10k')[0])
            self.assertEqual(self.status(self.apply('p10k'), 'p10k')['state'], 'restart')
            generated = self.config / 'zsh/quickshell-p10k.zsh'
            self.assertTrue(path.is_symlink())
            self.assertTrue(real.read_text().startswith(original))
            for palette in palettes():
                self.engine.handle(dict(action='sync', palette=palette, mode='dark'))
                self.assertIn(palette['iris'], generated.read_text())
                self.assertEqual(real.read_text().count('# quickshell-p10k-colors'), 1)
            # Unrelated edits made while syncing must survive disabling.
            with real.open('a') as stream:
                stream.write('# user note\n')
            self.assertEqual(self.status(self.apply('p10k', False), 'p10k')['state'], 'off')
            self.assertEqual(real.read_text(), original + '# user note\n')
            self.assertFalse(generated.exists())
            self.assertEqual(self.commands, [])

    def test_p10k_preserves_manual_override_edits(self):
        with patch.dict(os.environ, {'ZDOTDIR': str(self.home)}):
            (self.home / '.p10k.zsh').write_text('# config\n')
            self.apply('p10k')
            generated = self.config / 'zsh/quickshell-p10k.zsh'
            generated.write_text('# manual colors\n')
            self.assertEqual(self.status(self.apply('p10k', False), 'p10k')['state'], 'error')
            self.assertEqual(generated.read_text(), '# manual colors\n')

    def test_p10k_renderer_in_real_zsh(self):
        generated = self.home / 'colors.zsh'
        for palette in palettes():
            generated.write_text(formats.p10k(palette))
            code = r"""
                typeset -ga POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
                typeset -g POWERLEVEL9K_CUSTOM_BACKGROUND=4
                typeset -g POWERLEVEL9K_CUSTOM_FOREGROUND=250
                typeset -g POWERLEVEL9K_PROMPT_CHAR_BACKGROUND=''
                typeset -ga POWERLEVEL9K_BATTERY_LEVEL_FOREGROUND=(1 2 3)
                p10k() { [[ $1 == reload ]] || return 1; }
                source "$1" || exit 2
                [[ $POWERLEVEL9K_LEFT_PROMPT_ELEMENTS == 'dir vcs' ]] || exit 3
                [[ -z $POWERLEVEL9K_PROMPT_CHAR_BACKGROUND ]] || exit 4
                [[ $POWERLEVEL9K_BATTERY_LEVEL_FOREGROUND == '1 2 3' ]] || exit 5
                print -r -- "$POWERLEVEL9K_DIR_BACKGROUND $POWERLEVEL9K_CUSTOM_FOREGROUND"
            """
            result = subprocess.run(['zsh', '-dfc', code, 'test', str(generated)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.strip(), palette['iris'] + ' ' + palette['text'])

    def test_tmux_target_discovery_and_config_preservation(self):
        self.assertFalse(module.Themes.available(self.engine, 'tmux')[0])
        original = (ROOT / 'integrations/tmux/theme.conf').read_text()
        bindings = self.put('tmux/theme.conf', original)
        config = self.put('tmux/tmux.conf', 'set -g status 2\nbind h select-pane -L\n')
        self.assertTrue(module.Themes.available(self.engine, 'tmux')[0])
        self.engine.tmux_sockets = lambda: []
        self.assertEqual(self.status(self.apply('tmux'), 'tmux')['state'], 'applied')
        generated = self.config / 'tmux/quickshell-config.conf'
        self.assertIn('@quickshell_bg', generated.read_text())
        self.assertEqual(self.status(self.apply('tmux', False), 'tmux')['state'], 'off')
        self.assertFalse(generated.exists())
        self.assertEqual(bindings.read_text(), original)
        self.assertEqual(config.read_text(), 'set -g status 2\nbind h select-pane -L\n')

    def test_tmux_restore_after_reload_failure(self):
        self.put('tmux/theme.conf', (ROOT / 'integrations/tmux/theme.conf').read_text())
        self.engine.tmux_sockets = lambda: [self.home / 'fake.sock']
        def broken(args):
            if 'show-options' in args: return '1'
            raise RuntimeError('source failed')
        self.engine.run = broken
        self.assertEqual(self.status(self.apply('tmux'), 'tmux')['state'], 'error')
        self.engine.tmux_sockets = lambda: []
        self.assertEqual(self.status(self.apply('tmux', False), 'tmux')['state'], 'off')
        self.assertFalse((self.config / 'tmux/quickshell-config.conf').exists())


if __name__ == '__main__':
    unittest.main()
