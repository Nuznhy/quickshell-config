import QtQuick
import QtQuick.Window
import QtTest
import qs.components.ui as UI
import qs.modules.bar.widgets
import qs.config

Rectangle {
    id: scene
    width: 420
    height: 180
    color: "#ece9d8"
    Component {
        id: iconFactory
        UI.Icon {}
    }
    Component {
        id: buttonFactory
        UI.IconButton {}
    }
    Component {
        id: labelFactory
        IconLabel {}
    }
    TestCase {
        name: "KitIcons"
        when: windowShown
        function cleanup() {
            UiKit.previewKit = "";
            Theme.verticalBar = false;
        }
        function make(properties) {
            const icon = createTemporaryObject(iconFactory, scene, properties);
            verify(icon !== null);
            return icon;
        }
        function test_live_switch_and_glyph_fallback() {
            const icon = make({
                text: "󰒓",
                size: 24,
                color: "#123456"
            });
            const glyph = findChild(icon, "kit-icon-glyph");
            compare(icon.source.toString(), "");
            verify(glyph.visible);
            UiKit.previewKit = "windowsxp";
            tryCompare(icon, "imageReady", true);
            compare(icon.source.toString(), UiKit.iconSource("settings", icon.size * scene.Screen.devicePixelRatio));
            verify(!glyph.visible);
            compare(icon.color, "#123456");
            for (const kit of ["default", "minimal", "rounded", "windows7"]) {
                UiKit.previewKit = kit;
                compare(icon.imageReady, false);
                compare(icon.source.toString(), "");
                verify(glyph.visible);
                compare(glyph.text, "󰒓");
            }
            UiKit.previewKit = "windowsxp";
            icon.text = "★";
            compare(icon.source.toString(), "");
            verify(glyph.visible);
            compare(glyph.text, "★");
            icon.text = "󰒓";
            tryCompare(icon, "imageReady", true);
            icon.useKitIcons = false;
            compare(icon.source.toString(), "");
            verify(glyph.visible);
        }
        function test_all_assets_decode_and_sizes_resolve() {
            UiKit.previewKit = "windowsxp";
            const icon = make({
                size: 32
            });
            for (const name of Object.keys(UiKit.active.icons)) {
                for (const size of Object.keys(UiKit.active.icons[name])) {
                    icon.source = UiKit.iconSource(name, Number(size));
                    tryCompare(icon, "imageReady", true, 1000, name + " at " + size);
                }
            }
            verify(UiKit.iconSource("settings", 16).includes("/16/"));
            verify(UiKit.iconSource("settings", 17).includes("/32/"));
            verify(UiKit.iconSource("settings", 33).includes("/48/"));
            verify(UiKit.iconSource("settings", 96).includes("/48/"));
            compare(UiKit.iconSource("missing", 32), "");
        }
        function test_missing_asset_and_explicit_source() {
            UiKit.previewKit = "windowsxp";
            const icon = make({
                name: "settings"
            });
            tryCompare(icon, "imageReady", true);
            const explicit = icon.source;
            ignoreWarning(/QML Image: Cannot open:.*missing-icon.png/);
            icon.source = Qt.resolvedUrl("missing-icon.png");
            tryCompare(findChild(icon, "kit-icon-image"), "status", Image.Error);
            verify(findChild(icon, "kit-icon-glyph").visible);
            compare(findChild(icon, "kit-icon-glyph").text, "󰒓");
            icon.source = explicit;
            UiKit.previewKit = "default";
            tryCompare(icon, "imageReady", true);
            compare(icon.source, explicit);
        }
        function test_artwork_keeps_color_and_fits_controls() {
            UiKit.previewKit = "windowsxp";
            const icon = make({
                name: "power",
                size: 32,
                width: 100,
                height: 28,
                color: "#000000"
            });
            tryCompare(icon, "imageReady", true);
            const artwork = findChild(icon, "kit-icon-image");
            compare(artwork.width, 28);
            compare(artwork.height, 28);
            compare(artwork.x, 36);
            const rendered = grabImage(icon);
            let colored = false;
            for (let y = 0; y < rendered.height; ++y) {
                for (let x = 0; x < rendered.width; ++x) {
                    if (rendered.red(x, y) > rendered.green(x, y) + 50)
                        colored = true;
                }
            }
            verify(colored, "XP artwork retains its original color");
            const button = createTemporaryObject(buttonFactory, scene, {
                iconName: "settings",
                x: 120
            });
            verify(button !== null);
            tryCompare(button.contentItem, "imageReady", true);
            UiKit.previewKit = "default";
            compare(findChild(button.contentItem, "kit-icon-glyph").text, "󰒓");
        }
        function test_bar_layout_both_orientations() {
            UiKit.previewKit = "windowsxp";
            const label = createTemporaryObject(labelFactory, scene, {
                icon: "󰕾",
                text: "75"
            });
            verify(label !== null);
            const icon = label.children[0];
            const value = label.children[1];
            tryCompare(icon, "imageReady", true);
            tryVerify(() => value.x >= icon.x + icon.width);
            label.iconAfterText = true;
            tryVerify(() => icon.x >= value.x + value.width);
            Theme.verticalBar = true;
            tryVerify(() => value.y >= icon.y + icon.height);
            verify(label.implicitWidth >= Math.max(icon.width, value.width));
            verify(label.implicitHeight >= icon.height + value.height);
        }
        function test_render_native_sizes() {
            UiKit.previewKit = "windowsxp";
            const names = ["settings", "keyboard", "volume-high", "volume-muted", "folder", "power", "network-wired", "notifications"];
            for (let row = 0; row < 3; ++row) {
                for (let column = 0; column < names.length; ++column) {
                    const icon = make({
                        name: names[column],
                        size: [16, 32, 48][row],
                        x: column * 52,
                        y: row * 56
                    });
                    tryCompare(icon, "imageReady", true);
                }
            }
            wait(30);
            grabImage(scene).save("/tmp/qs-kit-icons-windowsxp.png");
        }
    }
}
