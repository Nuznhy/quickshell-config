import QtQuick
import QtTest
import "config/BarLayoutData.js" as Data

TestCase {
    name: "BarLayoutData"
    function test_default_layout() {
        const value = Data.defaults();
        compare(value.sections.start, ["workspaces", "tray", "media"]);
        compare(value.sections.center, ["clock"]);
        compare(value.sections.end.length, 11);
        compare(value.disabled, ["monitoring"]);
    }
    function test_normalize_repairs_ids() {
        const value = Data.defaults();
        value.sections.start = ["clock", "clock", "unknown"];
        value.sections.center = [];
        value.disabled = ["clock", "clock", "unknown"];
        const repaired = Data.normalize(value);
        compare(repaired.sections.start, ["clock", "workspaces", "tray", "media"]);
        compare(repaired.sections.center, []);
        compare(repaired.disabled, ["clock"]);
        const all = [].concat(repaired.sections.start, repaired.sections.center, repaired.sections.end);
        compare(new Set(all).size, 15);
    }
    function test_invalid_state() {
        for (const value of [null, {}, {version: 2}, {version: 1, sections: {start: []}}]) {
            let failed = false;
            try { Data.normalize(value); } catch (error) { failed = true; }
            verify(failed);
        }
    }
    function test_move_boundaries_and_empty_section() {
        const original = Data.defaults();
        let value = Data.move(original, "workspaces", "start", 3);
        compare(value.sections.start, ["tray", "media", "workspaces"]);
        value = Data.move(value, "workspaces", "start", 0);
        compare(value.sections.start, original.sections.start);
        value = Data.move(value, "clock", "end", 0);
        compare(value.sections.center, []);
        value = Data.move(value, "tray", "center", 0);
        compare(value.sections.center, ["tray"]);
        compare(original.sections.center, ["clock"], "operations do not mutate old state");
    }
    function test_disabled_position_roundtrip() {
        let value = Data.setEnabled(Data.defaults(), "clock", false);
        value = Data.move(value, "clock", "start", 1);
        value = Data.normalize(JSON.parse(JSON.stringify(value)));
        compare(value.sections.start[1], "clock");
        compare(value.disabled, ["monitoring", "clock"]);
        value = Data.setEnabled(value, "clock", true);
        compare(value.sections.start[1], "clock");
        compare(value.disabled, ["monitoring"]);
    }
    function test_monitoring_added_without_changing_existing_widgets() {
        const old = Data.defaults();
        old.sections.end = old.sections.end.filter(id => id !== "monitoring");
        old.disabled = ["cpu"];
        const migrated = Data.normalize(old);
        compare(migrated.disabled, ["cpu", "monitoring"]);
        compare(migrated.sections.end.slice(0, -1), old.sections.end);
        const enabled = Data.setEnabled(migrated, "monitoring", true);
        verify(!Data.normalize(enabled).disabled.includes("monitoring"));
    }
}
