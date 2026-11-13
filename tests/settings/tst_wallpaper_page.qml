import QtQuick
import QtTest
import qs.modules.wallpaper
import qs.config
import qs.services.wallpaper

Rectangle {
    width: 800
    height: 760
    color: Theme.bg
    WallpaperPage {
        id: page
        x: 20
        y: 20
        width: 760
    }
    TestCase {
        name: "WallpaperGallery"
        when: windowShown
        function init() {
            Theme.wallpaperFolder = "";
            Theme.wallpapers = {};
            Theme.lightWallpapers = {};
            Theme.darkWallpapers = {};
            Theme.separateWallpapers = false;
            Theme.mode = "dark";
            page.selectedMode = "dark";
            Theme.connectedScreens = [
                {
                    name: "DP-1"
                },
                {
                    name: "HDMI-A-1"
                }
            ];
            page.selectedMonitor = "";
            page.gallerySource = "local";
            Wallhaven.searches = [];
            Wallhaven.searched = false;
            Wallhaven.items = [];
            Wallhaven.lastDownload = null;
            wait(30);
        }
        function test_wallhaven_is_lazy_and_applies_downloads_per_mode() {
            compare(findChild(page, "wallhaven-gallery"), null);
            compare(Wallhaven.searches.length, 0);
            page.gallerySource = "wallhaven";
            tryVerify(() => findChild(page, "wallhaven-gallery") !== null);
            compare(Wallhaven.searches.length, 1);
            compare(findChild(page, "wallpaper-gallery").visible, false);
            Wallhaven.items = [
                {
                    id: "abc123",
                    thumb: Qt.resolvedUrl("test wallpaper.svg").toString(),
                    full: "https://w.wallhaven.cc/full/ab/wallhaven-abc123.jpg",
                    resolution: "800x450",
                    purity: "sfw"
                }
            ];
            page.selectedMonitor = "HDMI-A-1";
            const tile = findChild(page, "wallhaven-image-abc123");
            verify(tile !== null);
            tryCompare(tile, "enabled", true);
            // The results grid sits below the fixed test window; activate it directly.
            tile.clicked();
            compare(Wallhaven.lastDownload.item.id, "abc123");
            compare(Wallhaven.lastDownload.context.monitor, "HDMI-A-1");
            const file = Qt.resolvedUrl("gallery/first image.svg").toString();
            // A download started for another mode must not be applied here.
            Wallhaven.downloaded("abc123", file, {
                monitor: "HDMI-A-1",
                mode: "light"
            });
            wait(100);
            compare(Theme.wallpaperFor("HDMI-A-1"), "");
            Wallhaven.downloaded("abc123", file, Wallhaven.lastDownload.context);
            tryVerify(() => Theme.wallpaperFor("HDMI-A-1") === file);
            compare(Theme.wallpaperFor("DP-1"), "");
            wait(100);
            grabImage(page.parent).save("/tmp/quickshell-wallpaper-wallhaven.png");
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
            Theme.connectedScreens = [
                {
                    name: "DP-1"
                }
            ];
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
        function test_toggle_and_gallery_mode_target() {
            const shared = Qt.resolvedUrl("test wallpaper.svg").toString();
            Theme.setWallpaper("DP-1", shared);
            compare(findChild(page, "wallpaper-mode-options").visible, false);
            mouseClick(findChild(page, "wallpaper-separate-modes"));
            verify(Theme.separateWallpapers);
            compare(findChild(page, "wallpaper-mode-options").visible, true);
            compare(Theme.wallpaperFor("DP-1"), shared);
            mouseClick(findChild(page, "wallpaper-mode-light"));
            compare(page.wallpaperMode, "light");
            compare(Theme.mode, "dark");
            Theme.setWallpaperFolder(Qt.resolvedUrl("gallery").toString());
            tryCompare(page, "imageCount", 2);
            const tile = findChild(page, "wallpaper-image-first image.svg");
            tryCompare(tile, "enabled", true);
            mouseClick(tile);
            const light = Qt.resolvedUrl("gallery/first image.svg").toString();
            tryVerify(() => Theme.wallpaperFor("DP-1", "light") === light);
            compare(Theme.wallpaperFor("DP-1"), shared);
            mouseClick(findChild(page, "wallpaper-mode-dark"));
            compare(findChild(page, "wallpaper-card-DP-1").source, shared);
            mouseClick(findChild(page, "wallpaper-clear-DP-1"));
            compare(Theme.wallpaperFor("DP-1"), "");
            compare(Theme.wallpaperFor("DP-1", "light"), light);
            mouseClick(findChild(page, "wallpaper-separate-modes"));
            compare(page.wallpaperMode, "shared");
            compare(Theme.wallpaperFor("DP-1"), shared);
            Theme.mode = "light";
            compare(Theme.wallpaperFor("DP-1"), shared);
            mouseClick(findChild(page, "wallpaper-separate-modes"));
            compare(page.wallpaperMode, "light");
            compare(Theme.wallpaperFor("DP-1"), light);
            wait(100);
            grabImage(page.parent).save("/tmp/quickshell-wallpaper-modes.png");
        }
    }
}
