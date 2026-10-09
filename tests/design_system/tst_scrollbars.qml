import QtQuick
import QtQuick.Controls as C
import QtTest
import "components/ui" as UI
import "config"

Item {
    id: scene
    width: 640
    height: 480

    Component {
        id: barFactory
        UI.ScrollBar { width: 8; height: 160; orientation: Qt.Vertical }
    }
    Component {
        id: viewFactory
        UI.ScrollView {
            width: 240
            height: 180
            padding: 12
            contentWidth: 160
            contentHeight: 100
            // Bind to the production attached controls, without replacing them.
            readonly property var verticalBar: C.ScrollBar.vertical
            readonly property var horizontalBar: C.ScrollBar.horizontal
        }
    }
    Component {
        id: flickableFactory
        Flickable {
            width: 240
            height: 180
            contentWidth: width
            contentHeight: height
            property alias verticalBar: vertical
            C.ScrollBar.vertical: UI.ScrollBar { id: vertical }
        }
    }

    TestCase {
        name: "DesignScrollBars"
        when: windowShown

        function make(factory) {
            const item = createTemporaryObject(factory, scene);
            verify(item !== null);
            wait(30);
            return item;
        }
        function init() { mouseMove(scene, scene.width - 1, scene.height - 1); }
        function test_visibility_policy_data() {
            return [
                {tag: "as-needed-fits", policy: C.ScrollBar.AsNeeded, size: 1, shown: false},
                {tag: "as-needed-overflows", policy: C.ScrollBar.AsNeeded, size: 0.5, shown: true},
                {tag: "always-off-overflows", policy: C.ScrollBar.AlwaysOff, size: 0.5, shown: false},
                {tag: "always-on-fits", policy: C.ScrollBar.AlwaysOn, size: 1, shown: true}
            ];
        }
        function test_visibility_policy(data) {
            const bar = make(barFactory);
            bar.policy = data.policy;
            bar.size = data.size;
            bar.active = true;
            tryCompare(bar, "visible", data.shown);
            if (data.shown) tryCompare(bar.contentItem, "opacity", 1);
        }
        function test_idle_overflow_hides_and_interaction_reveals() {
            const bar = make(barFactory);
            bar.size = 0.5;
            bar.active = false;
            tryCompare(bar.contentItem, "opacity", 0);
            mouseMove(bar, 4, 40);
            tryCompare(bar.contentItem, "opacity", 1);
            mouseMove(scene, 500, 300);
            bar.active = false;
            tryCompare(bar.contentItem, "opacity", 0);
            bar.policy = C.ScrollBar.AlwaysOn;
            tryCompare(bar.contentItem, "opacity", 1);
        }
        function test_attached_flickable_content_grows_and_shrinks() {
            const flick = make(flickableFactory);
            const bar = flick.verticalBar;
            tryCompare(bar, "visible", false);
            flick.contentHeight = 600;
            tryCompare(bar, "visible", true);
            verify(bar.size < 1);
            bar.active = true;
            tryCompare(bar.contentItem, "opacity", 1);
            mousePress(bar, bar.width / 2, 20);
            mouseMove(bar, bar.width / 2, 100, 30);
            mouseRelease(bar, bar.width / 2, 100);
            verify(flick.contentY > 0, "dragging still scrolls the attached content");
            flick.contentHeight = flick.height;
            tryCompare(bar, "visible", false);
            flick.contentHeight = 600;
            bar.policy = C.ScrollBar.AlwaysOff;
            tryCompare(bar, "visible", false);
        }
        function test_scroll_view_independent_axes_and_placement() {
            const view = make(viewFactory);
            const vertical = view.verticalBar;
            const horizontal = view.horizontalBar;
            tryCompare(vertical, "visible", false);
            tryCompare(horizontal, "visible", false);
            view.contentHeight = 600;
            tryCompare(vertical, "visible", true);
            compare(horizontal.visible, false);
            compare(vertical.parent, view);
            compare(vertical.x, view.width - vertical.width);
            compare(vertical.y, view.topPadding);
            compare(vertical.height, view.availableHeight);
            view.contentWidth = 600;
            tryCompare(horizontal, "visible", true);
            compare(horizontal.parent, view);
            compare(horizontal.x, view.leftPadding);
            compare(horizontal.y, view.height - horizontal.height);
            compare(horizontal.width, view.availableWidth);
            horizontal.policy = C.ScrollBar.AlwaysOff;
            tryCompare(horizontal, "visible", false);
            view.width = 320;
            view.height = 720;
            tryCompare(vertical, "visible", false);
            compare(vertical.x, view.width - vertical.width);
            compare(horizontal.width, view.availableWidth);
        }
    }
}
