import QtQuick
import QtTest
import qs.config as ConfigScripts

TestCase {
    name: "BarLayoutData"
    function test_default_layout() {
        const value = ConfigScripts.BarLayoutData.defaults();
        compare(value.sections.start, ["workspaces", "tray", "media"]);
        compare(value.sections.center, ["clock"]);
        compare(value.sections.end.length, 15);
        compare(value.disabled, ["monitoring", "battery"]);
    }
    function test_normalize_repairs_ids() {
        const value = ConfigScripts.BarLayoutData.defaults();
        value.sections.start = ["clock", "clock", "unknown"];
        value.sections.center = [];
        value.disabled = ["clock", "clock", "unknown"];
        const repaired = ConfigScripts.BarLayoutData.normalize(value);
        compare(repaired.sections.start, ["clock", "workspaces", "tray", "media"]);
        compare(repaired.sections.center, []);
        compare(repaired.disabled, ["clock"]);
        const all = [].concat(repaired.sections.start, repaired.sections.center, repaired.sections.end);
        compare(new Set(all).size, ConfigScripts.BarLayoutData.widgets.length);
    }
    function test_invalid_state() {
        for (const value of [null,
            {},
            {
                version: 2
            },
            {
                version: 1,
                sections: {
                    start: []
                }
            }
        ]) {
            let failed = false;
            try {
                ConfigScripts.BarLayoutData.normalize(value);
            } catch (error) {
                failed = true;
            }
            verify(failed);
        }
    }
    function test_move_boundaries_and_empty_section() {
        const original = ConfigScripts.BarLayoutData.defaults();
        let value = ConfigScripts.BarLayoutData.move(original, "workspaces", "start", 3);
        compare(value.sections.start, ["tray", "media", "workspaces"]);
        value = ConfigScripts.BarLayoutData.move(value, "workspaces", "start", 0);
        compare(value.sections.start, original.sections.start);
        value = ConfigScripts.BarLayoutData.move(value, "clock", "end", 0);
        compare(value.sections.center, []);
        value = ConfigScripts.BarLayoutData.move(value, "tray", "center", 0);
        compare(value.sections.center, ["tray"]);
        compare(original.sections.center, ["clock"], "operations do not mutate old state");
    }
    function test_disabled_position_roundtrip() {
        let value = ConfigScripts.BarLayoutData.setEnabled(ConfigScripts.BarLayoutData.defaults(), "clock", false);
        value = ConfigScripts.BarLayoutData.move(value, "clock", "start", 1);
        value = ConfigScripts.BarLayoutData.normalize(JSON.parse(JSON.stringify(value)));
        compare(value.sections.start[1], "clock");
        compare(value.disabled, ["monitoring", "battery", "clock"]);
        value = ConfigScripts.BarLayoutData.setEnabled(value, "clock", true);
        compare(value.sections.start[1], "clock");
        compare(value.disabled, ["monitoring", "battery"]);
    }
    function test_monitoring_added_without_changing_existing_widgets() {
        const old = ConfigScripts.BarLayoutData.defaults();
        old.sections.end = old.sections.end.filter(id => id !== "monitoring");
        old.disabled = ["cpu"];
        const migrated = ConfigScripts.BarLayoutData.normalize(old);
        compare(migrated.disabled, ["cpu", "monitoring"]);
        compare(migrated.sections.end.slice(0, -1), old.sections.end);
        const enabled = ConfigScripts.BarLayoutData.setEnabled(migrated, "monitoring", true);
        verify(!ConfigScripts.BarLayoutData.normalize(enabled).disabled.includes("monitoring"));
    }
    function test_battery_added_disabled() {
        const old = ConfigScripts.BarLayoutData.defaults();
        old.sections.end = old.sections.end.filter(id => id !== "battery");
        old.disabled = ["monitoring"];
        const next = ConfigScripts.BarLayoutData.normalize(old);
        compare(next.disabled, ["monitoring", "battery"]);
        compare(next.sections.end.slice(0, -1), old.sections.end);
        verify(!ConfigScripts.BarLayoutData.setEnabled(next, "battery", true).disabled.includes("battery"));
    }
    function test_theme_mode_added_and_can_be_hidden() {
        const old = ConfigScripts.BarLayoutData.defaults();
        old.sections.end = old.sections.end.filter(id => id !== "theme-mode");
        const next = ConfigScripts.BarLayoutData.normalize(old);
        compare(next.sections.end.slice(0, -1), old.sections.end);
        compare(next.sections.end[next.sections.end.length - 1], "theme-mode");
        verify(!next.disabled.includes("theme-mode"));
        verify(ConfigScripts.BarLayoutData.setEnabled(next, "theme-mode", false).disabled.includes("theme-mode"));
    }
}
