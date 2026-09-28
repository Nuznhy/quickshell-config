import QtQuick
import QtTest
import "modules/settings"
import "config"

Item {
    width: 900; height: 620
    BarLayoutEditor { id: editor; anchors.fill: parent; anchors.margins: 20 }
    TestCase {
        name: "BarLayoutEditor"
        when: windowShown
        function control(name) {
            const result = findChild(editor, name);
            verify(result !== null, name);
            return result;
        }
        function init() {
            editor.cancelDrag();
            BarLayout.reset();
            Theme.verticalBar = false;
            wait(40);
        }
        function dragTo(id, section, y) {
            const handle = control("drag-" + id);
            const lane = control("lane-" + section);
            const to = lane.mapToItem(handle, 30, y);
            mousePress(handle, 20, 20);
            mouseMove(handle, 40, 20, 30);
            verify(editor.dragging);
            mouseMove(handle, to.x, to.y, 30);
            compare(editor.destination, section);
            mouseRelease(handle, to.x, to.y);
            wait(40);
        }
        function test_switch_preserves_slot() {
            mouseClick(control("toggle-clock"));
            verify(!BarLayout.isEnabled("clock"));
            compare(BarLayout.ids("center"), ["clock"]);
            mouseClick(control("toggle-clock"));
            verify(BarLayout.isEnabled("clock"));
        }
        SignalSpy { id: settingsSpy; target: editor; signalName: "settingsRequested" }
        function test_monitoring_gear_does_not_drag_or_toggle() {
            settingsSpy.clear();
            verify(!BarLayout.isEnabled("monitoring"));
            mouseClick(control("settings-monitoring"));
            compare(settingsSpy.count, 1);
            compare(settingsSpy.signalArguments[0][0], "monitoring");
            verify(!editor.dragging);
            verify(!BarLayout.isEnabled("monitoring"));
        }
        function test_drag_between_sections_and_empty_target() {
            dragTo("clock", "start", 70);
            compare(BarLayout.ids("start"), ["workspaces", "clock", "tray", "media"]);
            compare(BarLayout.ids("center"), []);
            dragTo("tray", "center", 20);
            compare(BarLayout.ids("center"), ["tray"]);
        }
        function test_drag_reorder() {
            dragTo("workspaces", "start", 210);
            compare(BarLayout.ids("start"), ["tray", "media", "workspaces"]);
        }
        function test_cancel_escape_and_outside_drop() {
            const handle = control("drag-clock");
            mousePress(handle, 10, 10);
            mouseMove(handle, 35, 10, 30);
            verify(editor.dragging);
            keyClick(Qt.Key_Escape);
            verify(!editor.dragging);
            mouseRelease(handle, 35, 10);
            compare(BarLayout.ids("center"), ["clock"]);
            mousePress(handle, 10, 10);
            mouseMove(handle, 35, 10, 30);
            const outside = editor.mapToItem(handle, 2, 2);
            mouseMove(handle, outside.x, outside.y, 30);
            mouseRelease(handle, outside.x, outside.y);
            compare(BarLayout.ids("center"), ["clock"]);
        }
        function test_vertical_and_reset() {
            Theme.verticalBar = true;
            dragTo("clock", "start", 10);
            BarLayout.setEnabled("settings", false);
            mouseClick(control("resetLayout"));
            compare(BarLayout.ids("center"), ["clock"]);
            verify(BarLayout.isEnabled("settings"));
        }
    }
}
