#!/usr/bin/env python3
"""Wallhaven helper unit tests, then the real page, service, and persistence with a stub helper."""
from pathlib import Path
from design_test_support import script_path
import json
import os
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
subprocess.run(['python3', '-m', 'unittest', 'discover', '-s', str(ROOT / 'tests/wallhaven'), '-v'], check=True)

# Offline stand-in for scripts/wallpaper/wallhaven.py: records each request
# (with the key reduced to a flag) and answers with deterministic local data.
STUB = r'''#!/usr/bin/env python3
import json
from pathlib import Path
import sys
base = Path(__file__).resolve().parents[2]
request = json.load(sys.stdin)
key = request.pop('apiKey', '')
with (base / 'requests.jsonl').open('a') as log:
    log.write(json.dumps(dict(request, hasKey=bool(key))) + '\n')
thumb = (base / 'thumb.svg').as_uri()
action = request['action']
if action == 'download':
    folder = Path.home() / 'Pictures' / 'Wallhaven'
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / ('wallhaven-' + request['id'] + '.svg')
    path.write_text((base / 'thumb.svg').read_text())
    print(json.dumps({'id': request['id'], 'file': path.as_uri()}))
elif action == 'collections':
    print(json.dumps({'collections': [{'id': 7, 'label': 'Favs', 'count': 1}]}))
elif request.get('q') == 'fail':
    print(json.dumps({'error': 'Wallhaven rate limit reached. Try again in a minute.'}))
    sys.exit(1)
else:
    page = request.get('page', 1)
    prefix = 'col' if action == 'collection' else 'p' + str(page)
    items = [{'id': prefix + 'a1', 'thumb': thumb, 'full': 'https://w.wallhaven.cc/full/x/a.jpg',
              'resolution': '1920x1080', 'ratio': '1.78', 'fileType': 'image/svg', 'purity': 'sfw'},
             {'id': prefix + 'b2', 'thumb': thumb, 'full': 'https://w.wallhaven.cc/full/x/b.jpg',
              'resolution': '3840x2160', 'ratio': '1.78', 'fileType': 'image/svg', 'purity': 'sketchy'}]
    print(json.dumps({'items': items, 'page': page, 'lastPage': 3, 'total': 6, 'seed': ''}))
'''

with tempfile.TemporaryDirectory(prefix='qs-wallhaven-') as directory:
    base = Path(directory)
    for name in ('config', 'components', 'modules', 'services', 'scripts', 'kits'):
        shutil.copytree(ROOT / name, base / name, ignore=shutil.ignore_patterns('__pycache__'))
    (base / 'runtime').mkdir(mode=0o700)
    (base / 'home').mkdir()
    script_path(base, 'wallhaven.py').write_text(STUB)
    (base / 'thumb.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="36"><rect width="64" height="36" fill="#1478cf"/></svg>')
    theme = base / 'config/Theme.qml'
    theme.write_text(theme.read_text().replace(
        'readonly property var connectedScreens: Quickshell.screens',
        'property var connectedScreens: [{name: "TEST", width: 1280, height: 720, devicePixelRatio: 1.5}]'))
    (base / 'shell.qml').write_text('''import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services.wallpaper
import qs.modules.wallpaper
ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 860; implicitHeight: 900
        color: Theme.bg
        WallpaperPage { id: page; x: 20; y: 20; width: parent.width - 40 }
    }
    function find(item, name) {
        if (!item)
            return null;
        if (item.objectName === name)
            return item;
        const children = Array.from(item.children || []);
        if (item.contentItem && !children.includes(item.contentItem))
            children.push(item.contentItem);
        for (const child of children) {
            const found = find(child, name);
            if (found)
                return found;
        }
        return null;
    }
    IpcHandler {
        target: "test"
        function status(): string {
            return JSON.stringify({ready: Theme.ready && Wallhaven.ready, loading: Wallhaven.loading,
                downloading: Wallhaven.downloading, items: Wallhaven.items.map(item => item.id),
                page: Wallhaven.page, error: Wallhaven.errorMessage, collections: Wallhaven.collections.length,
                categories: Wallhaven.categories, purity: Wallhaven.purity, collection: Wallhaven.collection,
                matchResolution: Wallhaven.matchResolution, wallpaper: Theme.wallpaperFor("TEST"),
                light: Theme.wallpaperFor("TEST", "light"), browser: !!find(page, "wallhaven-gallery")});
        }
        function source(value: string): void { page.gallerySource = value; }
        function click(name: string): bool {
            const item = find(page, name);
            if (!item || !item.enabled)
                return false;
            if (item.checkable) { item.toggle(); item.toggled(); } else item.clicked();
            return true;
        }
        function type(name: string, value: string): bool {
            const item = find(page, name);
            if (!item)
                return false;
            item.text = value;
            return true;
        }
        function account(key: string, user: string): void { Wallhaven.setAccount(key, user); }
        function collection(id: int): void { Wallhaven.setOption("collection", id); Wallhaven.search(1, ""); }
        function separate(): void { Theme.setSeparateWallpapers(true); page.selectedMode = "light"; }
    }
}
''')
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', HOME=str(base / 'home'),
               XDG_RUNTIME_DIR=str(base / 'runtime'), XDG_STATE_HOME=str(base / 'state'), XDG_CACHE_HOME=str(base / 'cache'))
    requests_log = base / 'requests.jsonl'

    def requests():
        return [json.loads(line) for line in requests_log.read_text().splitlines()] if requests_log.exists() else []

    with (base / 'log').open('w+') as log:
        def start():
            return subprocess.Popen(['quickshell', '--path', str(base)], env=env, stdout=log, stderr=subprocess.STDOUT)

        def ipc(action, *args):
            result = subprocess.run(['quickshell', 'ipc', '--path', str(base), 'call', 'test', action, *map(str, args)],
                                    env=env, capture_output=True, text=True, timeout=5)
            if result.returncode:
                raise RuntimeError(result.stderr + result.stdout)
            return result.stdout.strip()

        def wait_for(predicate):
            deadline = time.monotonic() + 10
            while time.monotonic() < deadline:
                try:
                    current = json.loads(ipc('status'))
                    if current['ready'] and predicate(current):
                        return current
                except (RuntimeError, json.JSONDecodeError):
                    pass
                time.sleep(.06)
            log.flush(); log.seek(0)
            raise AssertionError(log.read())

        def settled(predicate=lambda s: True):
            return wait_for(lambda s: not s['loading'] and not s['downloading'] and predicate(s))

        process = start()
        try:
            initial = wait_for(lambda s: True)
            assert not initial['browser'] and requests() == [], 'Wallhaven must stay idle until its tab opens'
            ipc('source', 'wallhaven')
            first = settled(lambda s: s['items'] == ['p1a1', 'p1b2'])
            assert first['browser'] and requests()[-1]['action'] == 'search' and not requests()[-1]['hasKey']

            assert ipc('click', 'wallhaven-category-anime') == 'true'
            settled(lambda s: s['categories'] == '101')
            assert requests()[-1]['categories'] == '101' and requests()[-1]['page'] == 1
            assert ipc('click', 'wallhaven-purity-nsfw') == 'false', 'NSFW needs an API key'

            assert ipc('click', 'wallhaven-next') == 'true'
            settled(lambda s: s['page'] == 2 and s['items'][0] == 'p2a1')
            assert ipc('click', 'wallhaven-match-resolution') == 'true'
            settled(lambda s: s['matchResolution'] and s['page'] == 1)
            assert requests()[-1]['atleast'] == '1920x1080', requests()[-1]

            assert ipc('type', 'wallhaven-query', 'fail') == 'true'
            assert ipc('click', 'wallhaven-search') == 'true'
            assert 'rate limit' in settled(lambda s: bool(s['error']))['error']
            ipc('type', 'wallhaven-query', 'mountains'); ipc('click', 'wallhaven-search')
            settled(lambda s: not s['error'] and requests()[-1]['q'] == 'mountains')

            assert ipc('click', 'wallhaven-image-p1b2') == 'true'
            applied = settled(lambda s: s['wallpaper'].endswith('/wallhaven-p1b2.svg'))
            downloaded = base / 'home/Pictures/Wallhaven/wallhaven-p1b2.svg'
            assert downloaded.is_file() and applied['wallpaper'] == downloaded.as_uri()

            # Separate light/dark: the download lands only in the selected mode.
            ipc('separate')
            ipc('click', 'wallhaven-image-p1a1')
            light = settled(lambda s: s['light'].endswith('/wallhaven-p1a1.svg'))
            assert light['wallpaper'] != light['light']

            ipc('account', 'secret-key', 'me')
            settled(lambda s: s['collections'] == 1)
            assert requests()[-1] == {'action': 'collections', 'hasKey': True}
            assert ipc('click', 'wallhaven-purity-nsfw') == 'true'
            settled(lambda s: s['purity'] == '101')
            ipc('collection', 7)
            settled(lambda s: s['items'] == ['cola1', 'colb2'])
            last = requests()[-1]
            assert last['action'] == 'collection' and last['username'] == 'me' and last['collection'] == 7 and last['hasKey']

            time.sleep(.5)
            process.terminate(); process.wait(timeout=5)
            state, = (base / 'state').rglob('wallhaven.json')
            saved = json.loads(state.read_text())
            assert saved['apiKey'] == 'secret-key' and saved['username'] == 'me' and saved['query'] == 'mountains'
            process = start()
            restored = wait_for(lambda s: s['collections'] == 1)
            assert (restored['categories'], restored['purity'], restored['collection'], restored['matchResolution']) == ('101', '101', 7, True)

            # Removing the key drops NSFW and collections.
            ipc('account', '', 'me')
            cleared = settled(lambda s: s['purity'] == '100')
            assert cleared['collection'] == 0 and cleared['collections'] == 0
            print('PASS: lazy loading, filters, paging, errors, download/apply per mode, account, collections, and persistence')
            log.flush(); log.seek(0)
            output = log.read()
            if any(word in output for word in ('ReferenceError', 'TypeError', 'Binding loop', 'Failed to load configuration')):
                raise AssertionError(output)
        finally:
            process.terminate(); process.wait(timeout=5)
