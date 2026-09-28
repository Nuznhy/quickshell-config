import QtQuick
import QtTest
import "components"
import "config"

Rectangle {
    width: 800
    height: 390
    color: Theme.bg
    WallpaperSelector { id: selector; x: 20; y: 20; width: 760 }
    TestCase {
        name: "Wallpapers"
        when: windowShown
        function init() {
            Theme.ready = true;
            Theme.wallpapers = {};
            Theme.lightWallpapers = {};
            Theme.darkWallpapers = {};
            Theme.separateWallpapers = false;
            Theme.mode = "dark";
            selector.wallpaperMode = Qt.binding(() => Theme.separateWallpapers ? Theme.mode : "shared");
            Theme.connectedScreens = [{name: "DP-1"}, {name: "HDMI-A-1"}];
            selector.width = 760;
            wait(20);
        }
        function card(name) { return findChild(selector, "wallpaper-card-" + name); }
        function drop(urls, actions) {
            return {urls: urls, hasUrls: urls.length > 0, supportedActions: actions,
                accepted: false, action: Qt.IgnoreAction,
                accept: function(action) { this.accepted = true; this.action = action; }};
        }
        function test_grid_wraps_without_overflow() {
            compare(selector.columns, 2);
            compare(card("DP-1").y, card("HDMI-A-1").y);
            verify(card("HDMI-A-1").x > card("DP-1").x + card("DP-1").width);
            selector.width = 330;
            tryCompare(selector, "columns", 1);
            tryVerify(() => card("HDMI-A-1").y > card("DP-1").y);
            verify(card("DP-1").width <= selector.width);
        }
        function test_drop_targets_one_monitor_and_never_moves_file() {
            const image = Qt.resolvedUrl("test wallpaper.svg").toString();
            const event = drop([image], Qt.CopyAction | Qt.MoveAction);
            card("HDMI-A-1").acceptDrop(event);
            compare(event.action, Qt.CopyAction);
            tryVerify(() => Theme.wallpaperFor("HDMI-A-1") === image);
            compare(Theme.wallpaperFor("DP-1"), "");
            mouseClick(findChild(selector, "wallpaper-clear-HDMI-A-1"));
            compare(Theme.wallpaperFor("HDMI-A-1"), "");
        }
        function test_rejects_remote_multiple_and_move_only_drops() {
            const image = Qt.resolvedUrl("test wallpaper.svg").toString();
            for (const event of [drop(["https://example.com/image.png"], Qt.CopyAction),
                                 drop([image, image], Qt.CopyAction), drop([image], Qt.MoveAction),
                                 drop([], Qt.CopyAction)]) {
                card("DP-1").acceptDrop(event);
                compare(event.accepted, false);
            }
            wait(30);
            compare(Theme.wallpaperFor("DP-1"), "");
        }
        function test_invalid_image_keeps_previous_and_can_recover() {
            const image = Qt.resolvedUrl("test wallpaper.svg").toString();
            selector.choose("DP-1", image);
            tryVerify(() => Theme.wallpaperFor("DP-1") === image);
            card("DP-1").acceptDrop(drop([Qt.resolvedUrl("not an image.jpg")], Qt.CopyAction));
            tryVerify(() => card("DP-1").errorMessage.length > 0);
            compare(Theme.wallpaperFor("DP-1"), image);
            selector.choose("DP-1", image);
            tryCompare(card("DP-1"), "candidate", "");
            compare(card("DP-1").errorMessage, "");
        }
        function test_disconnected_monitor_cannot_receive_picker_result() {
            Theme.connectedScreens = [{name: "DP-1"}];
            wait(20);
            selector.choose("HDMI-A-1", Qt.resolvedUrl("test wallpaper.svg"));
            wait(30);
            compare(Theme.wallpaperFor("HDMI-A-1"), "");
        }
        function test_preview() {
            selector.choose("DP-1", Qt.resolvedUrl("test wallpaper.svg"));
            tryVerify(() => Theme.wallpaperFor("DP-1") !== "");
            wait(100);
            const result = grabImage(selector.parent);
            result.save("/tmp/quickshell-wallpaper-selector.png");
        }
        function test_drop_and_clear_are_scoped_to_mode_and_monitor() {
            const image = Qt.resolvedUrl("test wallpaper.svg").toString();
            Theme.setSeparateWallpapers(true);
            selector.wallpaperMode = "light";
            card("HDMI-A-1").acceptDrop(drop([image], Qt.CopyAction));
            tryVerify(() => Theme.wallpaperFor("HDMI-A-1", "light") === image);
            compare(Theme.wallpaperFor("HDMI-A-1", "dark"), "");
            compare(Theme.wallpaperFor("DP-1", "light"), "");
            selector.wallpaperMode = "dark";
            compare(card("HDMI-A-1").source, "");
            selector.wallpaperMode = "light";
            mouseClick(findChild(selector, "wallpaper-clear-HDMI-A-1"));
            compare(Theme.wallpaperFor("HDMI-A-1", "light"), "");
        }
        function test_mode_switch_cancels_pending_image() {
            Theme.setSeparateWallpapers(true);
            selector.wallpaperMode = "light";
            selector.choose("DP-1", Qt.resolvedUrl("test wallpaper.svg"));
            selector.wallpaperMode = "dark";
            compare(card("DP-1").candidate, "");
            wait(50);
            compare(Theme.wallpaperFor("DP-1", "dark"), "");
        }
    }
}
