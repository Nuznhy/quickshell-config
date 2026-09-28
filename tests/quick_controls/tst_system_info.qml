import QtQuick
import QtTest
import "components"
import "services"
import "config"
import "widgets"

TestCase {
    id: testCase
    name: "SystemInfoAndBattery"
    width: 400; height: 680; visible: true
    when: windowShown
    SystemInfoPanel { id: info; width: 306; height: implicitHeight }
    BatteryCenter { id: battery; width: 360; y: 80; height: implicitHeight; visible: false }
    BatteryWidget { id: barBattery; y: 600; width: implicitWidth; height: implicitHeight }
    function init() {
        info.expanded = false; info.active = false; info.visible = true;
        battery.visible = false; battery.drafts = {};
        BatteryState.batteries = [];
        BatteryState.lastLimit = 0; Theme.verticalBar = false;
    }
    function test_collapsible_info_and_polling() {
        info.active = true;
        compare(SystemInfo.openPanels, 0);
        mouseClick(findChild(info, "system-info-expand"));
        verify(info.expanded);
        compare(SystemInfo.openPanels, 1);
        compare(BatteryState.openPanels, 1);
        wait(50);
        verify(info.implicitHeight > 200);
        grabImage(info).save('/tmp/quickshell-system-info.png');
        info.active = false;
        compare(SystemInfo.openPanels, 0);
        compare(BatteryState.openPanels, 0);
    }
    function test_battery_limit_requires_apply() {
        info.visible = false; battery.visible = true;
        BatteryState.batteries = [{id: "BAT0", model: "Laptop battery", percent: 72, status: "Charging", health: 91.2, cycles: 120, full: 45.6, design: 50, unit: "Wh", limitSupported: true, limit: 100, start: 95}];
        wait(50);
        let row = findChild(battery, "charge-limit-BAT0");
        verify(row.visible);
        battery.edit("BAT0", 80);
        compare(BatteryState.lastLimit, 0);
        mouseClick(findChild(battery, "apply-limit-BAT0"));
        compare(BatteryState.lastId, "BAT0");
        compare(BatteryState.lastLimit, 80);
        grabImage(battery).save('/tmp/quickshell-battery.png');
        // A refresh must retain a not-yet-applied draft.
        BatteryState.batteries = [Object.assign({}, BatteryState.batteries[0], {percent: 73})];
        wait(30);
        compare(findChild(battery, "charge-limit-BAT0").value, 80);
    }
    function test_bar_presence_and_orientation() {
        verify(!barBattery.visible);
        BatteryState.batteries = [{id: "BAT0", model: "Battery", percent: 72, status: "Charging", health: null, cycles: null, full: null, design: null, unit: "", limitSupported: false, limit: null}];
        verify(barBattery.visible);
        wait(50);
        let horizontalWidth = barBattery.implicitWidth;
        verify(horizontalWidth > 30);
        Theme.verticalBar = true;
        wait(50);
        verify(barBattery.implicitWidth < horizontalWidth);
        verify(barBattery.implicitHeight > 30);
        BatteryState.batteries = [];
        verify(!barBattery.visible);
    }
    function test_unsupported_hardware() {
        info.visible = false; battery.visible = true;
        BatteryState.batteries = [{id: "BAT0", model: "Battery", percent: null, status: "Unknown", health: null, cycles: null, full: null, design: null, unit: "", limitSupported: false, limit: null}];
        wait(50);
        verify(!findChild(battery, "charge-limit-BAT0").visible);
        verify(!findChild(battery, "apply-limit-BAT0").visible);
    }
}
