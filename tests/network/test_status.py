"""Metadata tests with fake libnm objects; never alter system networking."""
import importlib.util
from pathlib import Path
from types import SimpleNamespace
import unittest

path = Path(__file__).resolve().parents[2] / 'scripts/network-status.py'
spec = importlib.util.spec_from_file_location('network_status', path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class Connection:
    def __init__(self, uuid, name, kind, state='activated', ipv4=(), ipv6=()):
        self.uuid, self.name, self.kind, self.state = uuid, name, kind, state
        self.ipv4, self.ipv6 = ipv4, ipv6
    def get_uuid(self): return self.uuid
    def get_id(self): return self.name
    def get_connection_type(self): return self.kind
    def get_state(self): return SimpleNamespace(value_nick=self.state)
    def get_vpn(self): return self.kind == 'vpn'
    def get_devices(self): return [SimpleNamespace(get_iface=lambda: 'eth0')]
    def config(self, ips): return SimpleNamespace(get_addresses=lambda: [SimpleNamespace(get_address=lambda ip=ip: ip) for ip in ips])
    def get_ip4_config(self): return self.config(self.ipv4)
    def get_ip6_config(self): return self.config(self.ipv6)


class StatusTests(unittest.TestCase):
    def test_multi_interface_and_vpns(self):
        wired = Connection('wired', 'LAN: "Office" \\ cable', '802-3-ethernet', ipv4=['192.0.2.7'], ipv6=['2001:db8::7'])
        wifi = Connection('wifi', 'Café: Wi-Fi', '802-11-wireless', ipv4=['198.51.100.8'])
        vpn = Connection('vpn', 'Work', 'vpn', state='activating')
        wireguard = Connection('wg', 'Private', 'wireguard', ipv4=['10.0.0.2'])
        offline = Connection('off', 'Saved VPN', 'vpn')
        loopback = Connection('lo', 'lo', 'loopback')
        client = SimpleNamespace(get_nm_running=lambda: True, get_active_connections=lambda: [wired, wifi, vpn, wireguard, loopback],
                                 get_connections=lambda: [wired, wifi, vpn, wireguard, offline, loopback])
        result = module.snapshot(client)
        self.assertEqual(len(result['connections']), 4)
        self.assertEqual(result['connections'][0]['name'], wired.name)
        self.assertEqual(result['connections'][0]['ipv6'], ['2001:db8::7'])
        self.assertEqual(result['connections'][1]['ipv4'], ['198.51.100.8'])
        by_id = {profile['uuid']: profile for profile in result['vpns']}
        self.assertEqual(set(by_id), {'vpn', 'wg', 'off'})
        self.assertTrue(by_id['wg']['active'])
        self.assertFalse(by_id['vpn']['active'])
        self.assertEqual(by_id['vpn']['state'], 'activating')
        self.assertFalse(by_id['off']['active'])
        self.assertEqual(by_id['off']['state'], 'disconnected')

    def test_daemon_unavailable(self):
        with self.assertRaisesRegex(RuntimeError, 'not running'):
            module.snapshot(SimpleNamespace(get_nm_running=lambda: False))

    def test_no_addresses_yet(self):
        self.assertEqual(module.addresses(None), [])


if __name__ == '__main__': unittest.main()
