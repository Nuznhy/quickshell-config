import QtQuick
import QtTest
import qs.components.ui as UI
import qs.components.shared
import qs.config
import qs.kits.default as DefaultKitScripts

Item {
    id: scene
    width: 640
    height: 480
    Component {
        id: buttonFactory
        UI.Button {
            text: "Action"
        }
    }
    Component {
        id: fieldFactory
        UI.TextField {
            width: 200
            text: "Keep me"
        }
    }
    Component {
        id: sliderFactory
        UI.Slider {
            width: 200
            value: 0.65
        }
    }
    Component {
        id: switchFactory
        UI.Switch {
            checked: true
        }
    }
    Component {
        id: popupFactory
        UI.Popup {
            width: 120
            height: 80
        }
    }
    Component {
        id: cardFactory
        UI.Card {
            width: 100
            height: 60
            color: "#123456"
            radius: 7
            topLeftRadius: 0
            border.width: 3
            border.color: "#abcdef"
        }
    }
    Component {
        id: hoverFactory
        BarHoverIndicator {
            width: 100
            height: 42
            hovered: true
            focused: true
        }
    }
    Component {
        id: dropdownFactory
        Item {
            id: host
            width: 200
            height: 160
            property bool showStem: true
            property int triggerWidth: 30
            property int stemWidth: 46
            property int stemHeight: 12
            property string stemAlignment: "center"
            property alias renderer: paint.item
            Loader {
                id: paint
                anchors.fill: parent
                readonly property var surface: host
                sourceComponent: UiKit.visual("dropdownSurface")
            }
        }
    }
    Component {
        id: rectangleFactory
        Rectangle {
            width: 100
            height: 60
            color: "#123456"
            radius: 7
            topLeftRadius: 0
            border.width: 3
            border.color: "#abcdef"
        }
    }
    TestCase {
        name: "UiKits"
        when: windowShown
        function init() {
            UiKit.previewKit = "default";
            Theme.verticalBar = false;
        }
        function cleanup() {
            UiKit.previewKit = "";
            Theme.verticalBar = false;
        }
        function make(factory) {
            const item = createTemporaryObject(factory, scene);
            verify(item !== null);
            return item;
        }
        function test_defaults_and_fallback() {
            const defaults = DefaultKitScripts.Tokens.defaults();
            for (const key of Object.keys(defaults))
                compare(Design[key], defaults[key], key);
            UiKit.previewKit = "unknown";
            compare(UiKit.activeId, "default");
            compare(Design.radiusControl, 8);
            UiKit.previewKit = "minimal";
            compare(Design.radiusControl, 2);
            compare(Design.controlHeight, defaults.controlHeight);
            const kit = UiKit.minimalKit;
            const renderer = kit.cardSurface;
            kit.cardSurface = null;
            compare(UiKit.visual("cardSurface"), UiKit.defaultKit.cardSurface);
            kit.cardSurface = renderer;
        }
        function test_palette_overrides() {
            const kit = UiKit.roundedKit;
            const originalPalette = kit.palette;
            const originalPalettes = kit.palettes;
            const originalPreview = Design.previewPalette;
            const originalMode = Design.previewMode;
            const originalThemeMode = Theme.mode;
            const baseBackground = Design.background;
            const baseText = Design.text;
            const button = make(buttonFactory);
            const background = button.background;
            try {
                kit.palette = {
                    bg: "#123456",
                    text: "#ffffff",
                    iris: "#008800"
                };
                kit.palettes = {
                    light: {
                        bg: "#abcdef"
                    },
                    dark: {
                        surface: "#80112233"
                    }
                };
                UiKit.previewKit = "rounded";
                Design.previewMode = "";
                Theme.mode = "dark";
                compare(Design.background, "#123456");
                compare(Design.surface, "#80112233");
                compare(Design.text, "#ffffff");
                compare(Design.accent, "#008800");
                compare(button.background, background);
                Theme.mode = "light";
                compare(Design.background, "#abcdef");
                Design.previewMode = "dark";
                compare(Design.background, "#123456");
                Design.previewMode = "light";
                compare(Design.background, "#abcdef");
                Design.previewPalette = Object.assign({}, Design.palette, {
                    bg: "#fedcba",
                    text: "#000000",
                    gold: "#998877"
                });
                compare(Design.background, "#abcdef");
                compare(Design.text, "#ffffff");
                compare(Design.warning, "#998877");
                kit.palette = {
                    text: "#eeeeee"
                };
                kit.palettes = {};
                compare(Design.background, "#fedcba");
                compare(Design.text, "#eeeeee");
                UiKit.previewKit = "default";
                compare(Design.text, "#000000");
                Design.previewPalette = originalPreview;
                compare(Design.background, baseBackground);
                compare(Design.text, baseText);
            } finally {
                kit.palette = originalPalette;
                kit.palettes = originalPalettes;
                Design.previewPalette = originalPreview;
                Design.previewMode = originalMode;
                Theme.mode = originalThemeMode;
            }
        }
        function test_default_surface_matches_original_rectangle() {
            const card = make(cardFactory);
            const reference = make(rectangleFactory);
            reference.x = 200;
            waitForRendering(card);
            verify(grabImage(card).equals(grabImage(reference)));
        }
        function test_live_switch_preserves_controls_and_overrides() {
            const button = make(buttonFactory);
            const secondButton = make(buttonFactory);
            const field = make(fieldFactory);
            const slider = make(sliderFactory);
            const toggle = make(switchFactory);
            const card = make(cardFactory);
            const popup = make(popupFactory);
            secondButton.x = 300;
            field.y = 80;
            slider.y = 140;
            toggle.y = 200;
            card.x = 300;
            card.y = 100;
            const background = button.background;
            field.forceActiveFocus();
            field.cursorPosition = 3;
            for (const id of ["minimal", "rounded", "windows7", "default"]) {
                UiKit.previewKit = id;
                compare(button.background, background);
                compare(button.background.radius, Design.radiusControl);
                compare(secondButton.background.radius, Design.radiusControl);
                compare(field.text, "Keep me");
                compare(field.cursorPosition, 3);
                verify(field.activeFocus);
                compare(slider.value, 0.65);
                compare(toggle.checked, true);
                compare(card.color, "#123456");
                compare(card.radius, 7);
                compare(card.topLeftRadius, 0);
                compare(card.border.width, 3);
                compare(card.border.color, "#abcdef");
                // Verify the paint delegate consumes the stable host API.
                const loader = card.children[0];
                verify(loader.item !== null);
                compare(loader.item.color, card.color);
                compare(loader.item.topLeftRadius, 0);
                compare(loader.item.border.width, 3);
            }
            button.busy = true;
            UiKit.previewKit = "minimal";
            compare(button.enabled, false);
            button.busy = false;
            compare(button.enabled, true);
            const spy = createTemporaryObject(signalSpyFactory, scene, {
                target: button,
                signalName: "clicked"
            });
            mouseClick(button);
            compare(spy.count, 1);
            button.forceActiveFocus();
            keyClick(Qt.Key_Space);
            compare(spy.count, 2);
            popup.open();
            tryCompare(popup, "opened", true);
            UiKit.previewKit = "rounded";
            tryCompare(popup, "visible", false);
        }
        Component {
            id: signalSpyFactory
            SignalSpy {}
        }
        function test_demo_renderers_and_vertical_indicator() {
            const button = make(buttonFactory);
            const hover = make(hoverFactory);
            for (const id of ["minimal", "rounded", "windows7", "default"]) {
                UiKit.previewKit = id;
                const loader = button.background.children[0];
                verify(loader.item !== null);
                compare(loader.item.surface, button.background);
                for (const vertical of [false, true]) {
                    Theme.verticalBar = vertical;
                    const line = findChild(hover, "widget-leading-line");
                    verify(line !== null);
                    compare(line.width, vertical ? 2 : hover.width);
                    verify(findChild(hover, "widget-focus-outline").visible);
                }
            }
        }
        function test_dropdown_geometry_and_repaint() {
            const dropdown = make(dropdownFactory);
            const spy = createTemporaryObject(signalSpyFactory, scene, {
                signalName: "painted"
            });
            for (const id of ["minimal", "rounded", "windows7", "default"]) {
                UiKit.previewKit = id;
                const renderer = dropdown.renderer;
                spy.target = renderer;
                verify(renderer.notchRadius <= dropdown.stemHeight);
                compare(renderer.cardRadius, Design.radiusCard);
                spy.clear();
                dropdown.stemAlignment = "left";
                tryVerify(() => spy.count > 0);
                spy.clear();
                dropdown.stemAlignment = "right";
                tryVerify(() => spy.count > 0);
                compare(renderer.stemAlignment, "right");
            }
        }
    }
}
