import QtQuick
import QtTest
import "modules/bar"
import "config"

Item {
    width: 900; height: 650
    QtObject { id: fakeBar; signal closeAllPopups }
    BarSection { id: section; section: "start"; barWindow: fakeBar; width: 300; height: 300 }
    TestCase {
        name: "BarSection"
        when: windowShown
        function init() {
            BarLayout.reset();
            Theme.verticalBar = false;
            section.width = 300;
            section.height = 300;
            BarLayout.showMedia = true;
            BarLayout.showWorkspaces = true;
            wait(30);
        }
        function test_spacing_and_conditional_return() {
            compare(section.naturalLength, 3 * 30 + 2 * 12);
            BarLayout.showMedia = false;
            tryCompare(section, "naturalLength", 2 * 30 + 12);
            BarLayout.showWorkspaces = false;
            tryCompare(section, "naturalLength", 30);
            BarLayout.showMedia = true;
            tryCompare(section, "naturalLength", 2 * 30 + 12);
            BarLayout.showWorkspaces = true;
            tryCompare(section, "naturalLength", 3 * 30 + 2 * 12);
        }
        function test_disabled_and_empty_section() {
            for (const id of BarLayout.ids("start")) BarLayout.setEnabled(id, false);
            tryCompare(section, "naturalLength", 0);
            BarLayout.setEnabled("tray", true);
            tryCompare(section, "naturalLength", 30);
        }
        function test_overflow_scrolls_in_both_orientations() {
            section.width = 70;
            tryCompare(section, "overflowing", true);
            compare(section.contentWidth, section.naturalLength);
            Theme.verticalBar = true;
            section.height = 70;
            tryCompare(section, "overflowing", true);
            compare(section.contentHeight, section.naturalLength);
        }
        function test_repeated_orientation_changes() {
            for (let i = 0; i < 3; ++i) {
                Theme.verticalBar = true;
                tryCompare(section, "naturalLength", 3 * 42 + 2 * 12);
                Theme.verticalBar = false;
                tryCompare(section, "naturalLength", 3 * 30 + 2 * 12);
            }
        }
    }
}
