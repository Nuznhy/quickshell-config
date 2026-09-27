#!/usr/bin/env python3
"""Read NetworkManager connection metadata and IP addresses; never request secrets."""
import json

VPN_TYPES = {"vpn", "wireguard"}


def addresses(config):
    return [address.get_address() for address in config.get_addresses()] if config else []


def snapshot(client):
    if not client.get_nm_running():
        raise RuntimeError("NetworkManager is not running.")
    active = []
    for connection in client.get_active_connections():
        kind = connection.get_connection_type()
        if kind == "loopback":
            continue
        active.append({
            "uuid": connection.get_uuid(), "name": connection.get_id(), "type": kind,
            "vpn": kind in VPN_TYPES or connection.get_vpn(),
            "state": connection.get_state().value_nick,
            "devices": [device.get_iface() for device in connection.get_devices()],
            "ipv4": addresses(connection.get_ip4_config()),
            "ipv6": addresses(connection.get_ip6_config()),
        })
    profiles = []
    for connection in client.get_connections():
        if connection.get_connection_type() not in VPN_TYPES:
            continue
        current = next((item for item in active if item["uuid"] == connection.get_uuid()), None)
        profiles.append({
            "uuid": connection.get_uuid(), "name": connection.get_id(),
            "type": connection.get_connection_type(),
            "active": current is not None and current["state"] == "activated",
            "state": current["state"] if current else "disconnected",
        })
    return {"ok": True, "connections": active, "vpns": sorted(profiles, key=lambda p: p["name"].casefold())}


def main():
    try:
        import gi
        gi.require_version("NM", "1.0")
        from gi.repository import NM
        print(json.dumps(snapshot(NM.Client.new(None))))
    except (ImportError, ValueError):
        print(json.dumps({"ok": False, "error": "Install python-gobject and libnm for connection details."}))
    except Exception as error:
        print(json.dumps({"ok": False, "error": "Could not read NetworkManager: " + str(error)}))


if __name__ == "__main__":
    main()
