import QtQuick
import QtTest
import qs.tools.gallery
import qs.config as ConfigScripts
import qs.kits as KitScripts

Item {
    width: 960
    height: 820
    Gallery {
        id: gallery
        anchors.fill: parent
    }
    TestCase {
        name: "DesignGallery"
        when: windowShown
        function cleanupTestCase() {
            gallery.kit = "default";
        }
        function test_render_palettes_data() {
            const rows = [];
            for (const kit of KitScripts.Registry.kits) {
                for (const p of ConfigScripts.Palettes.presets) {
                    for (const mode of ["dark", "light"])
                        rows.push({
                            tag: kit.id + "-" + p.id + "-" + mode,
                            kit: kit.id,
                            preset: p.id,
                            mode: mode
                        });
                }
            }
            return rows;
        }
        function test_render_palettes(data) {
            gallery.kit = data.kit;
            gallery.preset = data.preset;
            gallery.mode = data.mode;
            gallery.contentItem.contentY = 0;
            wait(180);
            verify(gallery.content.implicitHeight > 0);
            let done = false;
            verify(gallery.grabToImage(result => {
                done = result.saveToFile("/tmp/qs-design-gallery-" + data.tag + ".png");
            }));
            tryVerify(() => done);
            gallery.contentItem.contentY = Math.max(0, gallery.contentItem.contentHeight - gallery.availableHeight);
            wait(50);
            done = false;
            verify(gallery.grabToImage(result => {
                done = result.saveToFile("/tmp/qs-design-gallery-" + data.tag + "-controls.png");
            }));
            tryVerify(() => done);
        }
        function test_narrow_layout() {
            gallery.kit = "default";
            gallery.parent.width = 640;
            gallery.parent.height = 480;
            gallery.contentItem.contentY = 0;
            wait(50);
            verify(gallery.content.width <= gallery.width);
            verify(gallery.content.implicitHeight > gallery.height);
            let done = false;
            verify(gallery.grabToImage(result => {
                done = result.saveToFile("/tmp/qs-design-gallery-narrow.png");
            }));
            tryVerify(() => done);
            gallery.parent.width = 960;
            gallery.parent.height = 820;
        }
    }
}
