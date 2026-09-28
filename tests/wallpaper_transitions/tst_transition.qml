import QtQuick
import QtTest
import "components"
import "modules/bar/widgets"
import "config"

Rectangle {
    width: 640; height: 400
    color: "black"
    WallpaperTransition {
        id: wallpaper
        width: 600; height: 340
        pixelSize: Qt.size(600, 340)
        duration: 180
    }
    ThemeModeWidget { id: button; x: 600; y: 0 }
    TestCase {
        name: "WallpaperTransitions"
        when: windowShown
        readonly property string red: Qt.resolvedUrl("red.svg").toString()
        readonly property string blue: Qt.resolvedUrl("blue.svg").toString()
        function init() {
            wallpaper.ready = true;
            wallpaper.source = "";
            wallpaper.mode = "dark";
            wallpaper.duration = 180;
            wait(240);
            Theme.mode = "dark"; Theme.ready = true; Theme.verticalBar = false;
            wallpaper.source = red;
            tryCompare(wallpaper, "displayedSource", red);
            verify(!wallpaper.transitioning);
        }
        function test_all_random_effects_finish() {
            for (let style = 0; style < 6; style++) {
                wallpaper.style = style;
                const target = style % 2 === 0 ? blue : red;
                wallpaper.source = target;
                wallpaper.mode = style % 2 === 0 ? "light" : "dark";
                tryCompare(wallpaper, "transitioning", true);
                compare(wallpaper.displayedSource, style % 2 === 0 ? red : blue);
                compare(wallpaper.activeStyle, style);
                tryCompare(wallpaper, "displayedSource", target);
                verify(!wallpaper.transitioning);
                compare(wallpaper.pendingIndex, -1);
                compare(wallpaper.bufferFor(1 - wallpaper.frontIndex).imageSource.toString(), "");
            }
        }
        function test_visual_wipe_and_zoom() {
            wallpaper.duration = 1000;
            wallpaper.style = 2;
            wallpaper.source = blue; wallpaper.mode = "light";
            tryCompare(wallpaper,"transitioning",true);
            wait(500);
            const middle = grabImage(wallpaper);
            // Left half has been revealed; the far right is still the old image.
            verify(middle.blue(20,100) > middle.red(20,100));
            verify(middle.red(580,100) > middle.blue(580,100));
            middle.save("/tmp/quickshell-wallpaper-wipe.png");
            tryCompare(wallpaper,"displayedSource",blue);
            wallpaper.style=1;
            wallpaper.source=red; wallpaper.mode="dark";
            tryCompare(wallpaper,"transitioning",true);
            wait(500);
            grabImage(wallpaper).save("/tmp/quickshell-wallpaper-zoom.png");
            tryCompare(wallpaper,"displayedSource",red);
        }
        function test_shared_image_does_not_animate() {
            wallpaper.mode = "light"; wait(40);
            verify(!wallpaper.transitioning); compare(wallpaper.displayedSource,red);
        }
        function test_file_selection_is_immediate_after_decode() {
            wallpaper.source=blue;
            tryCompare(wallpaper,"displayedSource",blue);
            verify(!wallpaper.transitioning);
        }
        function test_rapid_toggles_latest_wins() {
            wallpaper.duration=600;
            wallpaper.source=blue; wallpaper.mode="light";
            tryCompare(wallpaper,"transitioning",true);
            wallpaper.source=red; wallpaper.mode="dark";
            wait(30);
            wallpaper.source=blue; wallpaper.mode="light";
            wait(20);
            tryVerify(() => wallpaper.displayedSource === blue && !wallpaper.transitioning && wallpaper.pendingIndex === -1);
            wallpaper.source=red; wallpaper.mode="dark";
            wallpaper.source=blue; wallpaper.mode="light";
            wait(80);
            compare(wallpaper.displayedSource,blue);
            verify(!wallpaper.transitioning);
        }
        function test_missing_image_keeps_previous() {
            wallpaper.source=Qt.resolvedUrl("missing.png"); wallpaper.mode="light";
            tryVerify(() => wallpaper.errorMessage !== "");
            compare(wallpaper.displayedSource,red); verify(!wallpaper.transitioning);
            wallpaper.source=blue;
            tryCompare(wallpaper,"displayedSource",blue);
            compare(wallpaper.errorMessage,"");
        }
        function test_empty_mode_fades_out_and_returns() {
            wallpaper.source=""; wallpaper.mode="light";
            tryCompare(wallpaper,"transitioning",true);
            verify(wallpaper.hasContent);
            tryCompare(wallpaper,"hasContent",false);
            compare(wallpaper.displayedSource,"");
            wallpaper.source=red; wallpaper.mode="dark";
            tryCompare(wallpaper,"displayedSource",red);
            verify(wallpaper.hasContent);
        }
        function test_button_mouse_keyboard_and_orientation() {
            mouseClick(button); compare(Theme.mode,"light");
            mouseClick(button); compare(Theme.mode,"dark");
            button.forceActiveFocus(); keyClick(Qt.Key_Space); compare(Theme.mode,"light");
            Theme.verticalBar=true;
            verify(button.width <= 64);
            keyClick(Qt.Key_Return); compare(Theme.mode,"dark");
            Theme.ready=false; mouseClick(button); compare(Theme.mode,"dark");
        }
    }
}
