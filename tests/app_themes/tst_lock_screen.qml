import QtQuick
import QtTest
import "components"
import "config"
import "services"

Rectangle {
    width: 760; height: 680
    color: Theme.bg
    LockScreenSettings { id: panel; x: 20; y: 20; width: parent.width - 40 }
    TestCase {
        name: "LockScreenSettings"
        when: windowShown
        function init() {
            AppTheming.reset();
            panel.candidate = "";
            panel.errorMessage = "";
            Theme.lockBackgroundMode = "theme";
            Theme.lockBackgroundImage = "";
            Theme.lockBackgroundColor = "#191724";
        }
        function test_sync_switch() {
            mouseClick(findChild(panel, "lock-theme-sync"));
            compare(AppTheming.lastTarget, "hyprlock");
            compare(AppTheming.lastEnabled, true);
            mouseClick(findChild(panel, "lock-theme-sync"));
            compare(AppTheming.lastEnabled, false);
        }
        function test_color_and_theme() {
            mouseClick(findChild(panel, "lock-background-color"));
            compare(Theme.lockBackgroundMode, "color");
            const input = findChild(panel, "lock-color-input");
            input.forceActiveFocus();
            input.selectAll();
            keyClick(Qt.Key_NumberSign);
            for (let i = 0; i < 6; ++i) keyClick(Qt.Key_A);
            compare(Theme.lockBackgroundColor, "#aaaaaa");
            mouseClick(findChild(panel, "lock-background-theme"));
            compare(Theme.lockBackgroundMode, "theme");
        }
        function test_picture_validation() {
            const picture = Qt.resolvedUrl("picture.png").toString();
            panel.chooseImage(picture);
            tryCompare(Theme, "lockBackgroundImage", picture);
            compare(Theme.lockBackgroundMode, "image");
            panel.chooseImage(Qt.resolvedUrl("broken.png").toString());
            tryVerify(() => panel.errorMessage.length > 0);
            compare(Theme.lockBackgroundImage, picture);
            panel.chooseImage("https://example.com/picture.png");
            verify(panel.errorMessage.length > 0);
            compare(Theme.lockBackgroundImage, picture);
            mouseClick(findChild(panel, "lock-background-theme"));
            mouseClick(findChild(panel, "lock-background-image"));
            compare(Theme.lockBackgroundMode, "image");
            compare(panel.errorMessage, "");
            wait(100);
            grabImage(panel.parent).save("/tmp/quickshell-lock-settings.png");
        }
    }
}
