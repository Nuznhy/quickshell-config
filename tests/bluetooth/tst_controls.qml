import QtQuick
import QtTest
import "components"
import "services"
Item {
    width: 460; height: 1000
    BluetoothCenter { id: center; width: 430; maximumHeight: 900; active: true }
    TestCase {
        name: "BluetoothCenter"
        when: windowShown
        function control(name) {
            const item = findChild(center, name);
            verify(item !== null, name + " exists");
            return item;
        }
        function init() {
            BluetoothState.enabled = true;
            BluetoothState.discoverable = false;
            BluetoothState.available = true;
            BluetoothState.busy = false;
            BluetoothState.blocked = false;
            BluetoothState.prompt = null;
            BluetoothState.lastAction = {};
            center.active = true;
            center.forgetTarget = null;
            wait(30);
        }
        function test_power_and_alignment() {
            const toggle = control("bluetoothPower");
            compare(toggle.width, 40);
            compare(toggle.indicator.x, 0);
            verify(Math.abs(toggle.parent.width - toggle.x - toggle.width) < 1);
            mouseClick(toggle);
            compare(BluetoothState.lastAction.kind, "power");
            compare(BluetoothState.enabled, false);
        }
        function test_scan_and_connect() {
            mouseClick(control("scanButton"));
            compare(BluetoothState.lastAction.kind, "scan");
            mouseClick(control("deviceAction"));
            compare(BluetoothState.lastAction.kind, "connect");
        }
        function test_allow_discovery() {
            const toggle = control("allowDiscovery");
            mouseClick(toggle);
            compare(BluetoothState.discoverable, true);
            compare(BluetoothState.lastAction.kind, "discoverable");
            mouseClick(toggle);
            compare(BluetoothState.discoverable, false);
            BluetoothState.enabled = false;
            compare(toggle.enabled, false);
        }
        function test_forget_requires_confirmation() {
            mouseClick(control("forgetDevice"));
            compare(BluetoothState.lastAction.kind, undefined);
            compare(center.forgetTarget, BluetoothState.device);
            mouseClick(control("confirmForget"));
            compare(BluetoothState.lastAction.kind, "forget");
            compare(center.forgetTarget, null);
        }
        function test_pairing_input_and_close() {
            BluetoothState.prompt = { id: 1, kind: "pin", code: "" };
            const input = control("pairingInput");
            input.text = "1234";
            wait(30);
            mouseClick(control("confirmPairing"));
            compare(BluetoothState.lastAction.kind, "response");
            compare(BluetoothState.lastAction.accepted, true);
            compare(BluetoothState.lastAction.supplied, true);
            compare(input.text, "");
            BluetoothState.prompt = { id: 2, kind: "pin", code: "" };
            input.text = "9876";
            center.active = false;
            compare(input.text, "");
        }
        function test_unavailable_and_busy() {
            BluetoothState.available = false;
            compare(control("bluetoothPower").enabled, false);
            BluetoothState.available = true;
            BluetoothState.busy = true;
            compare(control("scanButton").enabled, false);
            compare(control("deviceAction").enabled, false);
        }
    }
}
