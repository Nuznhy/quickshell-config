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
        tryCompare(info, "revealProgress", 0);
        battery.visible = false; battery.drafts = {};
        BatteryState.batteries = [];
        BatteryState.powerProfiles = {available: false, current: "", profiles: []};
        BatteryState.lastProfile = ""; BatteryState.changing = false;
        BatteryState.actionKind = "limit";
        BatteryState.lastLimit = 0; Theme.verticalBar = false;
    }
    function test_collapsible_info_and_polling() {
        info.active = true;
        compare(SystemInfo.openPanels, 0);
        mouseClick(findChild(info, "system-info-expand"));
        verify(info.expanded);
        compare(SystemInfo.openPanels, 1);
        compare(BatteryState.openPanels, 1);
        tryCompare(info, "revealProgress", 1);
        verify(info.implicitHeight > 200);
        grabImage(info).save('/tmp/quickshell-system-info.png');
        info.active = false;
        compare(SystemInfo.openPanels, 0);
        compare(BatteryState.openPanels, 0);
    }
    function test_info_reveal_and_reversal() {
        const collapsedHeight = info.implicitHeight;
        info.active = true;
        info.expanded = true;
        tryVerify(() => info.revealProgress > 0 && info.revealProgress < 1);
        verify(info.implicitHeight > collapsedHeight);
        tryCompare(info, "revealProgress", 1);
        const expandedHeight = info.implicitHeight;
        info.expanded = false;
        compare(SystemInfo.openPanels, 0);
        tryVerify(() => info.revealProgress > 0 && info.revealProgress < 1);
        verify(info.implicitHeight < expandedHeight);
        verify(info.implicitHeight > collapsedHeight);
        // A second click reverses the running animation without snapping shut.
        const partial = info.revealProgress;
        info.expanded = true;
        compare(info.revealProgress, partial);
        tryCompare(info, "revealProgress", 1);
        info.expanded = false;
        tryCompare(info, "revealProgress", 0);
        tryCompare(info, "implicitHeight", collapsedHeight);
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
    function test_estimates_follow_status_and_limit() {
        info.visible = false; battery.visible = true;
        const base = {id: "BAT0", model: "Battery", percent: 50, health: null, cycles: null, full: null, design: null, unit: "", limitSupported: false, limit: null};
        const cases = [
            {status: "Charging", timeRemaining: 5400, chargeTarget: 100, expected: "Estimated until full: 1 h 30 min"},
            {status: "Charging", timeRemaining: 1800, chargeTarget: 80, expected: "Estimated to 80% limit: 30 min"},
            {status: "Discharging", timeRemaining: 7200, expected: "Estimated until empty: 2 h"},
            {status: "Discharging", timeRemaining: 30, expected: "Estimated until empty: less than 1 min"},
            {status: "Discharging", timeRemaining: null, expected: "Time until empty: unavailable"},
            {status: "Full", timeRemaining: 7200, expected: ""},
            {status: "Not charging", timeRemaining: 7200, expected: ""}
        ];
        for (const entry of cases) {
            BatteryState.batteries = [Object.assign({}, base, entry)];
            wait(10);
            const label = findChild(battery, "battery-estimate-BAT0");
            compare(label.text, entry.expected);
            compare(label.visible, entry.expected.length > 0);
        }
    }
    function test_power_profiles_selection_and_busy_state() {
        info.visible = false; battery.visible = true;
        BatteryState.batteries = [{id: "BAT0", model: "Laptop battery", percent: 72, status: "Charging", timeRemaining: 5400, chargeTarget: 80, health: 91.2, cycles: 120, full: 45.6, design: 50, unit: "Wh", limitSupported: true, limit: 80}];
        battery.edit("BAT0", 85);
        BatteryState.powerProfiles = {available: true, current: "balanced", profiles: [
            {id: "low-power", label: "Power saver"}, {id: "balanced", label: "Balanced"}, {id: "performance", label: "Performance"}]};
        wait(30);
        const performance = findChild(battery, "power-profile-performance");
        verify(findChild(battery, "power-profile-balanced").accent);
        mouseClick(performance);
        compare(BatteryState.lastProfile, "performance");
        verify(!performance.accent); // Wait for driver readback.
        BatteryState.powerProfiles = Object.assign({}, BatteryState.powerProfiles, {current: "performance"});
        verify(performance.accent);
        BatteryState.changing = true;
        verify(!performance.enabled);
        BatteryState.changing = false;
        compare(battery.drafts.BAT0, 85);
        grabImage(battery).save('/tmp/quickshell-battery-profiles.png');
        BatteryState.powerProfiles = {available: false, current: "", profiles: []};
        wait(10);
        verify(!findChild(battery, "power-profile-performance"));
    }
}
