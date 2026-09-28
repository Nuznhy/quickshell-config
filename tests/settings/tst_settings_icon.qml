import QtQuick
import QtTest
import "components"
import "config"

Rectangle {
    width: 600; height: 260
    color: Theme.bg
    SettingsIconEditor { id: editor; x: 20; y: 20; width: 560 }
    TestCase {
        name: "SettingsIcon"
        when: windowShown
        function init() { editor.selectPreset(0); wait(20); }
        function test_presets_hide_custom_input() {
            const input = findChild(editor, "settings-icon-glyph");
            compare(input.visible, false);
            mouseClick(findChild(editor, "settings-icon-option-custom"));
            compare(input.visible, true);
            mouseClick(findChild(editor, "settings-icon-option-arch"));
            compare(Theme.settingsIcon, "󰣇");
            compare(input.visible, false);
            compare(Theme.settingsIconSource, "");
            grabImage(editor.parent).save("/tmp/quickshell-icon-presets.png");
        }
        function test_saved_custom_icon_shows_custom_input() {
            Theme.setSettingsIcon("★", "");
            tryCompare(findChild(editor, "settings-icon-glyph"), "visible", true);
            verify(findChild(editor, "settings-icon-option-custom").selected);
        }
        function test_custom_glyph_and_reset() {
            mouseClick(findChild(editor, "settings-icon-option-custom"));
            const input = findChild(editor, "settings-icon-glyph");
            input.forceActiveFocus();
            input.text = "★";
            keyClick(Qt.Key_Return);
            compare(Theme.settingsIcon, "★");
            mouseClick(findChild(editor, "settings-icon-reset"));
            compare(Theme.settingsIcon, Theme.defaultSettingsIcon);
            compare(input.text, Theme.defaultSettingsIcon);
            compare(input.visible, false);
        }
        function test_custom_image_and_reset() {
            mouseClick(findChild(editor, "settings-icon-option-custom"));
            const source = Qt.resolvedUrl("test wallpaper.svg").toString();
            editor.candidate = source;
            tryCompare(Theme, "settingsIconSource", source);
            mouseClick(findChild(editor, "settings-icon-reset"));
            compare(Theme.settingsIconSource, "");
        }
    }
}
