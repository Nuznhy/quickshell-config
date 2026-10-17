import QtQuick
import QtTest
import qs.modules.workspaces
import qs.config
import qs.config as ConfigScripts

Rectangle {
    width: 640; height: 680
    color: Theme.bg
    WorkspaceSettingsPanel { id: panel; x: 20; y: 20; width: 600 }
    TestCase {
        name: "WorkspaceSettings"
        when: windowShown
        function init() { WorkspaceAppearance.reset(); wait(20); }
        function test_controls_and_reset() {
            mouseClick(findChild(panel, "workspace-icon-style-nerd"));
            compare(WorkspaceAppearance.iconStyle, "nerd");
            mouseClick(findChild(panel, "workspace-icon-capsule"));
            compare(WorkspaceAppearance.capsule, true);
            const input = findChild(panel, "workspace-separator-input");
            input.forceActiveFocus();
            input.selectAll();
            keyClick(Qt.Key_Bar);
            keyClick(Qt.Key_Return);
            compare(WorkspaceAppearance.separator, "|");
            mouseClick(findChild(panel, "workspace-show-icons"));
            compare(WorkspaceAppearance.showIcons, false);
            verify(!input.enabled);
            verify(!findChild(panel, "workspace-icon-style-nerd").enabled);
            compare(WorkspaceAppearance.capsule, true);
            mouseClick(findChild(panel, "workspace-show-icons"));
            verify(input.enabled);
            wait(250);
            grabImage(panel.parent).save("/tmp/quickshell-workspace-settings.png");
            mouseClick(findChild(panel, "workspace-settings-reset"));
            compare(WorkspaceAppearance.state, ConfigScripts.WorkspaceAppearanceData.defaults());
        }
        function test_saved_state_validation() {
            compare(ConfigScripts.WorkspaceAppearanceData.normalize({version: 1}), ConfigScripts.WorkspaceAppearanceData.defaults());
            compare(ConfigScripts.WorkspaceAppearanceData.normalize({version: 1, showIcons: "false", iconStyle: "invalid", capsule: 1}).showIcons, true);
            compare(ConfigScripts.WorkspaceAppearanceData.normalize({version: 1, separator: ""}).separator, "");
            compare(ConfigScripts.WorkspaceAppearanceData.normalize({version: 1, separator: "1234567󰏗x"}).separator, "1234567󰏗");
            compare(ConfigScripts.WorkspaceAppearanceData.normalize({version: 1, separator: "x\ny"}).separator, "x y");
            let failed = false;
            try { ConfigScripts.WorkspaceAppearanceData.normalize({version: 2}); } catch (error) { failed = true; }
            verify(failed);
        }
    }
}
