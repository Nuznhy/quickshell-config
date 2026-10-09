import QtQuick
import QtTest
import "config"
import "services"
import "components"
import "modules/bar/widgets"
import "services/WorkspacePreviewData.js" as Data

Rectangle {
    width: 700; height: 480
    color: Theme.bg
    WorkspaceBar { id: bar; x: 20; y: 20 }
    WorkspacePreviewContent {
        id: content
        x:20; y:100; width:380; height:implicitHeight
        workspaceId:1
        monitorBounds: ({x:1920,y:-100,width:1920,height:1080})
    }
    TestCase {
        name: "WorkspacePreview"
        when: windowShown
        function sample(address, x, width) {
            return {address:address,workspace:{id:1},mapped:true,at:[x,0],size:[width,900],monitor:1,title:"Terminal",class:"ghostty",focusHistoryID:0};
        }
        function init() {
            Theme.verticalBar=false;
            WorkspaceAppearance.reset();
            content.highlightedAddress="";
            Workspaces.previewWindows=Data.windows([sample("0xabc",1920,960),sample("0xdef",2880,960)])[1];
            Workspaces.workspaceIcons={"1":[{appId:"ghostty",source:"",address:"0xabc",addresses:["0xabc"]},{appId:"ghostty",source:"",address:"0xdef",addresses:["0xdef"]}]};
            mouseMove(content.parent,650,450);
            wait(300);
        }
        function test_workspace_appearance_keeps_icons_clickable_and_hides_spacing() {
            const slot = findChild(bar, "workspace-slot-1");
            const group = findChild(bar, "workspace-icon-group-1");
            const separator = findChild(bar, "workspace-separator-1");
            const initialWidth = slot.width;
            WorkspaceAppearance.setOption("capsule", true);
            WorkspaceAppearance.setOption("iconStyle", "nerd");
            WorkspaceAppearance.setOption("separator", "|");
            tryVerify(() => slot.width > initialWidth);
            compare(group.border.width, 1);
            verify(separator.visible);
            const glyph = findChild(bar, "workspace-app-glyph-0xdef");
            verify(glyph.visible);
            compare(glyph.text, "");
            compare(findChild(bar, "workspace-app-image-0xdef").source.toString(), "");
            const second = findChild(bar, "workspace-window-0xdef");
            mouseClick(second, second.width / 2, second.height / 2);
            compare(Workspaces.lastFocused, "0xdef");
            Theme.verticalBar = true;
            wait(300);
            verify(group.width <= slot.width);
            verify(group.height > second.height);
            WorkspaceAppearance.setOption("showIcons", false);
            tryCompare(group, "visible", false);
            verify(!separator.visible);
            Theme.verticalBar = false;
            tryVerify(() => slot.width < initialWidth);
            WorkspaceAppearance.setOption("showIcons", true);
            WorkspaceAppearance.setOption("separator", "");
            tryCompare(group, "visible", true);
            verify(!separator.visible);
            verify(findChild(bar, "workspace-window-0xabc") !== null);
            wait(350);
            grabImage(content.parent).save("/tmp/quickshell-workspace-capsule.png");
        }
        function test_geometry_uses_monitor_origin_and_logical_scale() {
            const monitor={x:-1920,y:-100,width:3840,height:2160,scale:2,lastIpcObject:{transform:0}};
            const bounds=Data.bounds(monitor,null);
            compare(bounds.width,1920); compare(bounds.height,1080);
            const rect=Data.project({x:-960,y:440,width:960,height:540},bounds,380,213.75);
            compare(rect.x,190); compare(rect.y,106.875); compare(rect.width,190);
            monitor.lastIpcObject.transform=1;
            compare(Data.bounds(monitor,null).width,1080);
            compare(Data.bounds(monitor,{width:1000,height:2000}).height,2000);
        }
        function test_unmapped_and_invalid_windows_excluded() {
            const hidden=sample("0xbbb",0,100); hidden.hidden=true;
            const invalid=sample("0xccc",0,0);
            const result=Data.windows([sample("0XABC",0,100),sample("0xabc",0,100),hidden,invalid]);
            compare(result[1].length,1); compare(result[1][0].address,"0xabc");
        }
        function test_highlight_matches_exact_duplicate_window() {
            const highlight=findChild(content,"workspace-preview-highlight");
            verify(!highlight.visible);
            content.highlightedAddress="0xdef";
            tryCompare(highlight,"visible",true);
            compare(highlight.x,190); compare(highlight.width,190);
            content.highlightedAddress="0xabc";
            compare(highlight.x,0);
            grabImage(content.parent).save("/tmp/quickshell-workspace-preview.png");
            content.highlightedAddress="0xdead";
            verify(!highlight.visible);
        }
        function test_hover_routes_workspace_and_exact_app_without_focus() {
            const preview=findChild(bar,"workspace-preview");
            const slot=findChild(bar,"workspace-slot-1");
            verify(slot!==null);
            mouseMove(slot,6,20); wait(30);
            compare(preview.workspaceId,1);
            compare(preview.highlightedAddress,"");
            const second=findChild(bar,"workspace-window-0xdef");
            mouseMove(second,second.width/2,second.height/2); wait(30);
            compare(preview.highlightedAddress,"0xdef");
            mouseClick(second,second.width/2,second.height/2);
            compare(Workspaces.lastFocused,"0xdef");
            compare(preview.workspaceId,-1);
            mouseMove(content.parent,650,450); wait(30);
            compare(preview.workspaceId,-1);
        }
    }
}
