import QtQuick
import QtTest
import "components"
import "services"

Item {
    width: 460; height: 900
    NetworkCenter {
        id: center
        width: 430
        maximumHeight: 880
        active: true
    }
    TestCase {
        name: "NetworkCenter"
        when: windowShown
        function control(name) {
            const item = findChild(center, name);
            verify(item !== null, name + " exists");
            return item;
        }
        function init() {
            center.active = true;
            NetworkState.failAction = false;
            NetworkState.busy = false;
            NetworkState.wifiEnabled = true;
            NetworkState.passwordNetwork = null;
            NetworkState.wired.connected = true;
            NetworkState.vpnProfiles = [{uuid: "test-vpn", name: "Work VPN", active: false, state: "disconnected"}];
            NetworkState.lastAction = {};
            wait(50);
        }
        function test_wifi_toggle_and_failed_action() {
            const toggle = control("wifiToggle");
            mouseClick(toggle);
            compare(NetworkState.lastAction.kind, "wifi");
            compare(NetworkState.lastAction.enabled, false);
            compare(toggle.checked, false);
            NetworkState.failAction = true;
            mouseClick(toggle);
            compare(NetworkState.lastAction.enabled, true);
            compare(toggle.checked, false, "failed request keeps authoritative state");
        }
        function test_wired_and_vpn_controls() {
            mouseClick(control("wiredToggle"));
            compare(NetworkState.lastAction.kind, "wired");
            compare(NetworkState.lastAction.enabled, false);
            mouseClick(control("vpnToggle"));
            compare(NetworkState.lastAction.kind, "vpn");
            compare(NetworkState.lastAction.uuid, "test-vpn");
            compare(NetworkState.lastAction.enabled, true);
            wait(30);
            compare(control("vpnToggle").checked, true);
            mouseClick(control("vpnToggle"));
            compare(NetworkState.lastAction.enabled, false);
        }
        function test_password_cleared_on_submit_and_close() {
            mouseClick(control("connectWifi"));
            compare(NetworkState.passwordNetwork, NetworkState.wifi);
            const field = control("wifiPassword");
            field.text = "test-password";
            mouseClick(control("submitPassword"));
            compare(NetworkState.lastAction.kind, "password");
            compare(NetworkState.lastAction.supplied, true);
            compare(field.text, "");
            NetworkState.passwordNetwork = NetworkState.wifi;
            field.text = "another-test-password";
            center.active = false;
            compare(field.text, "");
            compare(NetworkState.passwordNetwork, null);
        }
        function test_busy_disables_actions() {
            NetworkState.busy = true;
            compare(control("wifiToggle").enabled, false);
            compare(control("wiredToggle").enabled, false);
            compare(control("vpnToggle").enabled, false);
            compare(control("connectWifi").enabled, false);
        }
        function test_toggle_alignment() {
            for (const name of ["wifiToggle", "wiredToggle", "vpnToggle"]) {
                const toggle = control(name);
                compare(toggle.width, 40);
                compare(toggle.indicator.x, 0);
                compare(toggle.indicator.y, (toggle.height - toggle.indicator.height) / 2);
                verify(Math.abs(toggle.parent.width - toggle.x - toggle.width) < 1,
                    name + " stays at the right edge of its row");
            }
        }
    }
}
