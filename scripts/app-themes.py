#!/usr/bin/env python3
"""Apply/restore explicitly enabled application themes. JSON stdin/stdout API.

All subprocesses use fixed argument lists. No downloaded templates or shell hooks.
Recovery records are written before configuration changes; the lock also serializes
Spicetify and competing shell instances. Importing this module has no side effects.
"""
from pathlib import Path
import argparse
import configparser
import fcntl
import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import time
from urllib.parse import unquote, urlsplit

import app_theme_formats as fmt

TARGETS = [('gtk', 'GTK 3 / 4'), ('qt', 'Qt / KDE'), ('rofi', 'Rofi'), ('ghostty', 'Ghostty'), ('foot', 'Foot'),
           ('yazi', 'Yazi'), ('btop', 'btop'), ('hyprtoolkit', 'Hyprtoolkit'),
           ('spotify', 'Spotify'), ('discord', 'Discord'), ('zen', 'Zen Browser'), ('tmux', 'tmux'), ('hyprlock', 'Hyprlock')]


def read(path):
    return path.read_text() if path.exists() else ''


def atomic(path, text):
    path = path.resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    fd, name = tempfile.mkstemp(prefix='.' + path.name + '.', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            os.fchmod(stream.fileno(), mode)
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def selected_lines(text, pattern, section=None):
    selected, current = [], None
    for index, line in enumerate(text.splitlines(keepends=True)):
        header = re.match(r'^\s*\[([^\]]+)\]\s*$', line.strip())
        if header:
            current = header[1]
        if (section is None or section == current) and re.match(pattern, line):
            selected.append((index, line))
    return selected


def edit_lines(text, pattern, replacement, section=None, prepend=False):
    lines = text.splitlines(keepends=True)
    selected = selected_lines(text, pattern, section)
    if selected:
        indices = {i for i, _ in selected}
        result = []
        for i, line in enumerate(lines):
            if i == selected[0][0]:
                result.extend(replacement)
            if i not in indices:
                result.append(line)
        return ''.join(result)
    if not replacement:
        return text
    addition = ''.join(replacement)
    if section is not None:
        for i, line in enumerate(lines):
            if line.strip() == '[' + section + ']':
                lines.insert(i + 1, addition)
                return ''.join(lines)
        return text + ('\n' if text and not text.endswith('\n') else '') + f'\n[{section}]\n' + addition
    if prepend:
        return addition + text
    return text + ('\n' if text and not text.endswith('\n') else '') + addition


class Themes:
    def __init__(self, state_dir, home=None, config=None, data=None, runner=None, which=None):
        self.home = Path(home or Path.home())
        self.config = Path(config or (os.environ.get('XDG_CONFIG_HOME') or self.home / '.config'))
        self.data = Path(data or (os.environ.get('XDG_DATA_HOME') or self.home / '.local/share'))
        self.directory = Path(state_dir)
        self.file = self.directory / 'state.json'
        self.run = runner or self.run_command
        self.which = which or shutil.which
        self.state = json.loads(read(self.file)) if self.file.exists() else {
            'version': 1, 'enabled': [], 'journals': {}, 'status': {}, 'pending_restore': []}
        if self.state.get('version') != 1 or not isinstance(self.state.get('journals'), dict):
            raise ValueError('Invalid app-theme recovery state; restore its backup before applying themes.')
        self.state.setdefault('reload_restore', [])
        self.current = None
        self.lock_screen = {}

    @staticmethod
    def run_command(args):
        result = subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=90)
        if result.returncode:
            raise RuntimeError((result.stderr or result.stdout or f'{args[0]} failed').strip()[-800:])
        return result.stdout.strip()

    def save(self):
        atomic(self.file, json.dumps(self.state, indent=2) + '\n')

    def journal(self):
        return self.state['journals'].setdefault(self.current, [])

    def record(self, identity, path=None, **values):
        records = self.journal()
        old = next((r for r in records if r['id'] == identity), None)
        if old:
            if path and old['resolved'] != str(path.resolve()):
                raise RuntimeError(f'Symlink target changed: {path}')
            return old
        if path:
            values.update(path=str(path), resolved=str(path.resolve()))
            if path.exists():
                name = hashlib.sha256(str(path).encode()).hexdigest()[:16] + '-' + str(time.time_ns())
                backup = self.directory / 'backups' / self.current / name
                atomic(backup, read(path))
                values['backup'] = str(backup)
        record = dict(id=identity, **values)
        records.append(record)
        return record

    def generated(self, path, content):
        record = self.record('file:' + str(path), path, kind='file', before=read(path) if path.exists() else None,
                             after=read(path) if path.exists() else None)
        current = read(path) if path.exists() else None
        if current not in (record['before'], record['after']):
            raise RuntimeError(f'Manual edits preserved: {path}')
        record['after'] = content
        self.save()
        if current != content:
            atomic(path, content)

    def lines(self, path, identity, pattern, replacement, section=None, prepend=False, reconcile_imports=False):
        text = read(path)
        current = [line for _, line in selected_lines(text, pattern, section)]
        record = self.record('lines:' + str(path) + ':' + identity, path, kind='lines', pattern=pattern,
                             section=section, prepend=prepend, before=current, after=current)
        # Another theme manager can reinsert the previous import alongside ours.
        # Reconcile only imports already recorded in this target's journal; keep
        # the original restore snapshot and reject any unfamiliar edited line.
        known_imports = (reconcile_imports and identity == 'theme-import'
                         and all(line in record['before'] + record['after'] for line in current))
        if current not in (record['before'], record['after']) and not known_imports:
            raise RuntimeError(f'Theme setting changed manually: {path} ({identity})')
        record['after'] = replacement
        self.save()
        updated = edit_lines(text, pattern, replacement, section, prepend)
        if updated != text:
            atomic(path, updated)

    def field(self, path, key, value, section=None):
        self.lines(path, str(section) + ':' + key, r'^\s*' + re.escape(key) + r'\s*=',
                   [f'{key}={value}\n'], section)

    def setting(self, key, value):
        schema = 'org.gnome.desktop.interface'
        current = self.run(['gsettings', 'get', schema, key])
        record = self.record('gsettings:' + key, kind='gsettings', key=key, before=current, after=current)
        if current not in (record['before'], record['after']):
            raise RuntimeError(f'Desktop preference changed manually: {key}')
        record['after'] = value
        self.save()
        if current != value:
            self.run(['gsettings', 'set', schema, key, value])

    def json_theme(self, path):
        value = json.loads(read(path) or '{}')
        themes = value.get('enabledThemes', [])
        if not isinstance(themes, list):
            raise ValueError(f'Invalid enabledThemes in {path}')
        record = self.record('json:' + str(path), path, kind='json_theme',
                             before=fmt.NAME + '.theme.css' in themes)
        if fmt.NAME + '.theme.css' not in themes:
            value['enabledThemes'] = themes + [fmt.NAME + '.theme.css']
            self.save()
            atomic(path, json.dumps(value, indent=2) + '\n')

    def discord_roots(self):
        roots = [self.config / 'Vencord', self.config / 'vesktop' / 'settings']
        if os.environ.get('VENCORD_USER_DATA_DIR'):
            roots.insert(0, Path(os.environ['VENCORD_USER_DATA_DIR']))
        return [p for p in roots if (p / 'settings.json').exists() or (p / 'settings/settings.json').exists()]

    def tmux_sockets(self):
        # Named (-L) servers share this directory. Explicit -S sockets are also
        # supported when Quickshell inherits TMUX from that server.
        roots = {Path('/tmp'), Path(os.environ.get('TMUX_TMPDIR') or '/tmp')}
        candidates = []
        for root in roots:
            directory = root / f'tmux-{os.getuid()}'
            if directory.is_dir():
                candidates.extend(directory.iterdir())
        if os.environ.get('TMUX'):
            candidates.append(Path(os.environ['TMUX'].rsplit(',', 2)[0]))
        result = []
        for path in candidates:
            try:
                info = path.lstat()
            except FileNotFoundError:
                continue
            if stat.S_ISSOCK(info.st_mode) and info.st_uid == os.getuid() and path not in result:
                result.append(path)
        return result

    def reload_tmux(self):
        for socket in self.tmux_sockets():
            command = ['tmux', '-S', str(socket)]
            try:
                marker = self.run(command + ['show-options', '-gqv', '@quickshell-config-theme'])
            except RuntimeError as error:
                if any(message in str(error) for message in ['no server running', 'Connection refused', 'No such file or directory']):
                    continue
                raise
            # Never touch servers using another tmux configuration.
            if marker != '1':
                continue
            if 'tmux' not in self.state['enabled']:
                args = []
                for role in fmt.TMUX_ROLES:
                    args += ['set-option', '-gu', '@quickshell_' + role, ';']
                self.run(command + args[:-1])
            self.run(command + ['source-file', str(self.config / 'tmux/theme.conf')])

    def zen_profiles(self):
        flatpak = self.home / '.var/app/app.zen_browser.zen'
        roots = [self.config / 'zen', self.home / '.zen', flatpak / 'config/zen',
                 flatpak / '.zen', flatpak / 'zen']
        profiles = []
        for root in roots:
            parser = configparser.RawConfigParser()
            try:
                parser.read_string(read(root / 'profiles.ini'))
            except (OSError, configparser.Error):
                continue
            for section in parser.sections():
                if not section.startswith('Profile'):
                    continue
                value = parser.get(section, 'Path', fallback='').strip()
                if not value:
                    continue
                path = Path(value)
                if parser.get(section, 'IsRelative', fallback='1') == '1':
                    path = root / path
                elif not path.is_absolute():
                    continue
                path = path.resolve()
                if path.is_dir() and path not in profiles:
                    profiles.append(path)
        return profiles

    @staticmethod
    def zen_styles_enabled(profile):
        # user.js overrides prefs.js at startup. Read only this preference;
        # never rewrite the live browser's prefs.js or execute user.js.
        pattern = r'user_pref\(\s*["\x27]toolkit\.legacyUserProfileCustomizations\.stylesheets["\x27]\s*,\s*(true|false)\s*\)'
        values = re.findall(pattern, read(profile / 'prefs.js') + '\n' + read(profile / 'user.js'))
        return bool(values) and values[-1] == 'true'

    def qt_backend(self):
        platform = os.environ.get('QT_QPA_PLATFORMTHEME', '')
        if platform == 'kde' and (self.which('kreadconfig6') or self.which('kreadconfig5')):
            return 'kde'
        for version in ('qt6ct', 'qt5ct'):
            if platform == version and self.which(version):
                return version
        if self.which('kreadconfig6') or self.which('kreadconfig5'):
            return 'kde'
        for version in ('qt6ct', 'qt5ct'):
            if self.which(version):
                return version
        return None

    def available(self, target):
        if target == 'gtk':
            themes = [self.data / 'themes', self.home / '.themes', Path('/usr/share/themes')]
            return (bool(self.which('gsettings')) and any((p / 'adw-gtk3').exists() for p in themes),
                    'Requires gsettings, desktop schemas, and adw-gtk-theme.')
        if target == 'qt':
            return bool(self.qt_backend()), 'Requires KDE platform integration or qt5ct/qt6ct.'
        if target == 'discord':
            return bool(self.discord_roots()), 'Requires an existing Vencord or Vesktop installation.'
        if target == 'zen':
            return bool(self.zen_profiles()), 'No Zen profiles found. Start Zen Browser once, then refresh.'
        if target == 'tmux':
            return (bool(self.which('tmux')) and '# Quickshell tmux color bindings v1' in read(self.config / 'tmux/theme.conf'),
                    'Requires tmux and the dotfiles tmux/theme.conf integration.')
        if target == 'hyprtoolkit':
            return (self.config / 'hypr/hyprtoolkit.conf').exists(), 'No Hyprtoolkit configuration found.'
        executable = 'spicetify' if target == 'spotify' else target
        return bool(self.which(executable)), f'{executable} is not installed.'

    def session_setup(self, target):
        if target == 'gtk':
            # This user's forcing export originates in zsh; also recognize the
            # standard shell/session files on another machine, without rewriting
            # unrelated environment variables or sourcing arbitrary shell code.
            for path in [self.home / '.zshrc', self.home / '.zprofile', self.home / '.profile',
                         self.config / 'uwsm/env']:
                pattern = r'^\s*(?:export\s+)?GTK_THEME\s*='
                if selected_lines(read(path), pattern) or any(r.get('path') == str(path) for r in self.journal()):
                    self.lines(path, 'GTK_THEME', pattern, [])
            path = self.config / 'hypr/config/env.lua'
            pattern = r'^\s*hl\.env\([\"\x27]GTK_THEME[\"\x27]\s*,'
            if selected_lines(read(path), pattern):
                self.lines(path, 'GTK_THEME', pattern, [])
        else:
            backend = self.qt_backend()
            path = self.config / 'hypr/config/env.lua'
            if path.exists():
                for key, value in [('QT_STYLE_OVERRIDE', 'Fusion'), ('QT_QPA_PLATFORMTHEME', backend)]:
                    self.lines(path, key, r'^\s*hl\.env\([\"\x27]' + key + r'[\"\x27]\s*,',
                               [f'hl.env("{key}", "{value}")\n'])
            else:
                # Standard desktop-session setup for machines using environment.d.
                path = self.config / 'environment.d/90-quickshell-theme.conf'
                self.field(path, 'QT_STYLE_OVERRIDE', 'Fusion')
                self.field(path, 'QT_QPA_PLATFORMTHEME', backend)

    def apply(self, target, p, mode):
        c, d, name = self.config, self.data, fmt.NAME
        if target == 'hyprlock':
            options = self.lock_screen
            if not isinstance(options, dict) or options.get('background', 'theme') not in ('theme', 'color', 'image'):
                raise ValueError('Invalid lock-screen background mode.')
            background = p['bg']
            image = ''
            if options.get('background') == 'color':
                background = options.get('color', '')
                if not isinstance(background, str) or not re.fullmatch(r'#[0-9a-fA-F]{6}', background):
                    raise ValueError('Choose a lock-screen color in #RRGGBB format.')
            elif options.get('background') == 'image':
                source = options.get('image', '')
                if not isinstance(source, str) or not source.startswith('file:///'):
                    raise ValueError('Choose a local PNG, JPEG, or WebP lock-screen picture.')
                url = urlsplit(source)
                path = Path(unquote(url.path))
                if url.netloc or url.query or url.fragment or path.suffix.lower() not in ('.png', '.jpg', '.jpeg', '.webp') or not path.is_file():
                    raise ValueError('The lock-screen picture must be an existing local PNG, JPEG, or WebP file.')
                # Hyprlang interprets variables, comments and newlines before widgets.
                # Reject these rather than letting a filename change the configuration.
                image = fmt.hyprlock_path(str(path))
            helper = Path(__file__).resolve().with_name('hyprlock-status.py')
            self.generated(c / 'hypr/hyprlock.conf', fmt.hyprlock(p, background, image, str(helper)))
            return 'applied', 'Ready for the next lock. Keyboard layout and Caps Lock status stay visible.'
        elif target == 'gtk':
            for version, css in zip(('3.0', '4.0'), fmt.gtk(p)):
                directory = c / ('gtk-' + version)
                self.generated(directory / (name + '.css'), css)
                self.lines(directory / 'gtk.css', 'theme-import',
                           r'^\s*@import\s+(?:url\()?\s*[\"\x27](?:noctalia|quickshell-config)\.css',
                           [f'@import url("{name}.css");\n'], prepend=True, reconcile_imports=True)
                self.field(directory / 'settings.ini', 'gtk-application-prefer-dark-theme', '1' if mode == 'dark' else '0', 'Settings')
                if version == '3.0':
                    self.field(directory / 'settings.ini', 'gtk-theme-name', 'adw-gtk3-dark' if mode == 'dark' else 'adw-gtk3', 'Settings')
            self.setting('color-scheme', "'prefer-" + mode + "'")
            self.setting('gtk-theme', "'adw-gtk3" + ('-dark' if mode == 'dark' else '') + "'")
            self.session_setup(target)
            return 'restart', 'Applied. Reopen GTK apps; log in again after the first setup.'
        if target == 'qt':
            backend = self.qt_backend()
            if backend == 'kde':
                sections = fmt.kde(p)
                self.generated(d / 'color-schemes' / (name + '.colors'), fmt.ini(sections))
                for section, values in sections.items():
                    for key, value in values.items():
                        self.field(c / 'kdeglobals', key, value, section)
            else:
                for version in ('qt5ct', 'qt6ct'):
                    path = c / version / 'colors' / (name + '.conf')
                    self.generated(path, fmt.qt(p))
                    if self.which(version):
                        self.field(c / version / (version + '.conf'), 'color_scheme_path', str(path), 'Appearance')
                        self.field(c / version / (version + '.conf'), 'custom_palette', 'true', 'Appearance')
                        self.field(c / version / (version + '.conf'), 'style', 'Fusion', 'Appearance')
            self.session_setup(target)
            self.reload(target, remember=True)
            return 'restart', 'Applied. Reopen Qt apps; log in again after the first setup.'
        if target == 'rofi':
            self.generated(c / 'rofi' / (name + '.rasi'), fmt.rofi(p))
            # Import last so colors override the existing theme without resetting
            # its layout (as @theme would). Only manage our own import.
            self.lines(c / 'rofi/config.rasi', 'theme-import',
                       r'^\s*@import\s+"quickshell-config\.rasi"\s*;?\s*$',
                       [f'@import "{name}.rasi"\n'])
            return 'applied', 'Applied. Colors load the next time Rofi opens.'
        if target == 'ghostty':
            self.generated(c / 'ghostty/themes' / name, fmt.terminal(p, target))
            paths = [path for path in [c / 'ghostty/config', c / 'ghostty/config.ghostty'] if path.exists()]
            for path in paths or [c / 'ghostty/config']:
                self.field(path, 'theme', name)
            self.reload(target, remember=True)
            return 'applied', 'Applied'
        if target == 'tmux':
            self.generated(c / 'tmux/quickshell-config.conf', fmt.tmux(p))
            self.reload(target, remember=True)
            return 'applied', 'Applied. Colors update in running tmux servers using this config.'
        if target == 'foot':
            self.generated(c / 'foot/themes' / name, fmt.terminal(p, target))
            self.lines(c / 'foot/foot.ini', 'theme-include', r'^\s*include\s*=.*(?:noctalia|quickshell-config)\s*$',
                       [f'include={c / "foot/themes" / name}\n'], prepend=True)
        elif target == 'yazi':
            flavor, syntax = fmt.yazi(p)
            self.generated(c / 'yazi/flavors' / (name + '.yazi') / 'flavor.toml', flavor)
            self.generated(c / 'yazi/flavors' / (name + '.yazi') / 'tmtheme.xml', syntax)
            for mode_key in ('dark', 'light'):
                self.field(c / 'yazi/theme.toml', mode_key, json.dumps(name), 'flavor')
        elif target == 'btop':
            self.generated(c / 'btop/themes' / (name + '.theme'), fmt.btop(p))
            self.field(c / 'btop/btop.conf', 'color_theme', json.dumps(name))
        elif target == 'hyprtoolkit':
            values = dict(background='bg', base='surface', text='text', alternate_base='overlay',
                          bright_text='text', accent='iris', accent_secondary='foam')
            for key, role in values.items():
                self.field(c / 'hypr/hyprtoolkit.conf', key, f'rgba({p[role][1:]}ff)')
            return 'applied', 'Applied'
        elif target == 'spotify':
            self.generated(c / 'spicetify/Themes' / name / 'color.ini', fmt.spotify(p))
            self.generated(c / 'spicetify/Themes' / name / 'user.css', '/* Quickshell uses Spicetify color replacement. */\n')
            config = c / 'spicetify/config-xpui.ini'
            if not config.exists():
                raise RuntimeError('Initialize Spicetify for your Spotify installation first.')
            for key, value in [('current_theme', name), ('color_scheme', 'Base'), ('inject_css', '1'), ('replace_colors', '1')]:
                self.field(config, key, value, 'Setting')
            self.reload(target, remember=True)
        elif target == 'discord':
            for directory in self.discord_roots():
                settings = directory / 'settings' if (directory / 'settings/settings.json').exists() else directory
                themes = directory / 'themes' if settings != directory else directory.parent / 'themes'
                self.generated(themes / (name + '.theme.css'), fmt.discord(p))
                self.json_theme(settings / 'settings.json')
        elif target == 'zen':
            profiles = self.zen_profiles()
            if not profiles:
                raise RuntimeError('No Zen profiles found. Start Zen Browser once, then refresh.')
            missing_styles = []
            for profile in profiles:
                self.generated(profile / 'chrome' / (name + '.css'), fmt.zen(p, mode))
                self.lines(profile / 'chrome/userChrome.css', 'theme-import',
                           r'^\s*@import\s+(?:url\(\s*)?["\x27](?:quickshell-config\.css|'
                           r'(?:[^"\x27\r\n]*/)?noctalia/zen-browser/zen-userChrome\.css|'
                           r'noctalia\.css)["\x27]\s*\)?\s*;\s*$',
                           [f'@import url("{name}.css");\n'], prepend=True, reconcile_imports=True)
                if not self.zen_styles_enabled(profile):
                    missing_styles.append(profile.name)
            message = f'Applied to {len(profiles)} profile(s). Restart Zen to load colors.'
            if missing_styles:
                message += (' Enable toolkit.legacyUserProfileCustomizations.stylesheets in about:config for: '
                            + ', '.join(missing_styles) + '.')
            return 'restart', message
        return 'restart', 'Applied. Reopen the app to load its colors.'

    def reload(self, target, remember=False):
        if remember and target not in self.state['reload_restore']:
            self.state['reload_restore'].append(target)
            self.save()
        if target == 'ghostty' and self.which('pkill'):
            # pkill returns 1 when no matching process exists, which is normal.
            try:
                self.run(['pkill', '-USR2', '-u', str(os.getuid()), '-x', 'ghostty'])
            except RuntimeError as error:
                if str(error) != 'pkill failed':
                    raise
        elif target == 'qt' and self.which('dbus-send'):
            self.run(['dbus-send', '--session', '/KGlobalSettings', 'org.kde.KGlobalSettings.notifyChange', 'int32:0', 'int32:0'])
        elif target == 'spotify':
            self.run(['spicetify', '-q', 'apply', '--no-restart'])
        elif target == 'tmux':
            self.reload_tmux()

    def restore(self, target):
        self.current = target
        records = self.journal()
        errors = []
        # Restore selection/imports before removing generated files.
        ordered = [r for r in records if r['kind'] != 'file'] + [r for r in records if r['kind'] == 'file']
        for record in ordered:
            try:
                kind = record['kind']
                if kind == 'gsettings':
                    current = self.run(['gsettings', 'get', 'org.gnome.desktop.interface', record['key']])
                    if current not in (record['before'], record['after']):
                        raise RuntimeError('Desktop preference changed manually: ' + record['key'])
                    self.run(['gsettings', 'set', 'org.gnome.desktop.interface', record['key'], record['before']])
                else:
                    path = Path(record['path'])
                    if str(path.resolve()) != record['resolved']:
                        raise RuntimeError(f'Symlink target changed: {path}')
                    if kind == 'file':
                        # Keep generated files if a selection could not be restored.
                        if errors:
                            continue
                        current = read(path) if path.exists() else None
                        if current not in (record['before'], record['after']):
                            raise RuntimeError(f'Manual edits preserved: {path}')
                        if record['before'] is None:
                            if path.exists():
                                path.resolve().unlink()
                        else:
                            atomic(path, record['before'])
                    elif kind == 'lines':
                        text = read(path)
                        current = [line for _, line in selected_lines(text, record['pattern'], record['section'])]
                        if current not in (record['before'], record['after']):
                            raise RuntimeError(f'Theme setting changed manually: {path}')
                        updated = edit_lines(text, record['pattern'], record['before'], record['section'], record['prepend'])
                        if updated != text:
                            atomic(path, updated)
                    elif kind == 'json_theme':
                        value = json.loads(read(path) or '{}')
                        if not record['before']:
                            value['enabledThemes'] = [t for t in value.get('enabledThemes', []) if t != fmt.NAME + '.theme.css']
                            atomic(path, json.dumps(value, indent=2) + '\n')
                records.remove(record)
                self.save()
            except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
                errors.append(str(error))
        if errors:
            raise RuntimeError('; '.join(errors))
        if target in self.state['reload_restore']:
            self.reload(target)
            self.state['reload_restore'].remove(target)
        self.state['journals'].pop(target, None)
        self.state['pending_restore'] = [t for t in self.state['pending_restore'] if t != target]
        self.state['status'][target] = {'state': 'off', 'message': 'Previous theme restored. Reopen the app if needed.'}
        self.save()

    def handle(self, request):
        self.lock_screen = request.get('lockScreen', {})
        action = request.get('action', 'discover')
        if action not in ('discover', 'sync', 'set', 'retry'):
            raise ValueError('Unknown action')
        if action != 'discover':
            palette = fmt.validate(request.get('palette'), request.get('mode'))
            target = request.get('target')
            if action in ('set', 'retry') and target not in dict(TARGETS):
                raise ValueError('Unknown target')
            if action == 'set':
                enabled = request.get('enabled')
                if not isinstance(enabled, bool):
                    raise ValueError('enabled must be a boolean')
                if enabled:
                    if target not in self.state['enabled']:
                        self.state['enabled'].append(target)
                    self.state['pending_restore'] = [t for t in self.state['pending_restore'] if t != target]
                else:
                    self.state['enabled'] = [t for t in self.state['enabled'] if t != target]
                    if target not in self.state['pending_restore']:
                        self.state['pending_restore'].append(target)
                self.save()
            targets = [target] if action in ('set', 'retry') else list(dict.fromkeys(self.state['enabled'] + self.state['pending_restore']))
            for target in targets:
                self.current = target
                try:
                    if target in self.state['enabled']:
                        available, reason = self.available(target)
                        if not available:
                            raise RuntimeError(reason)
                        state, message = self.apply(target, palette, request['mode'])
                        self.state['status'][target] = dict(state=state, message=message)
                    elif target in self.state['pending_restore']:
                        self.restore(target)
                except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
                    self.state['status'][target] = dict(state='error', message=str(error))
                self.save()
        results = []
        for target, label in TARGETS:
            available, reason = self.available(target)
            status = self.state['status'].get(target, dict(state='off', message=''))
            results.append(dict(id=target, name=label, enabled=target in self.state['enabled'],
                                available=available, state=status['state'],
                                message=status['message'] or (reason if not available else '')))
        return {'targets': results}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--state', type=Path, required=True)
    args = parser.parse_args()
    try:
        request = json.load(sys.stdin)
        args.state.mkdir(parents=True, exist_ok=True, mode=0o700)
        with (args.state / 'lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            result = Themes(args.state).handle(request)
        print(json.dumps(result))
    except (OSError, ValueError, KeyError, TypeError, RuntimeError) as error:
        print(json.dumps({'error': str(error)}))
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
