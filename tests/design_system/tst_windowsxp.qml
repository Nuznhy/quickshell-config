import QtQuick
import QtQuick.Controls as C
import QtTest
import qs.config
import qs.config as ConfigScripts
import qs.components.ui as UI

Rectangle {
    id: scene
    width: 800
    height: 600
    color: "#708090"
    Component {
        id: buttonFactory
        UI.Button {
            width: 140
            text: "Action"
        }
    }
    Component {
        id: menuItemFactory
        UI.MenuItem {
            width: 180
            text: "Menu action"
            checkable: true
        }
    }
    Component {
        id: fieldFactory
        UI.TextField {
            width: 200
            text: "Editable"
        }
    }
    Component {
        id: choiceFactory
        UI.CheckBox {
            text: "Option"
        }
    }
    Component {
        id: radioFactory
        UI.RadioButton {
            text: "Option"
        }
    }
    Component {
        id: switchFactory
        UI.Switch {}
    }
    Component {
        id: selectFactory
        UI.ComboBox {
            width: 200
            model: ["First", "Second", "Third"]
        }
    }
    Component {
        id: sliderFactory
        UI.Slider {
            property bool rtl: false
            LayoutMirroring.enabled: rtl
            width: 200
            value: 0.4
        }
    }
    Component {
        id: barFactory
        UI.KitSurface {
            width: 240
            height: 44
            kitSlot: "barSurface"
            color: Design.barColor("background")
            radius: 8
        }
    }
    Component {
        id: menuFactory
        UI.MenuSurface {
            width: 200
            height: 100
            radius: 8
        }
    }
    Component {
        id: scrollFactory
        Flickable {
            width: 240
            height: 180
            contentWidth: 600
            contentHeight: 600
            property alias vertical: vertical
            property alias horizontal: horizontal
            C.ScrollBar.vertical: UI.ScrollBar {
                id: vertical
                policy: C.ScrollBar.AlwaysOn
            }
            C.ScrollBar.horizontal: UI.ScrollBar {
                id: horizontal
                policy: C.ScrollBar.AlwaysOn
            }
        }
    }
    TestCase {
        name: "WindowsXPKit"
        when: windowShown
        function init() {
            failOnWarning(/.*/);
            UiKit.previewKit = "windowsxp";
            Design.previewPalette = ConfigScripts.Palettes.palette("windowsxp-luna", "light");
            Design.previewMode = "light";
            Theme.verticalBar = false;
            mouseMove(scene, 790, 590);
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
        function palettes() {
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
                tag: "wallpaper",
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
        function test_palette_and_painted_contrast_data() {
            return palettes();
        }
        function test_palette_and_painted_contrast(data) {
            Design.previewPalette = data.palette;
            Design.previewMode = data.mode;
            compare(Design.palette, data.palette);
            const button = make(buttonFactory);
            for (const variant of ["neutral", "primary", "destructive"]) {
                button.variant = variant;
                for (const down of [false, true]) {
                    button.down = down;
                    wait(Design.durationNormal + 30);
                    const shot = grabImage(button.background);
                    for (const y of [8, 16, 24])
                        verify(Design.contrast(button.foreground, shot.pixel(10, y)) >= 4.45, variant + " painted contrast " + y);
                }
            }
            button.visible = false;
            const bar = make(barFactory);
            for (const vertical of [false, true]) {
                Theme.verticalBar = vertical;
                bar.width = vertical ? 44 : 240;
                bar.height = vertical ? 240 : 44;
                wait(30);
                const shot = grabImage(bar);
                for (const role of ["text", "textSecondary", "textMuted", "accent", "danger"]) {
                    for (const position of [5, 12, 22, 38]) {
                        const background = vertical ? shot.pixel(position, 60) : shot.pixel(60, position);
                        verify(Design.contrast(Design.barColor(role), background) >= 4.4, role + " on bar at " + position);
                    }
                }
            }
        }
        function test_menu_flat_highlight_and_keyboard() {
            const item = make(menuItemFactory);
            mouseMove(item, 20, 16);
            wait(Design.durationNormal + 30);
            let shot = grabImage(item.background);
            compare(shot.pixel(10, 5), Design.accent);
            compare(shot.pixel(10, 25), Design.accent);
            verify(Design.contrast(item.foreground, Design.accent) >= 4.5);
            item.forceActiveFocus();
            keyClick(Qt.Key_Space);
            verify(item.checked);
            item.enabled = false;
            mouseClick(item);
            verify(item.checked);
        }
        function test_fonts_focus_invalid_and_disabled() {
            const field = make(fieldFactory);
            const expected = Qt.fontFamilies().includes("Tahoma") ? "Tahoma" : Qt.fontFamilies().includes("DejaVu Sans") ? "DejaVu Sans" : "sans-serif";
            compare(field.font.family, expected);
            compare(Design.iconFontFamily, "JetBrainsMono Nerd Font");
            field.forceActiveFocus();
            field.invalid = true;
            wait(Design.durationFast + 30);
            compare(field.background.border.color, Design.danger);
            const renderer = field.background.children[0].item;
            verify(renderer.children.some(child => child.visible && child.border && child.border.color === Design.accent));
            field.enabled = false;
            compare(field.opacity, Design.disabledOpacity);
            UiKit.previewKit = "default";
            compare(field.font.family, Theme.fontFamily);
        }
        function test_choice_and_switch_states() {
            for (const factory of [choiceFactory, radioFactory, switchFactory]) {
                const control = make(factory);
                verify(!control.checked);
                const before = grabImage(control.indicator);
                control.forceActiveFocus();
                keyClick(Qt.Key_Space);
                verify(control.checked);
                wait(Design.durationNormal + 30);
                verify(!before.equals(grabImage(control.indicator)), "checked indicator changes for " + control);
                control.enabled = false;
                mouseClick(control);
                verify(control.checked);
                control.destroy();
                wait(30);
            }
        }
        function test_select_join_and_restore() {
            const select = make(selectFactory);
            mouseClick(select);
            tryCompare(select.popup, "opened", true);
            compare(select.background.bottomRightRadius, 0);
            keyClick(Qt.Key_Escape);
            tryCompare(select.popup, "visible", false);
            select.forceActiveFocus();
            keyClick(Qt.Key_Down);
            compare(select.currentIndex, 1);
            tryCompare(select.background, "bottomRightRadius", Design.radiusControl);
        }
        function test_slider_orientations_hidden_handle_and_rtl() {
            const slider = make(sliderFactory);
            for (const orientation of [Qt.Horizontal, Qt.Vertical]) {
                slider.orientation = orientation;
                slider.width = slider.horizontal ? 200 : 32;
                slider.height = slider.horizontal ? 32 : 200;
                slider.forceActiveFocus();
                const before = slider.value;
                keyClick(slider.horizontal ? Qt.Key_Right : Qt.Key_Up);
                verify(slider.value > before);
                wait(30);
                const shot = grabImage(slider.handle);
                verify(shot.pixel(8, 8) !== scene.color);
                slider.showHandle = false;
                verify(!slider.handle.visible);
                const track = slider.background.children[0].item;
                verify(track.children[1].visible);
                slider.showHandle = true;
            }
            slider.orientation = Qt.Horizontal;
            slider.width = 200;
            slider.height = 32;
            slider.value = 0.2;
            const left = slider.handle.x;
            slider.rtl = true;
            verify(slider.handle.x > left);
        }
        function test_scrollbars_drag_both_axes_and_switch_kit() {
            const flick = make(scrollFactory);
            for (const vertical of [true, false]) {
                const bar = vertical ? flick.vertical : flick.horizontal;
                verify(bar.contentItem.children[0].item !== null);
                mousePress(bar, vertical ? bar.width / 2 : 10, vertical ? 10 : bar.height / 2);
                mouseMove(bar, vertical ? bar.width / 2 : 100, vertical ? 100 : bar.height / 2, 30);
                mouseRelease(bar, vertical ? bar.width / 2 : 100, vertical ? 100 : bar.height / 2);
                verify(vertical ? flick.contentY > 0 : flick.contentX > 0);
            }
            const x = flick.contentX, y = flick.contentY;
            UiKit.previewKit = "default";
            compare(flick.contentX, x);
            compare(flick.contentY, y);
            flick.vertical.policy = C.ScrollBar.AlwaysOff;
            verify(!flick.vertical.visible);
        }
        function test_surface_clipping_palette_repaint_and_overrides() {
            const menu = make(menuFactory);
            let shot = grabImage(menu);
            compare(shot.pixel(0, 0), scene.color);
            compare(shot.pixel(20, 40), Design.background);
            Design.previewPalette = ConfigScripts.Palettes.palette("windowsxp-luna", "dark");
            wait(30);
            shot = grabImage(menu);
            compare(shot.pixel(20, 40), Design.background);
            menu.color = "#123456";
            menu.border.color = "#abcdef";
            menu.border.width = 3;
            menu.topLeftRadius = 0;
            wait(30);
            const renderer = menu.children[0].item;
            compare(renderer.border.color, "#abcdef");
            compare(renderer.border.width, 3);
            compare(renderer.topLeftRadius, 0);
        }
    }
}
