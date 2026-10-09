import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('brightness', Path(__file__).resolve().parents[2] / 'scripts/brightness.py')
brightness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(brightness)


class BrightnessTests(unittest.TestCase):
    def test_discovers_arbitrary_buses_and_unsupported_monitors(self):
        result = brightness.parse_displays('''Display 1
   I2C bus: /dev/i2c-24
   DRM connector: card2-DP-3
   Monitor: ABC:Portable:123
Invalid display
   I2C bus: /dev/i2c-31
   Monitor: XYZ:TV:
''')
        self.assertEqual([item['id'] for item in result], ['ddc:24', 'ddc:31'])
        self.assertEqual(result[0]['connection'], 'DP-3')
        self.assertFalse(result[1]['supported'])

    def test_scaled_ddc_write_and_unsupported_value(self):
        with patch.object(brightness, 'command', side_effect=['VCP 10 C 80 250', '']) as command:
            brightness.set_level('ddc:24', 60)
            self.assertEqual(command.call_args.args[0], ['ddcutil', '--bus', '24', 'setvcp', '10', '150'])
        with self.assertRaises(RuntimeError):
            brightness.parse_level('VCP 10 ERR')
        with self.assertRaises(ValueError):
            brightness.set_level('ddc:24', 101)

    def test_builtin_discovery_missing_ddc_and_minimum(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            device = root / 'vendor_panel'
            device.mkdir()
            (device / 'max_brightness').write_text('200')
            (device / 'brightness').write_text('50')
            with patch.object(brightness, 'BACKLIGHT', root), patch.object(brightness.shutil, 'which', side_effect=lambda name: '/bin/brightnessctl' if name == 'brightnessctl' else None):
                result = brightness.discover()
                self.assertEqual(result['displays'][0]['value'], 25)
                self.assertEqual(result['displays'][0]['id'], 'backlight:vendor_panel')
                self.assertIn('ddcutil', result['error'])
                with patch.object(brightness, 'command') as command:
                    brightness.set_level('backlight:vendor_panel', 0)
                    self.assertEqual(command.call_args.args[0][-1], '1')
                with self.assertRaises(ValueError):
                    brightness.set_level('backlight:../outside', 50)

    def test_value_checks_do_not_discover_or_change_capabilities(self):
        with patch.object(brightness, 'ddc_level', return_value=(75, 150)), patch.object(brightness, 'discover') as discover:
            result = brightness.read_levels(['ddc:24'])
            self.assertEqual(result, {'levels': [{'id': 'ddc:24', 'value': 50}]})
            discover.assert_not_called()
        with patch.object(brightness, 'ddc_level', side_effect=RuntimeError('temporarily busy')):
            result = brightness.read_levels(['ddc:24'])
            self.assertEqual(result, {'levels': [{'id': 'ddc:24', 'error': 'temporarily busy'}]})
        result = brightness.read_levels(['backlight:../outside'])
        self.assertIn('error', result['levels'][0])

    def test_one_monitor_failure_does_not_hide_other_controls(self):
        display = dict(id='ddc:44', supported=True, value=0)
        with patch.object(brightness, 'ddc_level', side_effect=RuntimeError('Disconnected')):
            result = brightness.read_display(display)
        self.assertFalse(result['supported'])
        self.assertEqual(result['error'], 'Disconnected')


if __name__ == '__main__':
    unittest.main()
