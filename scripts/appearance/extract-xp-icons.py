#!/usr/bin/env python3
"""Extract original PNG artwork from the Windows XP SVG reference sheets."""
import argparse
import base64
import json
from pathlib import Path
import struct
import xml.etree.ElementTree as ET


def extract(source, destination):
    manifest = json.loads((destination / 'sources.json').read_text())
    sheets = {}
    count = 0
    for name, entry in manifest.items():
        sheet = entry['sheet']
        if sheet not in sheets:
            root = ET.parse(source / sheet).getroot()
            sheets[sheet] = {image.get('id'): image for image in
                             root.findall('.//{http://www.w3.org/2000/svg}image')}
        for size, image_id in entry['images'].items():
            image = sheets[sheet][image_id]
            href = image.get('{http://www.w3.org/1999/xlink}href', '')
            if not href.startswith('data:image/png;base64,'):
                raise ValueError(f'{sheet}: {image_id} is not an embedded PNG')
            data = base64.b64decode(href.split(',', 1)[1], validate=True)
            if data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', data[16:24]) != (int(size), int(size)):
                raise ValueError(f'{sheet}: unexpected dimensions for {image_id}')
            folder = destination / size
            folder.mkdir(exist_ok=True)
            (folder / f'{name}.png').write_bytes(data)
            count += 1
    print(f'Extracted {count} original icons into {destination}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path, help='Directory containing the supplied SVG sheets')
    parser.add_argument('--destination', type=Path, default=Path(__file__).resolve().parents[2] / 'kits/windowsxp/icons')
    args = parser.parse_args()
    extract(args.source, args.destination)
