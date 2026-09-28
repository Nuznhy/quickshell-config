import QtQuick
import QtTest
import "components"
import "config"
import "services"

TestCase {
    id: testCase
    name: "QuickSettings"
    width: 330
    height: 340
    visible: true
    when: windowShown
    QuickSettings { id: panel; x: 12; y: 12; width: 306; height: implicitHeight }
    SignalSpy { id: settingsSpy; target: panel; signalName: "settingsRequested" }
    function control(name) { return findChild(panel, name); }
    function init() {
        panel.active = false;
        Theme.mode = "dark";
        Notifications.doNotDisturb = false;
        QuickControls.available = true;
        QuickControls.busy = false;
        QuickControls.nightEnabled = false;
        QuickControls.strength = 50;
        QuickControls.errorMessage = "";
        settingsSpy.clear();
    }
    function test_toggles_follow_external_changes() {
        let dnd = control("dnd-toggle");
        mouseClick(dnd);
        verify(Notifications.doNotDisturb);
        verify(dnd.checked);
        Notifications.doNotDisturb = false;
        verify(!dnd.checked);
        let theme = control("theme-toggle");
        mouseClick(theme);
        compare(Theme.mode, "light");
        compare(theme.text, "Light");
        mouseClick(theme);
        compare(Theme.mode, "dark");
    }
    function test_night_shift() {
        let night = control("night-shift-toggle");
        mouseClick(night);
        verify(night.checked);
        QuickControls.nightEnabled = false;
        verify(!night.checked);
        QuickControls.available = false;
        verify(!night.enabled);
        mouseClick(night);
        verify(!QuickControls.nightEnabled);
        QuickControls.available = true;
        QuickControls.busy = true;
        verify(night.enabled);
        compare(night.opacity, 1);
        mouseClick(night);
        verify(QuickControls.nightEnabled);
    }
    function test_open_settings() {
        mouseClick(control("full-settings"));
        compare(settingsSpy.count, 1);
    }
    function test_strength_slider() {
        let row = control("night-shift-strength");
        verify(!row.visible);
        QuickControls.nightEnabled = true;
        wait(50);
        verify(row.visible);
        // Exercise the real Slider via its keyboard control.
        function findSlider(item) {
            if (item.from !== undefined && item.to !== undefined) return item;
            for (const child of item.children || []) {
                let result = findSlider(child);
                if (result) return result;
            }
            return null;
        }
        let slider = findSlider(row);
        verify(slider !== null);
        verify(!slider.wheelEnabled);
        compare(slider.value, 4000);
        compare(row.suffix, " K");
        slider.forceActiveFocus();
        keyClick(Qt.Key_Right);
        compare(slider.value, 4050);
        compare(QuickControls.strength, 49);
        QuickControls.strength = 85;
        compare(slider.value, 2250);
        QuickControls.nightEnabled = false;
        verify(!row.visible);
        compare(QuickControls.strength, 85);
    }
    function test_poll_lifecycle() {
        compare(QuickControls.openPanels, 0);
        panel.active = true;
        compare(QuickControls.openPanels, 1);
        panel.active = false;
        compare(QuickControls.openPanels, 0);
    }
    function test_layout() {
        wait(100);
        let night = control("night-shift-toggle");
        let theme = control("theme-toggle");
        let dnd = control("dnd-toggle");
        verify(Math.abs(night.width - theme.width) < 2);
        verify(theme.x >= night.x + night.width + 7);
        verify(dnd.x >= theme.x + theme.width + 7);
        verify(panel.implicitHeight < 220);
        grabImage(panel).save('/tmp/quickshell-quick-settings.png');
        let originalHeight = panel.implicitHeight;
        QuickControls.errorMessage = 'Night Shift needs hyprsunset. Install: sudo pacman -S hyprsunset';
        wait(50);
        verify(panel.implicitHeight > originalHeight);
    }
}
