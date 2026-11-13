#!/usr/bin/env python3
"""Search Wallhaven and download wallpapers; one JSON request on stdin, JSON on stdout."""
import json
import os
from pathlib import Path
import re
import sys
import tempfile
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlsplit, quote
from urllib.request import Request, urlopen

API = 'https://wallhaven.cc/api/v1'
USER_AGENT = 'quickshell-wallpaper/1.0'
TIMEOUT = 15
MAX_DOWNLOAD = 50 * 1024 * 1024
SORTINGS = ('toplist', 'date_added', 'relevance', 'random', 'views', 'favorites')
TOP_RANGES = ('1d', '3d', '1w', '1M', '3M', '6M', '1y')
EXTENSIONS = ('.jpg', '.jpeg', '.png', '.webp')
ID_PATTERN = re.compile(r'^[a-z0-9]{1,16}$')
USERNAME_PATTERN = re.compile(r'^[A-Za-z0-9_.-]{1,64}$')
RESOLUTION_PATTERN = re.compile(r'^[1-9][0-9]{1,4}x[1-9][0-9]{1,4}$')
SEED_PATTERN = re.compile(r'^[A-Za-z0-9]{6}$')


def download_dir():
    return Path.home() / 'Pictures' / 'Wallhaven'


def bits(value, default):
    return value if isinstance(value, str) and re.fullmatch(r'[01]{3}', value) else default


def purity(value, api_key):
    selected = bits(value, '100')
    # NSFW results require a valid key; never ask for them without one.
    if not api_key:
        selected = selected[:2] + '0'
    return selected if '1' in selected else '100'


def page_number(value):
    return value if isinstance(value, int) and 1 <= value <= 10000 else 1


def fetch(url, api_key='', limit=4 * 1024 * 1024):
    headers = {'User-Agent': USER_AGENT, 'Accept': 'application/json'}
    if api_key:
        headers['X-API-Key'] = api_key
    try:
        with urlopen(Request(url, headers=headers), timeout=TIMEOUT) as response:
            data = response.read(limit + 1)
    except HTTPError as error:
        if error.code == 401:
            raise ValueError('Wallhaven rejected the API key. Check it in Account.') from None
        if error.code == 429:
            raise ValueError('Wallhaven rate limit reached. Try again in a minute.') from None
        if error.code == 404:
            raise ValueError('Not found on Wallhaven.') from None
        raise ValueError(f'Wallhaven returned HTTP {error.code}.') from None
    except (URLError, TimeoutError, OSError):
        raise ValueError('Could not reach Wallhaven. Check your connection.') from None
    if len(data) > limit:
        raise ValueError('Wallhaven response was too large.')
    return data


def fetch_json(url, api_key=''):
    try:
        return json.loads(fetch(url, api_key))
    except json.JSONDecodeError:
        raise ValueError('Wallhaven returned an unreadable response.') from None


def wallpaper(entry):
    thumbs = entry.get('thumbs') or {}
    return {
        'id': str(entry.get('id', '')),
        'thumb': str(thumbs.get('large') or thumbs.get('small') or ''),
        'full': str(entry.get('path', '')),
        'resolution': str(entry.get('resolution', '')),
        'ratio': str(entry.get('ratio', '')),
        'fileType': str(entry.get('file_type', '')),
        'purity': str(entry.get('purity', '')),
    }


def listing(payload):
    meta = payload.get('meta') or {}
    items = [wallpaper(entry) for entry in payload.get('data') or [] if isinstance(entry, dict)]
    return {
        'items': [item for item in items if ID_PATTERN.match(item['id'])],
        'page': page_number(meta.get('current_page')),
        'lastPage': page_number(meta.get('last_page')),
        'total': meta.get('total') if isinstance(meta.get('total'), int) else len(items),
        'seed': meta.get('seed') if isinstance(meta.get('seed'), str) else '',
    }


def search_url(request, api_key):
    sorting = request.get('sorting') if request.get('sorting') in SORTINGS else 'toplist'
    params = {
        'q': str(request.get('q', ''))[:200],
        'categories': bits(request.get('categories'), '111'),
        'purity': purity(request.get('purity'), api_key),
        'sorting': sorting,
        'order': 'asc' if request.get('order') == 'asc' else 'desc',
        'page': page_number(request.get('page')),
    }
    if params['categories'] == '000':
        params['categories'] = '111'
    if sorting == 'toplist':
        params['topRange'] = request.get('topRange') if request.get('topRange') in TOP_RANGES else '1M'
    if sorting == 'random' and SEED_PATTERN.match(str(request.get('seed', ''))):
        params['seed'] = request['seed']
    if RESOLUTION_PATTERN.match(str(request.get('atleast', ''))):
        params['atleast'] = request['atleast']
    if not params['q']:
        del params['q']
    return API + '/search?' + urlencode(params)


def collection_url(request, api_key):
    username = str(request.get('username', ''))
    collection = request.get('collection')
    if not USERNAME_PATTERN.match(username):
        raise ValueError('Enter your Wallhaven username in Account.')
    if not isinstance(collection, int) or collection <= 0:
        raise ValueError('Choose a collection.')
    params = {'purity': purity(request.get('purity'), api_key), 'page': page_number(request.get('page'))}
    return f'{API}/collections/{quote(username)}/{collection}?' + urlencode(params)


def collections(api_key):
    if not api_key:
        raise ValueError('Add a Wallhaven API key to list your collections.')
    payload = fetch_json(API + '/collections', api_key)
    return {'collections': [
        {'id': entry['id'], 'label': str(entry.get('label', ''))[:100],
         'count': entry.get('count') if isinstance(entry.get('count'), int) else 0}
        for entry in payload.get('data') or []
        if isinstance(entry, dict) and isinstance(entry.get('id'), int)
    ]}


def download(request, target=None):
    identifier = str(request.get('id', ''))
    source = str(request.get('full', ''))
    url = urlsplit(source)
    extension = Path(url.path).suffix.lower()
    if not ID_PATTERN.match(identifier):
        raise ValueError('Invalid Wallhaven wallpaper.')
    if (url.scheme != 'https' or url.hostname != 'w.wallhaven.cc' or url.port
            or url.query or extension not in EXTENSIONS or identifier not in url.path):
        raise ValueError('Unexpected Wallhaven image address.')
    folder = Path(target) if target else download_dir()
    path = folder / f'wallhaven-{identifier}{extension}'
    if not path.is_file() or path.stat().st_size == 0:
        data = fetch(source, limit=MAX_DOWNLOAD)
        if not data:
            raise ValueError('Wallhaven returned an empty image.')
        folder.mkdir(parents=True, exist_ok=True)
        # Write beside the target, then rename so a partial file is never applied.
        handle, temporary = tempfile.mkstemp(prefix='.wallhaven-', dir=folder)
        try:
            with os.fdopen(handle, 'wb') as stream:
                stream.write(data)
            os.replace(temporary, path)
        except OSError:
            Path(temporary).unlink(missing_ok=True)
            raise ValueError(f'Could not save the wallpaper to {folder}.') from None
    return {'id': identifier, 'file': path.resolve().as_uri()}


def handle(request):
    if not isinstance(request, dict):
        raise ValueError('Invalid request.')
    api_key = request.get('apiKey') if isinstance(request.get('apiKey'), str) else ''
    api_key = api_key.strip()
    action = request.get('action')
    if action == 'search':
        return listing(fetch_json(search_url(request, api_key), api_key))
    if action == 'collection':
        return listing(fetch_json(collection_url(request, api_key), api_key))
    if action == 'collections':
        return collections(api_key)
    if action == 'download':
        return download(request)
    raise ValueError('Unknown Wallhaven action.')


if __name__ == '__main__':
    try:
        print(json.dumps(handle(json.load(sys.stdin))))
    except (ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
        print(json.dumps({'error': str(error)}))
        sys.exit(1)
