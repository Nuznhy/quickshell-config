import QtQuick
import QtTest
import "components"
import "config"
import "config/WidgetStyle.js" as Style

Rectangle {
    width: 680; height: 700
    color: "#191724"
    WidgetStyleSettings { id: settings; x: 20; y: 100; width: 620 }
    BarHoverIndicator { id: first; x: 20; y: 20; width: 100; height: 42; hovered: false }
    BarHoverIndicator { id: second; x: 160; y: 20; width: 100; height: 42; hovered: first.hovered }
    TestCase {
        name: "WidgetStyling"
        when: windowShown
        function init() {
            first.hovered = false; first.active = false; first.focused = false;
            Theme.verticalBar = false;
            Theme.resetWidgetStyle();
            wait(350);
        }
        function test_defaults_validation() {
            compare(Style.normalize(undefined), Style.defaults());
            compare(Style.normalize({lines: "invalid", background: "instant", duration: -1, strength: "12"}),
                {lines: "animated", background: "instant", duration: 300, strength: 12});
            compare(Style.normalize({duration: 410, strength: 12.4}).duration, 420);
            compare(Style.normalize({duration: Infinity, strength: 50}), Style.defaults());
        }
        function test_modes_and_interruption() {
            first.hovered = true;
            tryVerify(() => first.lineOpacity > 0 && first.lineOpacity < 1);
            Theme.setWidgetStyle("lines", "off");
            compare(first.lineOpacity, 0);
            first.active = true;
            compare(first.lineOpacity, 0);
            Theme.setWidgetStyle("lines", "instant");
            compare(first.lineOpacity, 1);
            first.hovered = false; first.active = false;
            compare(first.lineOpacity, 0);
            Theme.setWidgetStyle("background", "animated");
            first.hovered = true;
            tryVerify(() => first.backgroundOpacity > 0 && first.backgroundOpacity < 0.12);
            Theme.setWidgetStyle("background", "off");
            compare(first.backgroundOpacity, 0);
        }
        function test_shared_background_focus_and_geometry() {
            Theme.setWidgetStyle("lines", "off");
            Theme.setWidgetStyle("background", "instant");
            Theme.setWidgetStyle("strength", 24);
            first.hovered = true;
            compare(first.backgroundOpacity, 0.24);
            compare(second.backgroundOpacity, first.backgroundOpacity);
            compare(first.width, 100); compare(first.height, 42);
            first.hovered = false; first.active = true;
            compare(first.backgroundOpacity, 0);
            first.focused = true;
            verify(findChild(first, "widget-focus-outline").visible);
            compare(first.lineOpacity, 0);
            Theme.setWidgetStyle("lines", "instant");
            Theme.verticalBar = true;
            compare(findChild(first, "widget-leading-line").width, 2);
            compare(findChild(first, "widget-trailing-line").height, first.height);
        }
        function test_controls_preview_and_reset() {
            const duration = findChild(settings, "widget-style-duration");
            const strength = findChild(settings, "widget-style-strength");
            verify(duration.enabled); verify(!strength.enabled);
            findChild(settings, "widget-style-lines").selected(0);
            findChild(settings, "widget-style-background").selected(1);
            verify(!duration.enabled); verify(strength.enabled);
            Theme.setWidgetStyle("strength", 23);
            const preview = findChild(settings, "widget-style-preview");
            mouseMove(preview, 20, 20);
            mouseClick(preview, 20, 20);
            verify(preview.selected);
            compare(Theme.widgetStyle.strength, 23);
            wait(200);
            grabImage(settings).save('/tmp/qs-widget-styling-horizontal.png');
            Theme.verticalBar = true;
            mouseMove(preview, 20, 20);
            wait(200);
            grabImage(settings).save('/tmp/qs-widget-styling-vertical.png');
            mouseClick(findChild(settings, "widget-style-reset"));
            compare(Theme.widgetStyle, Style.defaults());
            compare(Theme.verticalBar, true);
        }
    }
}
