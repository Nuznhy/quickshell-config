import QtQuick
import QtQuick.Controls as C
import QtTest
import "components/ui" as UI
import "components"
import "config"
import "config/Palettes.js" as Palettes

Item {
    id: scene
    width: 640
    height: 480
    Component { id: buttonFactory; UI.Button { text: "Action"; property bool available: true; enabled: available } }
    Component { id: fieldFactory; UI.TextField { width: 220; placeholderText: "Value" } }
    Component { id: comboFactory; UI.ComboBox { width: 220; textRole: "label"; valueRole: "id"; model: [{id: "a", label: "Alpha"}, {id: "b", label: "Beta"}] } }
    Component { id: switchFactory; ControlSwitch { property bool reported: false; value: reported } }
    Component { id: segmentsFactory; UI.SegmentedControl { width: 300; model: ["One", "Two", "Three"]; currentIndex: 0 } }
    Component { id: checkFactory; UI.CheckBox { text: "Check" } }
    Component { id: sliderFactory; UI.Slider { width: 220; from: 0; to: 100; stepSize: 1; value: 25 } }
    Component { id: audioFactory; AudioSlider { width: 220; level: 25 } }
    Component { id: seekFactory; MediaSeekSlider { width: 220; mediaPosition: 10; duration: 100; trackKey: "first" } }
    Component { id: popupFactory; UI.Popup { width: 160; height: 100; contentItem: UI.MenuItem { text: "Option" } } }
    Component { id: calendarFactory; CalendarPanel { width: 328; active: true } }
    Component { id: mediaFactory; MediaDetails { width: 300 } }
    Component { id: audioChoiceFactory; AudioDeviceDropdown { width: 280; title: "Output"; devices: [{name: "a", description: "Speakers"}, {name: "b", description: "Headphones"}]; selectedName: "a" } }
    TestCase {
        name: "DesignControls"
        when: windowShown
        SignalSpy { id: spy }
        function init() {
            spy.target = null;
            spy.clear();
            Design.previewPalette = null;
            mouseMove(scene, scene.width - 1, scene.height - 1);
        }
        function watch(item, signal) { spy.target = null; spy.signalName = signal; spy.target = item; spy.clear(); }
        function make(factory) {
            const item = createTemporaryObject(factory, scene);
            verify(item !== null);
            wait(20);
            return item;
        }
        function test_button_mouse_keyboard_busy_and_disabled() {
            const button = make(buttonFactory);
            watch(button, "clicked");
            mouseClick(button);
            compare(spy.count, 1);
            button.forceActiveFocus();
            keyClick(Qt.Key_Space);
            compare(spy.count, 2);
            const width = button.width;
            button.busy = true;
            compare(button.enabled, false);
            compare(button.width, width);
            mouseClick(button);
            keyClick(Qt.Key_Space);
            compare(spy.count, 2);
            button.available = false;
            button.busy = false;
            compare(button.enabled, false, "restore the caller's current enabled binding");
            button.available = true;
            compare(button.enabled, true);
            mouseClick(button);
            compare(spy.count, 3);
        }
        function test_button_visual_states_data() {
            return ["neutral", "primary", "ghost", "destructive"].map(variant => ({tag: variant, variant: variant}));
        }
        function test_button_visual_states(data) {
            const button = make(buttonFactory);
            button.variant = data.variant;
            wait(Design.durationNormal);
            const normal = button.background.color.toString();
            mouseMove(button, button.width / 2, button.height / 2);
            wait(Design.durationNormal);
            const hover = button.background.color.toString();
            verify(normal !== hover, "hover changes the surface");
            mousePress(button);
            wait(Design.durationNormal);
            verify(button.background.color.toString() !== hover, "press differs from hover");
            mouseRelease(button);
            button.forceActiveFocus();
            compare(button.background.border.width, Design.focusWidth);
        }
        function test_text_field_read_only_password_and_invalid_focus() {
            const field = make(fieldFactory);
            mouseClick(field);
            keyClick(Qt.Key_A);
            compare(field.text, "a");
            field.readOnly = true;
            keyClick(Qt.Key_B);
            compare(field.text, "a");
            field.readOnly = false;
            field.echoMode = TextInput.Password;
            verify(field.displayText !== field.text);
            field.invalid = true;
            field.forceActiveFocus();
            verify(field.activeFocus);
            wait(Design.durationNormal);
            compare(field.background.border.color, Design.danger);
        }
        function test_combo_keyboard_selection_and_escape() {
            const combo = make(comboFactory);
            watch(combo, "activated");
            combo.forceActiveFocus();
            keyClick(Qt.Key_Down);
            compare(combo.currentValue, "b");
            compare(spy.count, 1);
            mouseClick(combo);
            tryCompare(combo.popup, "visible", true);
            keyClick(Qt.Key_Escape);
            tryCompare(combo.popup, "visible", false);
            compare(combo.currentValue, "b");
            combo.enabled = false;
            mouseClick(combo);
            compare(combo.popup.visible, false);
        }
        function test_controlled_switch_reject_and_accept() {
            const toggle = make(switchFactory);
            watch(toggle, "changeRequested");
            mouseClick(toggle);
            compare(spy.count, 1);
            compare(spy.signalArguments[0][0], true);
            compare(toggle.checked, false, "a request must not replace service state");
            toggle.reported = true;
            compare(toggle.checked, true);
            toggle.forceActiveFocus();
            keyClick(Qt.Key_Space);
            compare(spy.signalArguments[1][0], false);
            compare(toggle.checked, true);
        }
        function test_checkbox_and_controlled_segments() {
            const checkbox = make(checkFactory);
            mouseClick(checkbox);
            compare(checkbox.checked, true);
            checkbox.forceActiveFocus();
            keyClick(Qt.Key_Space);
            compare(checkbox.checked, false);
            checkbox.destroy();
            const segments = make(segmentsFactory);
            watch(segments, "selected");
            mouseClick(segments, segments.width / 2, segments.height / 2);
            compare(spy.signalArguments[0][0], 1);
            compare(segments.currentIndex, 0, "selection is owned by the caller");
        }
        function test_slider_keyboard_and_disabled() {
            const slider = make(sliderFactory);
            watch(slider, "moved");
            slider.forceActiveFocus();
            keyClick(Qt.Key_Right);
            compare(slider.value, 26);
            compare(spy.count, 1);
            slider.enabled = false;
            mouseClick(slider, 180, 16);
            compare(slider.value, 26);
        }
        function test_audio_final_write_and_stale_level() {
            const slider = make(audioFactory);
            watch(slider, "volumeRequested");
            mousePress(slider, 40, 16);
            mouseMove(slider, 160, 16, 10);
            mouseRelease(slider, 180, 16);
            wait(80);
            verify(spy.count > 0);
            compare(spy.signalArguments[spy.count - 1][0], Math.round(slider.value));
            verify(slider.value > slider.level, "release retains the last edit until new service state");
        }
        function test_seek_commits_once_and_cancels_track_change() {
            const slider = make(seekFactory);
            watch(slider, "seekRequested");
            mousePress(slider, 40, 16);
            mouseMove(slider, 160, 16, 20);
            compare(spy.count, 0);
            mouseRelease(slider, 160, 16);
            compare(spy.count, 1);
            mousePress(slider, 100, 16);
            mouseMove(slider, 180, 16, 20);
            slider.trackKey = "second";
            mouseRelease(slider, 180, 16);
            compare(spy.count, 1);
        }
        function test_popup_outside_dismissal() {
            const anchor = make(buttonFactory);
            const popup = createTemporaryObject(popupFactory, anchor);
            popup.open();
            tryCompare(popup, "visible", true);
            mouseClick(scene, 400, 300);
            tryCompare(popup, "visible", false);
        }
        function test_calendar_keyboard_and_media_empty_state() {
            const calendar = make(calendarFactory);
            const month = calendar.displayedMonth.getMonth();
            calendar.forceActiveFocus();
            keyClick(Qt.Key_Right);
            compare(calendar.displayedMonth.getMonth(), (month + 1) % 12);
            keyClick(Qt.Key_Home);
            compare(calendar.displayedMonth.getMonth(), calendar.today.getMonth());
            calendar.destroy();
            const media = make(mediaFactory);
            verify(media.implicitHeight > 0);
            compare(media.duration, 0);
            compare(media.timeLabel(125), "2:05");
        }
        function test_audio_selector_dismisses_when_unavailable() {
            const selector = make(audioChoiceFactory);
            selector.expanded = true;
            wait(30);
            selector.busy = true;
            compare(selector.expanded, false);
            selector.busy = false;
            selector.expanded = true;
            selector.devices = [];
            compare(selector.expanded, false);
            compare(selector.selectedDescription, "No devices available");
        }
        function test_palette_changes_update_existing_controls_data() {
            return Palettes.presets.reduce((rows, p) => rows.concat(["dark", "light"].map(mode => ({tag: p.id + "-" + mode, preset: p.id, mode: mode}))), []);
        }
        function test_palette_changes_update_existing_controls(data) {
            const button = make(buttonFactory);
            button.variant = "primary";
            Design.previewPalette = Palettes.palette(data.preset, data.mode);
            wait(Design.durationNormal);
            compare(button.background.color, Design.accent);
            compare(button.contentItem.color, Design.textOnAccent);
            verify(Design.contrast(button.foreground, button.background.color) >= 4.5);
            button.variant = "neutral";
            wait(Design.durationNormal);
            verify(Design.contrast(button.foreground, button.background.color) >= 4.5);
        }
    }
}
