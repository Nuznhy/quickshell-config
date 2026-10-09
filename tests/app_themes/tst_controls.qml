import QtQuick
import QtTest
import "components"
import "services"
import "config"
Rectangle {
    width: 800; height: 600
    color: Theme.bg
    ApplicationThemes { id: panel; x: 20; y: 20; width: 760 }
    TestCase {
        name: "ApplicationThemes"
        when: windowShown
        function init() { AppTheming.reset(); panel.width = 760; panel.detailsId = ""; wait(20); }
        function test_enable_and_disable() {
            const toggle = findChild(panel, "app-theme-ghostty");
            verify(toggle !== null);
            mouseClick(toggle);
            compare(AppTheming.lastTarget, "ghostty");
            compare(AppTheming.lastEnabled, true);
            wait(20);
            mouseClick(findChild(panel, "app-theme-ghostty"));
            compare(AppTheming.lastEnabled, false);
        }
        function test_hyprland_override_toggle() {
            AppTheming.targets = [{id: "hyprland", name: "Hyprland appearance", available: true, enabled: false, state: "off", message: ""},
                {id: "hyprland-colors", name: "Hyprland colors", available: true, enabled: false, state: "off", message: ""}];
            wait(20);
            mouseClick(findChild(panel, "app-theme-hyprland"));
            compare(AppTheming.lastTarget, "hyprland");
            verify(!AppTheming.targets.find(t => t.id === "hyprland-colors").enabled);
            compare(AppTheming.lastEnabled, true);
            wait(20);
            mouseClick(findChild(panel, "app-theme-hyprland"));
            compare(AppTheming.lastEnabled, false);
        }
        function test_missing_dependency_cannot_enable() {
            const toggle = findChild(panel, "app-theme-discord");
            compare(toggle.enabled, false);
        }
        function test_missing_dependency_can_disable_previous_sync() {
            AppTheming.setEnabled("discord", true);
            wait(20);
            const toggle = findChild(panel, "app-theme-discord");
            compare(toggle.enabled, true);
            mouseClick(toggle);
            compare(AppTheming.lastEnabled, false);
        }
        function test_error_is_visible_and_wraps_without_opening_details() {
            const message = "Permission denied: /home/user/.config/ghostty/config\nCould not write <theme> colors. Check the file permissions and retry.";
            AppTheming.targets = AppTheming.targets.map(t => t.id === "ghostty"
                ? Object.assign({}, t, {enabled: true, state: "error", message: message}) : t);
            panel.width = 280;
            const card = findChild(panel, "app-theme-card-ghostty");
            const status = findChild(panel, "app-theme-status-ghostty");
            tryCompare(status, "text", message);
            compare(status.textFormat, Text.PlainText);
            compare(panel.detailsId, "");
            tryVerify(() => status.height > 20 && card.height > 82);
            verify(!status.truncated);
            verify(status.mapToItem(card, 0, status.height).y <= card.height - 12);
            verify(findChild(panel, "app-theme-retry-ghostty").visible);
            const next = findChild(panel, "app-theme-card-discord");
            tryVerify(() => next.y >= card.y + card.height);
            grabImage(panel.parent).save("/tmp/quickshell-app-theme-error.png");
            AppTheming.targets = AppTheming.targets.map(t => t.id === "ghostty"
                ? Object.assign({}, t, {state: "applied", message: "Applied"}) : t);
            tryCompare(findChild(panel, "app-theme-status-ghostty"), "text", "Synced");
            tryCompare(findChild(panel, "app-theme-card-ghostty"), "height", 82);
        }
        function test_error_without_message_has_fallback() {
            AppTheming.targets = AppTheming.targets.map(t => t.id === "ghostty"
                ? Object.assign({}, t, {state: "error", message: ""}) : t);
            tryCompare(findChild(panel, "app-theme-status-ghostty"), "text",
                "Theme update failed. No error details were reported.");
        }
        function test_adaptive_grid_and_details() {
            AppTheming.targets = AppTheming.targets.concat([
                {id: "gtk", name: "GTK 3 / 4", available: true, enabled: true, state: "restart", message: "Reopen GTK apps to load colors."},
                {id: "qt", name: "Qt / KDE", available: true, enabled: true, state: "applied", message: "Applied"},
                {id: "zen", name: "Zen Browser", available: true, enabled: true, state: "restart", message: "Restart Zen to load colors."},
                {id: "tmux", name: "tmux", available: true, enabled: true, state: "applied", message: "Applied"}]);
            const grid = findChild(panel, "app-themes-grid");
            tryCompare(grid, "columns", 3);
            const first = findChild(panel, "app-theme-card-ghostty");
            const second = findChild(panel, "app-theme-card-discord");
            tryVerify(() => second.x > first.x && second.y === first.y);
            mouseClick(findChild(panel, "app-theme-details-gtk"));
            compare(panel.detailTarget.name, "GTK 3 / 4");
            compare(findChild(panel, "app-theme-details-panel").visible, true);
            grabImage(panel.parent).save("/tmp/quickshell-app-theme-grid.png");
            panel.width = 500;
            tryCompare(grid, "columns", 2);
            panel.width = 280;
            tryCompare(grid, "columns", 1);
            tryVerify(() => second.y > first.y);
            verify(first.width <= panel.width);
        }
    }
}
