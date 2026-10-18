import QtQuick
import QtTest
import qs.config
import qs.config as ConfigScripts
import qs.components.ui as UI
import qs.components.shared

Rectangle {
    id: scene
    width: 640
    height: 480
    color: "#346789"
    Component {
        id: glassFactory
        UI.KitSurface {
            width: 200
            height: 100
            kitSlot: "barSurface"
            color: Design.background
            radius: 12
        }
    }
    Component {
        id: menuFactory
        UI.MenuSurface {
            width: 200
            height: 100
        }
    }
    Component {
        id: dropdownFactory
        Item {
            width: 200
            height: 100
            readonly property bool showStem: true
            readonly property int triggerWidth: 44
            readonly property string stemAlignment: "center"
            Loader {
                anchors.fill: parent
                readonly property var surface: parent
                sourceComponent: UiKit.visual("dropdownSurface")
            }
        }
    }
    Component {
        id: buttonFactory
        UI.Button {
            width: 140
            text: "Action"
        }
    }
    Component {
        id: customControlFactory
        UI.KitSurface {
            width: 140
            height: 32
            kitSlot: "controlSurface"
            color: Design.surfaceRaised
            control: QtObject {
                property bool down: false
                property bool enabled: true
                property bool hovered: false
                property bool activeFocus: true
            }
        }
    }
    Component {
        id: sliderFactory
        UI.Slider {
            property bool rtl: false
            LayoutMirroring.enabled: rtl
            width: 200
            stepSize: 0.1
            value: 0.4
        }
    }
    Component {
        id: checkboxFactory
        UI.CheckBox {
            text: "Option"
        }
    }
    Component {
        id: fieldFactory
        UI.TextField {
            width: 200
            invalid: true
        }
    }
    Component {
        id: indicatorFactory
        BarHoverIndicator {
            width: 80
            height: 40
            hovered: true
            styleSettings: ({
                    lines: "off",
                    background: "off",
                    duration: 0,
                    strength: 24
                })
        }
    }
    TestCase {
        name: "Windows7Kit"
        when: windowShown
        function init() {
            failOnWarning(/.*/);
            UiKit.previewKit = "windows7";
            Design.previewPalette = null;
            Design.previewMode = "";
            Theme.verticalBar = false;
            scene.color = "#346789";
            mouseMove(scene, 630, 470);
        }
        function cleanup() {
            UiKit.previewKit = "";
            Design.previewPalette = null;
            Design.previewMode = "";
            Theme.verticalBar = false;
        }
        function make(factory) {
            const item = createTemporaryObject(factory, scene);
            verify(item !== null);
            waitForRendering(item);
            return item;
        }
        function test_font_override_and_restore() {
            const expected = Qt.fontFamilies().includes("Segoe UI") ? "Segoe UI" : "sans-serif";
            const button = make(buttonFactory);
            compare(button.font.family, expected);
            compare(Design.iconFontFamily, "JetBrainsMono Nerd Font");
            UiKit.previewKit = "default";
            compare(button.font.family, Theme.fontFamily);
            UiKit.previewKit = "windows7";
            compare(button.font.family, expected);
        }
        function test_palette_inheritance_data() {
            const rows = [];
            for (const preset of ConfigScripts.Palettes.presets) {
                for (const mode of ["light", "dark"])
                    rows.push({
                        tag: preset.id + "-" + mode,
                        palette: ConfigScripts.Palettes.palette(preset.id, mode),
                        mode: mode
                    });
            }
            rows.push({
                tag: "generated-wallpaper",
                palette: Object.assign({}, ConfigScripts.Palettes.palette("neutral", "dark"), {
                    bg: "#152621",
                    surface: "#20362e",
                    overlay: "#2b473b",
                    iris: "#92d3b6"
                }),
                mode: "dark"
            });
            return rows;
        }
        function test_palette_inheritance(data) {
            const button = make(buttonFactory);
            Design.previewPalette = data.palette;
            Design.previewMode = data.mode;
            compare(Design.palette, data.palette);
            for (const variant of ["neutral", "primary", "destructive"]) {
                button.variant = variant;
                wait(Design.durationNormal);
                verify(Design.contrast(button.foreground, button.background.color) >= 4.5, variant);
                const painted = grabImage(button.background);
                for (const y of [10, 16, 22])
                    verify(Design.contrast(button.foreground, painted.pixel(10, y)) >= 4.5, variant + " painted contrast at " + y);
            }
        }
        function test_glass_alpha_clipping_and_repaint() {
            const glass = make(glassFactory);
            wait(50);
            let shot = grabImage(glass);
            compare(shot.pixel(0, 0), scene.color, "glass reflections stay inside rounded corners");
            scene.color = "#ffffff";
            wait(50);
            verify(shot.pixel(100, 50).toString() !== grabImage(glass).pixel(100, 50).toString(), "glass leaves the desktop visible");
            glass.topLeftRadius = 0;
            wait(50);
            verify(grabImage(glass).pixel(0, 0).toString() !== scene.color.toString(), "explicit square corner is retained");
            Theme.verticalBar = true;
            wait(50);
            verify(!shot.equals(grabImage(glass)), "vertical bar rotates the glass lighting");
            shot = grabImage(glass);
            Design.previewPalette = ConfigScripts.Palettes.palette("neutral", "light");
            wait(50);
            verify(!shot.equals(grabImage(glass)), "palette changes repaint glass");
            glass.color = "transparent";
            wait(50);
            compare(grabImage(glass).pixel(100, 50), scene.color, "caller transparency is preserved");
        }
        function test_native_glass_has_no_accent_wash() {
            scene.color = "#808080";
            Design.previewPalette = ConfigScripts.Palettes.palette("windows7-aero", "light");
            Design.previewMode = "light";
            const glass = make(glassFactory);
            wait(50);
            const before = grabImage(glass);
            const center = before.pixel(100, 50);
            fuzzyCompare(center.r, center.g, 1 / 255);
            fuzzyCompare(center.g, center.b, 1 / 255);
            Design.previewPalette = Object.assign({}, Design.previewPalette, {
                iris: "#ff0000"
            });
            wait(50);
            verify(before.equals(grabImage(glass)), "changing the accent does not recolor glass");
        }
        function test_native_menu_client_area_data() {
            return [
                {
                    tag: "light"
                },
                {
                    tag: "dark"
                }
            ];
        }
        function test_native_menu_client_area(data) {
            Design.previewPalette = ConfigScripts.Palettes.palette("windows7-aero", data.tag);
            Design.previewMode = data.tag;
            for (const factory of [menuFactory, dropdownFactory]) {
                scene.color = "#000000";
                const menu = make(factory);
                wait(50);
                const before = grabImage(menu);
                compare(before.pixel(100, 50), Design.background, "content stays opaque and neutral");
                scene.color = "#ffffff";
                wait(50);
                const after = grabImage(menu);
                compare(after.pixel(100, 50), Design.background);
                verify(before.pixel(3, 50).toString() !== after.pixel(3, 50).toString(), "frame remains glass");
                menu.destroy();
                wait(0);
            }
        }
        function test_native_primary_button_data() {
            return [
                {
                    tag: "light"
                },
                {
                    tag: "dark"
                }
            ];
        }
        function test_native_primary_button(data) {
            Design.previewPalette = ConfigScripts.Palettes.palette("windows7-aero", data.tag);
            Design.previewMode = data.tag;
            const button = make(buttonFactory);
            button.variant = "primary";
            wait(Design.durationNormal);
            const fill = grabImage(button.background).pixel(10, 16);
            fuzzyCompare(fill.r, fill.g, 1 / 255);
            fuzzyCompare(fill.g, fill.b, 1 / 255);
            compare(button.background.children[0].item.border.color, Design.accent);
            verify(Design.contrast(button.foreground, fill) >= 4.5);
            button.highlighted = true;
            wait(Design.durationNormal);
            verify(grabImage(button.background).pixel(10, 16).toString() !== fill.toString(), "selection remains visible");
            verify(Design.contrast(button.foreground, button.background.color) >= 4.5);
        }
        function test_custom_control_focus_uses_theme_accent() {
            const surface = make(customControlFactory);
            compare(surface.children[0].item.border.color, Design.accent);
        }
        function test_reference_button_silver_face() {
            Design.previewPalette = ConfigScripts.Palettes.palette("windows7-aero", "light");
            Design.previewMode = "light";
            const button = make(buttonFactory);
            wait(Design.durationNormal);
            const painted = grabImage(button.background);
            const upper = painted.pixel(10, 8);
            const lower = painted.pixel(10, 17);
            const foot = painted.pixel(10, 26);
            fuzzyCompare(upper.r, upper.g, 1 / 255);
            fuzzyCompare(upper.g, upper.b, 1 / 255);
            verify(upper.r < 0.94, "upper face stays silver instead of white");
            verify(Design.luminance(upper) - Design.luminance(lower) > 0.1, "reference gradient has a distinct middle step");
            verify(Design.luminance(foot) > Design.luminance(lower), "silver foot catches the light again");
        }
        function test_recessed_checkbox_keyboard_and_repaint_data() {
            return [
                {
                    tag: "light"
                },
                {
                    tag: "dark"
                }
            ];
        }
        function test_recessed_checkbox_keyboard_and_repaint(data) {
            Design.previewPalette = ConfigScripts.Palettes.palette("windows7-aero", data.tag);
            Design.previewMode = data.tag;
            const checkbox = make(checkboxFactory);
            checkbox.forceActiveFocus();
            wait(50);
            const empty = grabImage(checkbox.indicator);
            keyClick(Qt.Key_Space);
            verify(checkbox.checked);
            wait(50);
            const checked = grabImage(checkbox.indicator);
            verify(!empty.equals(checked), "checking draws the tick");
            compare(empty.pixel(3, 3), checked.pixel(3, 3), "checking retains the recessed neutral face");
            Design.previewPalette = ConfigScripts.Palettes.palette("rose-pine", data.tag);
            wait(50);
            verify(!checked.equals(grabImage(checkbox.indicator)), "face and tick repaint with the palette");
            keyClick(Qt.Key_Space);
            verify(!checkbox.checked);
            checkbox.enabled = false;
            mouseClick(checkbox);
            verify(!checkbox.checked);
        }
        function test_pointed_slider_thumb_and_hidden_progress() {
            Design.previewPalette = ConfigScripts.Palettes.palette("windows7-aero", "light");
            Design.previewMode = "light";
            const slider = make(sliderFactory);
            wait(50);
            let thumb = grabImage(slider.handle);
            compare(thumb.pixel(2, 4), scene.color, "thumb is narrower than the input target");
            verify(thumb.pixel(8, 14).toString() !== scene.color.toString(), "horizontal thumb points down");
            slider.orientation = Qt.Vertical;
            slider.width = 32;
            slider.height = 200;
            wait(50);
            thumb = grabImage(slider.handle);
            compare(thumb.pixel(4, 2), scene.color);
            verify(thumb.pixel(14, 8).toString() !== scene.color.toString(), "vertical thumb points right");
            slider.orientation = Qt.Horizontal;
            slider.width = 200;
            slider.height = 32;
            slider.showHandle = false;
            wait(50);
            const progress = grabImage(slider.background);
            compare(progress.pixel(10, 1), slider.accentColor, "hidden thumb retains value fill");
            verify(progress.pixel(170, 1).toString() !== slider.accentColor.toString(), "value fill stops at the current position");
            slider.rtl = true;
            wait(50);
            const mirrored = grabImage(slider.background);
            compare(mirrored.pixel(170, 1), slider.accentColor, "hidden-thumb value follows mirrored layout");
        }
        function test_button_ghost_press_focus_and_disabled() {
            const button = make(buttonFactory);
            button.variant = "ghost";
            wait(Design.durationNormal);
            compare(grabImage(button.background).pixel(10, 10), scene.color);
            mouseMove(button, 20, 15);
            wait(Design.durationNormal);
            const hover = grabImage(button.background);
            mousePress(button);
            wait(Design.durationNormal);
            verify(!hover.equals(grabImage(button.background)), "press visibly depresses the bevel");
            mouseRelease(button);
            button.forceActiveFocus();
            compare(button.background.border.width, Design.focusWidth);
            const spy = createTemporaryObject(spyFactory, scene, {
                target: button,
                signalName: "clicked"
            });
            keyClick(Qt.Key_Space);
            compare(spy.count, 1);
            button.busy = true;
            keyClick(Qt.Key_Space);
            mouseClick(button);
            compare(spy.count, 1);
            verify(!button.enabled);
        }
        function test_slider_and_invalid_field_keyboard() {
            const slider = make(sliderFactory);
            slider.forceActiveFocus();
            keyClick(Qt.Key_Right);
            compare(slider.value, 0.5);
            slider.orientation = Qt.Vertical;
            slider.width = 32;
            slider.height = 200;
            keyClick(Qt.Key_Up);
            compare(slider.value, 0.6);
            slider.enabled = false;
            mouseClick(slider, 16, 20);
            compare(slider.value, 0.6);
            slider.destroy();
            const field = make(fieldFactory);
            field.forceActiveFocus();
            keyClick(Qt.Key_A);
            compare(field.text, "a");
            wait(Design.durationNormal);
            compare(field.background.border.color, Design.danger);
            field.readOnly = true;
            keyClick(Qt.Key_B);
            compare(field.text, "a");
        }
        function test_widget_preferences_and_focus() {
            const indicator = make(indicatorFactory);
            compare(findChild(indicator, "widget-hover-background").opacity, 0);
            compare(indicator.lineOpacity, 0);
            indicator.focused = true;
            verify(findChild(indicator, "widget-focus-outline").visible);
            indicator.styleSettings = {
                lines: "instant",
                background: "instant",
                duration: 0,
                strength: 24
            };
            compare(indicator.lineOpacity, 1);
            compare(findChild(indicator, "widget-hover-background").opacity, 0.24);
        }
        Component {
            id: spyFactory
            SignalSpy {}
        }
    }
}
