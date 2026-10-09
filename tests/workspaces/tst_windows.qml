import QtQuick
import QtTest
import "services/WorkspaceWindows.js" as Windows
import "components"
import "config"
import "services"

Item {
    width: 300; height: 200
    AnimatedAppIcons { id: first; x: 20; y: 20; icons: []; activeWorkspace: true }
    AnimatedAppIcons { id: second; x: 120; y: 20; icons: []; activeWorkspace: false }
    TestCase {
        name: "WorkspaceWindows"
        when: windowShown
        function client(address, workspace, app) {
            return {address: address, workspace: {id: workspace}, class: app || "ghostty", initialClass: app || "ghostty", mapped: true, focusHistoryID: 0};
        }
        function icon(appClass, initialClass) { return {appId: appClass, source: ""}; }
        function pair() { return Windows.build([client("0xabc",1),client("0xdef",1)],icon)[1]; }
        function init() {
            first.icons = []; second.icons = []; Theme.verticalBar = false;
            first.nerdFontIcons = false;
            Workspaces.lastFocused = ""; Workspaces.urgent = [];
            wait(250);
        }
        function test_same_app_windows_and_icon_cache() {
            let calls = 0;
            const clients = [client("0xabc",1),client("0xdef",1),client("0xff",2)];
            const result = Windows.build(clients,(app, initial) => {calls++; return icon(app, initial);});
            compare(result[1].length,2); compare(result[2].length,1); compare(calls,1);
            compare(result[1][0].addresses,["0xabc"]); compare(result[1][1].addresses,["0xdef"]);
            clients[0].focusHistoryID = 10;
            compare(JSON.stringify(Windows.build(clients,icon)),JSON.stringify(result));
        }
        function test_nerd_icons_map_apps_and_unknown_apps_have_fallback() {
            first.nerdFontIcons = true;
            first.icons = Windows.build([client("0xabc", 1, "org.telegram.desktop"),
                client("0xdef", 1, "unknown-app")], icon)[1];
            wait(250);
            compare(findChild(first, "workspace-app-glyph-0xabc").text, "");
            compare(findChild(first, "workspace-app-glyph-0xdef").text, "󰏗");
            first.nerdFontIcons = false;
            compare(first.count, 2);
        }
        function test_filtering_and_normalization() {
            const unmapped=client("0xbbb",2); unmapped.mapped=false;
            const result=Windows.build([client("0XABC",1),client("0xabc",1),client("0x123",-99),unmapped,client("bad address",3)],icon);
            compare(Object.keys(result),["1"]);
            compare(result[1].length,1); compare(result[1][0].address,"0xabc");
        }
        function test_clicks_focus_each_window_and_badges_are_separate() {
            first.icons=pair(); wait(250);
            compare(first.count,2);
            const a=findChild(first,"workspace-window-0xabc"), b=findChild(first,"workspace-window-0xdef");
            verify(a!==null && b!==null);
            Workspaces.urgent=["0xabc"];
            tryCompare(a,"needsAttention",true); compare(b.needsAttention,false);
            mouseClick(b,b.width/2,b.height/2); compare(Workspaces.lastFocused,"0xdef");
            mouseClick(a,a.width/2,a.height/2); compare(Workspaces.lastFocused,"0xabc");
        }
        function test_close_only_removes_that_window() {
            const entries=pair(); first.icons=entries; wait(250);
            first.icons=[entries[1]];
            tryCompare(first,"count",1);
            verify(findChild(first,"workspace-window-0xdef")!==null);
        }
        function test_move_and_quick_return_preserve_siblings() {
            const entries=pair(); first.icons=entries; wait(250);
            first.icons=[entries[0]]; second.icons=[entries[1]]; wait(60);
            first.icons=entries; second.icons=[];
            wait(250);
            compare(first.count,2); compare(second.count,0);
            first.icons=[entries[0]]; second.icons=[entries[1]]; wait(250);
            compare(first.count,1); compare(second.count,1);
        }
        function test_vertical_roundtrip_keeps_duplicate_icons() {
            first.icons=pair(); wait(250);
            const a=findChild(first,"workspace-window-0xabc"), b=findChild(first,"workspace-window-0xdef");
            verify(b.x>a.x);
            Theme.verticalBar=true; wait(250); verify(b.y>a.y); compare(b.x,a.x);
            Theme.verticalBar=false; wait(250); verify(b.x>a.x); compare(b.y,a.y);
            compare(first.count,2);
        }
    }
}
