import importlib.util
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch

spec = importlib.util.spec_from_file_location('system_info', Path(__file__).resolve().parents[2]/'scripts/system-info.py')
info = importlib.util.module_from_spec(spec)
spec.loader.exec_module(info)

class InfoTests(unittest.TestCase):
    def test_update_counts_and_errors(self):
        with patch.object(info.shutil, 'which', return_value='/usr/bin/checkupdates'):
            for code, output, count in [(0, 'foo 1 -> 2\nbar 2 -> 3\n', 2), (2, '', 0), (1, '', None)]:
                runner = Mock(return_value=subprocess.CompletedProcess([], code, output, ''))
                result = info.updates(runner)
                self.assertEqual(result['count'], count)
                self.assertEqual(bool(result['error']), code == 1)
                self.assertEqual(runner.call_args.args[0], ['checkupdates', '--nocolor'])

    def test_missing_update_tool(self):
        with patch.object(info.shutil, 'which', return_value=None):
            self.assertIn('pacman-contrib', info.updates()['error'])

    def test_installed_and_usable_memory(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(info.shutil, 'which', return_value=None):
            root = Path(directory)
            proc = root/'meminfo'; proc.write_text('MemTotal:       65000000 kB\n')
            entry = root/'17-0'; entry.mkdir()
            raw = bytearray(40); struct.pack_into('<H', raw, 12, 0x7fff); struct.pack_into('<I', raw, 28, 65536)
            (entry/'raw').write_bytes(raw)
            self.assertIn('64.0 GiB installed', info.memory(proc, root))
            (entry/'raw').write_bytes(b'truncated')
            self.assertTrue(info.memory(proc, root).endswith('usable'))
            self.assertNotIn('installed', info.memory(proc, root))

    def test_udev_installed_capacity(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            proc = root/'meminfo'; proc.write_text('MemTotal: 65000000 kB\n')
            result = subprocess.CompletedProcess([], 0, 'MEMORY_DEVICE_0_SIZE=34359738368\nMEMORY_DEVICE_1_SIZE=34359738368\nMEMORY_ARRAY_MAX_CAPACITY=137438953472\n', '')
            with patch.object(info.shutil, 'which', return_value='/usr/bin/udevadm'), patch.object(info.subprocess, 'run', return_value=result):
                self.assertIn('64.0 GiB installed', info.memory(proc, root))

if __name__ == '__main__': unittest.main()
