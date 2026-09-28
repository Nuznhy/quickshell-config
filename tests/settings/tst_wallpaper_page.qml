import QtQuick
import QtTest
import "components"
import "config"

Rectangle {
    width: 800; height: 760
    color: Theme.bg
    WallpaperPage { id: page; x: 20; y: 20; width: 760 }
    TestCase {
        name: "WallpaperGallery"
        when: windowShown
        function init() {
            Theme.wallpaperFolder = "";
            Theme.wallpapers = {};
            Theme.connectedScreens = [{name: "DP-1"}, {name: "HDMI-A-1"}];
            page.selectedMonitor = "";
            wait(30);
        }
        function test_folder_filters_and_switches() {
            Theme.setWallpaperFolder(Qt.resolvedUrl("gallery").toString());
            tryCompare(page, "imageCount", 2);
            Theme.setWallpaperFolder(Qt.resolvedUrl("empty-gallery").toString());
            tryCompare(page, "imageCount", 0);
            Theme.setWallpaperFolder(Qt.resolvedUrl("gallery").toString());
            tryCompare(page, "imageCount", 2);
            Theme.setWallpaperFolder("");
            tryCompare(page, "imageCount", 0);
        }
        function test_thumbnail_applies_to_selected_monitor() {
            Theme.setWallpaperFolder(Qt.resolvedUrl("gallery").toString());
            tryCompare(page, "imageCount", 2);
            page.selectedMonitor = "HDMI-A-1";
            const tile = findChild(page, "wallpaper-image-first image.svg");
            verify(tile !== null);
            tryCompare(tile, "enabled", true);
            mouseClick(tile);
            const url = Qt.resolvedUrl("gallery/first image.svg").toString();
            tryVerify(() => Theme.wallpaperFor("HDMI-A-1") === url);
            compare(Theme.wallpaperFor("DP-1"), "");
            Theme.connectedScreens = [{name: "DP-1"}];
            tryCompare(page, "activeMonitor", "DP-1");
            Theme.connectedScreens = [];
            tryCompare(tile, "enabled", false);
        }
        function test_preview() {
            Theme.setWallpaperFolder(Qt.resolvedUrl("gallery").toString());
            tryCompare(page, "imageCount", 2);
            wait(100);
            grabImage(page.parent).save("/tmp/quickshell-wallpaper-gallery.png");
        }
    }
}
