import importlib.util
import io
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
from urllib.parse import parse_qs, urlsplit

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('wallhaven', ROOT / 'scripts/wallpaper/wallhaven.py')
wallhaven = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wallhaven)

KEY = 'secret-key-123'
LISTING = {
    'data': [{
        'id': 'abc123', 'path': 'https://w.wallhaven.cc/full/ab/wallhaven-abc123.jpg',
        'thumbs': {'large': 'https://th.wallhaven.cc/lg/ab/abc123.jpg'},
        'resolution': '3840x2160', 'ratio': '1.78', 'file_type': 'image/jpeg', 'purity': 'sfw',
    }, {'id': '../bad'}],
    'meta': {'current_page': 2, 'last_page': 9, 'total': 200, 'seed': 'aB3dE6'},
}


class Response(io.BytesIO):
    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()


class Recorder:
    def __init__(self, payload=b'', error=None):
        self.payload = payload
        self.error = error
        self.requests = []

    def __call__(self, request, timeout):
        self.requests.append(request)
        if self.error:
            raise self.error
        return Response(self.payload)

    @property
    def query(self):
        return parse_qs(urlsplit(self.requests[-1].full_url).query)


def run(request, recorder):
    with patch.object(wallhaven, 'urlopen', recorder):
        return wallhaven.handle(request)


class SearchTests(unittest.TestCase):
    def test_builds_filters_and_normalizes_results(self):
        recorder = Recorder(json.dumps(LISTING).encode())
        result = run({'action': 'search', 'q': 'mountains', 'categories': '010', 'purity': '110',
                      'sorting': 'toplist', 'topRange': '1w', 'atleast': '2560x1440', 'page': 2}, recorder)
        query = recorder.query
        self.assertEqual(query['q'], ['mountains'])
        self.assertEqual(query['categories'], ['010'])
        self.assertEqual(query['purity'], ['110'])
        self.assertEqual(query['topRange'], ['1w'])
        self.assertEqual(query['atleast'], ['2560x1440'])
        self.assertEqual(query['page'], ['2'])
        self.assertEqual([item['id'] for item in result['items']], ['abc123'])
        self.assertEqual(result['items'][0]['thumb'], 'https://th.wallhaven.cc/lg/ab/abc123.jpg')
        self.assertEqual((result['page'], result['lastPage'], result['total']), (2, 9, 200))

    def test_rejects_invalid_filters(self):
        recorder = Recorder(json.dumps(LISTING).encode())
        run({'action': 'search', 'categories': '000', 'purity': 'x', 'sorting': 'evil',
             'atleast': '1920x1080&purity=111', 'page': -3}, recorder)
        query = recorder.query
        self.assertEqual(query['categories'], ['111'])
        self.assertEqual(query['purity'], ['100'])
        self.assertEqual(query['sorting'], ['toplist'])
        self.assertEqual(query['page'], ['1'])
        self.assertNotIn('atleast', query)
        self.assertNotIn('q', query)

    def test_random_pages_reuse_seed_only(self):
        recorder = Recorder(json.dumps(LISTING).encode())
        run({'action': 'search', 'sorting': 'random', 'seed': 'aB3dE6', 'page': 2}, recorder)
        self.assertEqual(recorder.query['seed'], ['aB3dE6'])
        self.assertNotIn('topRange', recorder.query)
        run({'action': 'search', 'sorting': 'top', 'seed': 'aB3dE6'}, recorder)
        self.assertNotIn('seed', recorder.query)

    def test_nsfw_requires_key_which_is_sent_only_as_header(self):
        recorder = Recorder(json.dumps(LISTING).encode())
        run({'action': 'search', 'purity': '001'}, recorder)
        self.assertEqual(recorder.query['purity'], ['100'])
        self.assertIsNone(recorder.requests[-1].get_header('X-api-key'))
        result = run({'action': 'search', 'purity': '111', 'apiKey': f' {KEY} '}, recorder)
        self.assertEqual(recorder.query['purity'], ['111'])
        self.assertEqual(recorder.requests[-1].get_header('X-api-key'), KEY)
        self.assertNotIn(KEY, recorder.requests[-1].full_url)
        self.assertNotIn(KEY, json.dumps(result))

    def test_http_errors_are_actionable_without_secrets(self):
        for code, text in ((401, 'API key'), (429, 'rate limit')):
            error = HTTPError('https://wallhaven.cc', code, 'error', {}, io.BytesIO())
            self.addCleanup(error.close)
            with self.assertRaises(ValueError) as caught:
                run({'action': 'search', 'apiKey': KEY}, Recorder(error=error))
            self.assertIn(text, str(caught.exception))
            self.assertNotIn(KEY, str(caught.exception))

    def test_unreadable_response(self):
        with self.assertRaisesRegex(ValueError, 'unreadable'):
            run({'action': 'search'}, Recorder(b'<html>'))


class CollectionTests(unittest.TestCase):
    def test_collections_require_key(self):
        with self.assertRaisesRegex(ValueError, 'API key'):
            run({'action': 'collections'}, Recorder())

    def test_lists_collections(self):
        payload = {'data': [{'id': 7, 'label': 'Favs', 'count': 3}, {'id': 'x', 'label': 'bad'}]}
        recorder = Recorder(json.dumps(payload).encode())
        result = run({'action': 'collections', 'apiKey': KEY}, recorder)
        self.assertEqual(result, {'collections': [{'id': 7, 'label': 'Favs', 'count': 3}]})
        self.assertEqual(urlsplit(recorder.requests[-1].full_url).path, '/api/v1/collections')

    def test_collection_listing_validates_owner(self):
        recorder = Recorder(json.dumps(LISTING).encode())
        result = run({'action': 'collection', 'username': 'me', 'collection': 7,
                      'purity': '111', 'page': 2, 'apiKey': KEY}, recorder)
        self.assertEqual(urlsplit(recorder.requests[-1].full_url).path, '/api/v1/collections/me/7')
        self.assertEqual(recorder.query['purity'], ['111'])
        self.assertEqual(result['items'][0]['id'], 'abc123')
        with self.assertRaisesRegex(ValueError, 'username'):
            run({'action': 'collection', 'username': '../me', 'collection': 7}, recorder)
        with self.assertRaisesRegex(ValueError, 'collection'):
            run({'action': 'collection', 'username': 'me', 'collection': '7'}, recorder)


class DownloadTests(unittest.TestCase):
    def setUp(self):
        self.folder = Path(tempfile.mkdtemp(prefix='wallhaven-test-'))
        self.addCleanup(shutil.rmtree, self.folder)

    def download(self, request, recorder):
        with patch.object(wallhaven, 'urlopen', recorder), patch.object(wallhaven, 'download_dir', lambda: self.folder):
            return wallhaven.handle(dict(request, action='download'))

    def test_downloads_once_and_reuses_file(self):
        request = {'id': 'abc123', 'full': 'https://w.wallhaven.cc/full/ab/wallhaven-abc123.png'}
        recorder = Recorder(b'image-bytes')
        result = self.download(request, recorder)
        path = self.folder / 'wallhaven-abc123.png'
        self.assertEqual(result, {'id': 'abc123', 'file': path.resolve().as_uri()})
        self.assertEqual(path.read_bytes(), b'image-bytes')
        self.assertEqual([p.name for p in self.folder.iterdir()], ['wallhaven-abc123.png'])
        self.download(request, recorder)
        self.assertEqual(len(recorder.requests), 1)

    def test_rejects_unexpected_sources(self):
        for full in ('http://w.wallhaven.cc/full/ab/wallhaven-abc123.jpg',
                     'https://evil.example/full/ab/wallhaven-abc123.jpg',
                     'https://w.wallhaven.cc:8443/full/ab/wallhaven-abc123.jpg',
                     'https://w.wallhaven.cc/full/ab/wallhaven-abc123.sh',
                     'https://w.wallhaven.cc/full/ab/wallhaven-other.jpg'):
            with self.subTest(full=full), self.assertRaisesRegex(ValueError, 'address'):
                self.download({'id': 'abc123', 'full': full}, Recorder(b'x'))
        with self.assertRaisesRegex(ValueError, 'Invalid'):
            self.download({'id': '../x', 'full': 'https://w.wallhaven.cc/full/x.jpg'}, Recorder(b'x'))

    def test_oversized_and_empty_downloads_leave_nothing(self):
        request = {'id': 'abc123', 'full': 'https://w.wallhaven.cc/full/ab/wallhaven-abc123.jpg'}
        with patch.object(wallhaven, 'MAX_DOWNLOAD', 4), self.assertRaisesRegex(ValueError, 'too large'):
            self.download(request, Recorder(b'12345'))
        with self.assertRaisesRegex(ValueError, 'empty'):
            self.download(request, Recorder(b''))
        self.assertEqual(list(self.folder.iterdir()), [])


if __name__ == '__main__':
    unittest.main()
