import QtQuick
import QtTest
import "components"
import "config"

Rectangle {
    width: 600; height: 480
    color: Theme.bg
    BarFontPicker { id: picker; x: 20; y: 20; width: 560 }
    TestCase {
        name: "BarFont"
        when: windowShown
        function init() { Theme.setBarFontFamily(Theme.defaultBarFontFamily); }
        function cleanup() { picker.expanded = false; picker.visible = true; wait(180); }
        function test_trigger_toggles_and_hiding_closes() {
            const trigger = findChild(picker, "bar-font-picker");
            mouseClick(trigger);
            tryCompare(findChild(picker, "bar-font-search"), "activeFocus", true);
            verify(picker.expanded);
            mouseClick(trigger);
            compare(picker.expanded, false);
            wait(180);
            mouseClick(trigger);
            tryCompare(findChild(picker, "bar-font-search"), "activeFocus", true);
            picker.visible = false;
            compare(picker.expanded, false);
        }
        function test_outside_click_closes() {
            mouseClick(findChild(picker, "bar-font-picker"));
            tryCompare(findChild(picker, "bar-font-search"), "activeFocus", true);
            mouseClick(picker.parent, 590, 470);
            tryCompare(picker, "expanded", false);
        }
        function test_search_and_select_with_keyboard() {
            const family = picker.families.find(name => name !== Theme.defaultBarFontFamily);
            verify(!!family);
            mouseClick(findChild(picker, "bar-font-picker"));
            const search = findChild(picker, "bar-font-search");
            tryCompare(search, "activeFocus", true);
            search.text = family;
            const choices = findChild(picker, "bar-font-choices");
            tryVerify(() => choices.count > 0);
            compare(picker.matches[0], family);
            keyClick(Qt.Key_Return);
            compare(Theme.barFontFamily, family);
            mouseClick(findChild(picker, "bar-font-reset"));
            compare(Theme.barFontFamily, Theme.defaultBarFontFamily);
        }
        function test_no_results_does_not_change_font() {
            mouseClick(findChild(picker, "bar-font-picker"));
            const search = findChild(picker, "bar-font-search");
            tryCompare(search, "activeFocus", true);
            search.text = "no-such-font-123456789";
            compare(picker.matches.length, 0);
            keyClick(Qt.Key_Return);
            compare(Theme.barFontFamily, Theme.defaultBarFontFamily);
            keyClick(Qt.Key_Escape);
        }
        function test_escape_preserves_selection() {
            mouseClick(findChild(picker, "bar-font-picker"));
            tryCompare(findChild(picker, "bar-font-search"), "activeFocus", true);
            keyClick(Qt.Key_Down);
            keyClick(Qt.Key_Down);
            keyClick(Qt.Key_Escape);
            compare(Theme.barFontFamily, Theme.defaultBarFontFamily);
        }
    }
}
