#!/usr/bin/env python3
"""A short-lived BlueZ operation and pairing agent, controlled by JSON over stdin."""
import json
import re
import sys
import gi
from gi.repository import Gio, GLib

AGENT_PATH = '/org/quickshell/PairingAgent'
AGENT_XML = '''<node><interface name="org.bluez.Agent1">
<method name="Release"/><method name="Cancel"/>
<method name="RequestPinCode"><arg type="o" direction="in"/><arg type="s" direction="out"/></method>
<method name="RequestPasskey"><arg type="o" direction="in"/><arg type="u" direction="out"/></method>
<method name="DisplayPinCode"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
<method name="DisplayPasskey"><arg type="o" direction="in"/><arg type="u" direction="in"/><arg type="q" direction="in"/></method>
<method name="RequestConfirmation"><arg type="o" direction="in"/><arg type="u" direction="in"/></method>
<method name="RequestAuthorization"><arg type="o" direction="in"/></method>
<method name="AuthorizeService"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
</interface></node>'''


def emit(**message):
    print(json.dumps(message), flush=True)


def validate_path(path, device=False):
    pattern = r'/org/bluez/hci\d+/dev_(?:[0-9A-Fa-f]{2}_){5}[0-9A-Fa-f]{2}' if device else r'/org/bluez/hci\d+'
    if not re.fullmatch(pattern, path):
        raise ValueError('Invalid Bluetooth object path.')


def answer_variant(kind, value):
    if kind == 'pin':
        if not isinstance(value, str) or not 1 <= len(value) <= 16:
            raise ValueError('Enter a PIN of 1–16 characters.')
        return GLib.Variant('(s)', (value,))
    if kind == 'passkey':
        if not isinstance(value, str) or not re.fullmatch(r'[0-9]{1,6}', value):
            raise ValueError('Enter a numeric passkey of up to six digits.')
        return GLib.Variant('(u)', (int(value),))
    return GLib.Variant('()', ())


class PairingAgent:
    def __init__(self, device, send=emit):
        self.device, self.send = device, send
        self.pending = None
        self.kind = ''
        self.serial = 0

    def reject(self):
        if self.pending:
            self.pending.return_dbus_error('org.bluez.Error.Rejected', 'Pairing request rejected.')
            self.pending = None

    def handle(self, connection, sender, object_path, interface, method, parameters, invocation):
        args = parameters.unpack()
        if method in ('Cancel', 'Release'):
            self.reject()
            self.send(type='prompt', prompt=None)
            invocation.return_value(GLib.Variant('()', ()))
            return
        if not args or args[0] != self.device:
            invocation.return_dbus_error('org.bluez.Error.Rejected', 'Unexpected device.')
            return
        self.serial += 1
        if method in ('DisplayPinCode', 'DisplayPasskey'):
            code = args[1] if method == 'DisplayPinCode' else f'{args[1]:06d}'
            self.send(type='prompt', prompt={'id': self.serial, 'kind': 'display', 'code': code,
                      'entered': args[2] if method == 'DisplayPasskey' else 0})
            invocation.return_value(GLib.Variant('()', ()))
            return
        kinds = {'RequestPinCode': 'pin', 'RequestPasskey': 'passkey', 'RequestConfirmation': 'confirm',
                 'RequestAuthorization': 'authorize', 'AuthorizeService': 'authorize'}
        if method not in kinds:
            invocation.return_dbus_error('org.bluez.Error.Rejected', 'Unsupported pairing request.')
            return
        self.reject()
        self.pending, self.kind = invocation, kinds[method]
        self.send(type='prompt', prompt={'id': self.serial, 'kind': self.kind,
                  'code': f'{args[1]:06d}' if method == 'RequestConfirmation' else ''})

    def respond(self, response):
        if not self.pending or response.get('id') != self.serial:
            return
        if response.get('accepted') is not True:
            self.reject()
        else:
            try:
                value = answer_variant(self.kind, response.get('value', ''))
            except ValueError as error:
                self.send(type='input-error', error=str(error))
                return
            self.pending.return_value(value)
            self.pending = None
        self.send(type='prompt', prompt=None)


def run(action, path, value=''):
    validate_path(path, action not in ('power', 'discoverable'))
    bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
    def call(target, interface, method, params=None, timeout=15000):
        return bus.call_sync('org.bluez', target, interface, method, params, None,
                             Gio.DBusCallFlags.NONE, timeout, None)
    if action in ('power', 'discoverable'):
        if value not in ('on', 'off'): raise ValueError('Invalid power state.')
        if action == 'discoverable' and value == 'on':
            call(path, 'org.freedesktop.DBus.Properties', 'Set',
                 GLib.Variant('(ssv)', ('org.bluez.Adapter1', 'DiscoverableTimeout', GLib.Variant('u', 180))))
        call(path, 'org.freedesktop.DBus.Properties', 'Set',
             GLib.Variant('(ssv)', ('org.bluez.Adapter1', 'Powered' if action == 'power' else 'Discoverable', GLib.Variant('b', value == 'on'))))
    elif action == 'forget':
        call(path.split('/dev_')[0], 'org.bluez.Adapter1', 'RemoveDevice', GLib.Variant('(o)', (path,)))
    elif action == 'disconnect':
        call(path, 'org.bluez.Device1', 'Disconnect')
    elif action in ('pair', 'connect'):
        loop = GLib.MainLoop()
        agent = PairingAgent(path)
        info = Gio.DBusNodeInfo.new_for_xml(AGENT_XML).interfaces[0]
        registration = bus.register_object(AGENT_PATH, info, agent.handle, None, None)
        call('/org/bluez', 'org.bluez.AgentManager1', 'RegisterAgent',
             GLib.Variant('(os)', (AGENT_PATH, 'KeyboardDisplay')))
        errors = []
        def completed(connection, result, data):
            try: connection.call_finish(result)
            except GLib.Error as error: errors.append(error.message)
            loop.quit()
        def input_ready(source, condition):
            line = sys.stdin.readline()
            try: response = json.loads(line) if line else {'cancel': True}
            except ValueError: return True
            if response.get('cancel'):
                agent.reject()
                if action == 'pair':
                    try: call(path, 'org.bluez.Device1', 'CancelPairing', timeout=2000)
                    except GLib.Error: pass
                errors.append('Bluetooth operation canceled.')
                loop.quit()
                return False
            agent.respond(response)
            return True
        GLib.io_add_watch(sys.stdin, GLib.IO_IN | GLib.IO_HUP, input_ready)
        bus.call('org.bluez', path, 'org.bluez.Device1', 'Pair' if action == 'pair' else 'Connect',
                 None, None, Gio.DBusCallFlags.NONE, 120000 if action == 'pair' else 45000, None, completed, None)
        try:
            loop.run()
        finally:
            agent.reject()
            try: call('/org/bluez', 'org.bluez.AgentManager1', 'UnregisterAgent', GLib.Variant('(o)', (AGENT_PATH,)))
            except GLib.Error: pass
            bus.unregister_object(registration)
        if errors: raise RuntimeError(errors[0])
    else:
        raise ValueError('Unsupported Bluetooth operation.')


if __name__ == '__main__':
    try:
        run(*sys.argv[1:])
        emit(type='result', ok=True)
    except Exception as error:
        emit(type='result', ok=False, error=str(error))
        sys.exit(1)
