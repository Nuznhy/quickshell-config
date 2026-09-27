import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('bluetooth_action', Path(__file__).resolve().parents[2] / 'scripts/bluetooth-action.py')
bt = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bt)
DEVICE = '/org/bluez/hci0/dev_11_22_33_44_55_66'


class Invocation:
    value = None
    error = None
    def return_value(self, value): self.value = value.unpack()
    def return_dbus_error(self, name, message): self.error = name


class AgentTests(unittest.TestCase):
    def setUp(self):
        self.messages = []
        self.agent = bt.PairingAgent(DEVICE, lambda **message: self.messages.append(message))

    def request(self, method, signature, args):
        invocation = Invocation()
        self.agent.handle(None, '', '', '', method, bt.GLib.Variant(signature, args), invocation)
        return invocation

    def test_confirmation_requires_explicit_response(self):
        invocation = self.request('RequestConfirmation', '(ou)', (DEVICE, 123))
        self.assertIsNone(invocation.value)
        self.assertEqual(self.messages[-1]['prompt']['code'], '000123')
        self.agent.respond({'id': self.agent.serial - 1, 'accepted': True})
        self.assertIsNone(invocation.value)
        self.agent.respond({'id': self.agent.serial, 'accepted': True})
        self.assertEqual(invocation.value, ())

    def test_reject_and_wrong_device(self):
        invocation = self.request('RequestAuthorization', '(o)', (DEVICE,))
        self.agent.respond({'id': self.agent.serial, 'accepted': False})
        self.assertEqual(invocation.error, 'org.bluez.Error.Rejected')
        unexpected = self.request('RequestAuthorization', '(o)', ('/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF',))
        self.assertEqual(unexpected.error, 'org.bluez.Error.Rejected')

    def test_pin_and_passkey_validation(self):
        invocation = self.request('RequestPasskey', '(o)', (DEVICE,))
        self.agent.respond({'id': self.agent.serial, 'accepted': True, 'value': 'oops'})
        self.assertIsNone(invocation.value)
        self.assertEqual(self.messages[-1]['type'], 'input-error')
        self.agent.respond({'id': self.agent.serial, 'accepted': True, 'value': '000123'})
        self.assertEqual(invocation.value, (123,))
        self.assertEqual(bt.answer_variant('pin', '12ab').unpack(), ('12ab',))
        for value in ['', '1' * 17]:
            with self.assertRaises(ValueError): bt.answer_variant('pin', value)

    def test_keyboard_display_and_cancel(self):
        invocation = self.request('DisplayPasskey', '(ouq)', (DEVICE, 987, 2))
        self.assertEqual(invocation.value, ())
        self.assertEqual(self.messages[-1]['prompt']['code'], '000987')
        self.assertEqual(self.messages[-1]['prompt']['entered'], 2)
        pending = self.request('RequestPinCode', '(o)', (DEVICE,))
        self.request('Cancel', '()', ())
        self.assertEqual(pending.error, 'org.bluez.Error.Rejected')
        self.assertIsNone(self.messages[-1]['prompt'])

    def test_discovery_visibility_timeout(self):
        with patch.object(bt.Gio, 'bus_get_sync') as get_bus:
            bt.run('discoverable', '/org/bluez/hci0', 'on')
            calls = get_bus.return_value.call_sync.call_args_list
            self.assertEqual([call.args[4].unpack() for call in calls], [
                ('org.bluez.Adapter1', 'DiscoverableTimeout', 180),
                ('org.bluez.Adapter1', 'Discoverable', True),
            ])
            get_bus.return_value.call_sync.reset_mock()
            bt.run('discoverable', '/org/bluez/hci0', 'off')
            calls = get_bus.return_value.call_sync.call_args_list
            self.assertEqual([call.args[4].unpack() for call in calls], [
                ('org.bluez.Adapter1', 'Discoverable', False),
            ])

    def test_paths_and_device_operations(self):
        bt.validate_path(DEVICE, True)
        for path in ['/org/bluez/hci0/dev_bad', '/org/bluez/hci0;command']:
            with self.assertRaises(ValueError): bt.validate_path(path, True)
        with patch.object(bt.Gio, 'bus_get_sync') as get_bus:
            bt.run('power', '/org/bluez/hci0', 'off')
            args = get_bus.return_value.call_sync.call_args.args
            self.assertEqual(args[2:4], ('org.freedesktop.DBus.Properties', 'Set'))
            self.assertEqual(args[4].unpack(), ('org.bluez.Adapter1', 'Powered', False))
            bt.run('disconnect', DEVICE)
            self.assertEqual(get_bus.return_value.call_sync.call_args.args[3], 'Disconnect')
            bt.run('forget', DEVICE)
            args = get_bus.return_value.call_sync.call_args.args
            self.assertEqual(args[1:4], ('/org/bluez/hci0', 'org.bluez.Adapter1', 'RemoveDevice'))
            self.assertEqual(args[4].unpack(), (DEVICE,))


if __name__ == '__main__': unittest.main()
