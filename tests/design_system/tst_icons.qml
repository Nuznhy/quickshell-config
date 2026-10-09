import QtQuick
import QtTest
import "components/ui" as UI

Rectangle {
    id: scene
    width: 160
    height: 120
    color: "white"
    Component { id: buttonFactory; UI.IconButton {} }
    TestCase {
        name: "IconAlignment"
        when: windowShown
        function test_visible_glyph_is_centered_data() {
            return [
                {tag: "reload", glyph: "󰑐", width: 32, height: 32, padding: 4},
                {tag: "settings", glyph: "󰒓", width: 34, height: 32, padding: 4},
                {tag: "reload-compact", glyph: "󰑐", width: 26, height: 28, padding: 2},
                {tag: "settings-compact", glyph: "󰒓", width: 28, height: 28, padding: 4}
            ];
        }
        function test_visible_glyph_is_centered(data) {
            const button = createTemporaryObject(buttonFactory, scene, {
                text: data.glyph, width: data.width, height: data.height,
                leftPadding: data.padding, rightPadding: data.padding,
                topPadding: data.padding, bottomPadding: data.padding
            });
            verify(button !== null);
            // Inspect actual rendered ink, independently of font-metric arithmetic.
            button.background.visible = false;
            button.contentItem.color = "black";
            mouseMove(scene, 150, 110);
            wait(30);
            const image = grabImage(button);
            image.save("/tmp/qs-icon-centering-" + data.tag + ".png");
            let left = image.width, right = -1, top = image.height, bottom = -1;
            for (let y = 0; y < image.height; ++y) {
                for (let x = 0; x < image.width; ++x) {
                    if (image.red(x, y) < 128 && image.green(x, y) < 128 && image.blue(x, y) < 128) {
                        left = Math.min(left, x); right = Math.max(right, x);
                        top = Math.min(top, y); bottom = Math.max(bottom, y);
                    }
                }
            }
            verify(right >= left && bottom >= top, "the glyph is visible");
            verify(Math.abs((left + right + 1) / 2 - image.width / 2) <= 1,
                   "visible ink is horizontally centered");
            verify(Math.abs((top + bottom + 1) / 2 - image.height / 2) <= 1,
                   "visible ink is vertically centered");
        }
    }
}
