import QtQuick
import QtTest
import "components/ui" as UI
import "config"

Rectangle {
    id: scene
    width: 400; height: 400
    color: "#ff00ff"
    UI.ComboBox {
        id: selector
        x: 40; y: 40; width: 280
        model: ["Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota"]
    }
    TestCase {
        name: "SelectShape"
        when: windowShown
        function test_corners_reverse_and_restore() {
            compare(selector.background.bottomLeftRadius, Design.radiusControl);
            selector.popup.open();
            tryCompare(selector.popup, "reveal", 1);
            compare(selector.background.bottomLeftRadius, 0);
            compare(selector.background.topLeftRadius, Design.radiusControl);
            compare(selector.popup.background.topLeftRadius, 0);
            compare(selector.popup.background.bottomLeftRadius, Design.radiusControl);
            compare(selector.popup.y, selector.height - Design.borderWidth);
            selector.popup.close();
            wait(50);
            verify(selector.popup.reveal > 0 && selector.popup.reveal < 1);
            selector.popup.open();
            tryCompare(selector.popup, "reveal", 1);
            compare(selector.popup.opacity, 1);
            selector.currentIndex = selector.count - 1;
            selector.popup.contentItem.positionViewAtEnd();
            wait(200);
            grabImage(scene).save("/tmp/qs-select-rounded.png");
            selector.popup.close();
            tryCompare(selector.popup, "reveal", 0);
            compare(selector.background.bottomRightRadius, Design.radiusControl);
        }
    }
}
