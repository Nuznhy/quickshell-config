import QtQuick
import "ui" as UI
import Quickshell
import Quickshell.Hyprland
import "../config"
import "../services"
import "../services/WorkspacePreviewData.js" as PreviewData
import "PopupPlacement.js" as Placement

Item {
    id: root
    objectName: "workspace-preview"
    width: 0; height: 0
    required property var barWindow
    property var anchorItem: null
    property int workspaceId: -1
    property string highlightedAddress: ""
    property bool opened: false
    readonly property var previewItem: content.item
    readonly property var workspace: Hyprland.workspaces.values.find(ws => ws.id === workspaceId)
    readonly property var monitor: workspace?.monitor || Hyprland.monitors.values.find(m => m.id === Workspaces.getWsWindows(workspaceId)[0]?.monitor)
    readonly property var screen: Quickshell.screens.find(screen => screen.name === monitor?.name) || barWindow?.screen
    readonly property var monitorBounds: PreviewData.bounds(monitor, screen)
    readonly property real previewWidth: Math.max(1, Math.min(380,
        (barWindow?.screen?.width || 800) - 48,
        Math.min(260, (barWindow?.screen?.height || 600) - 100) * monitorBounds.width / monitorBounds.height))

    function request(wsId, item, address) {
        hideDelay.stop();
        const changed = workspaceId !== wsId;
        workspaceId = wsId;
        anchorItem = item;
        highlightedAddress = address || "";
        if (!opened && (changed || !showDelay.running)) showDelay.restart();
        if (opened) Qt.callLater(popup.anchor.updateAnchor);
    }
    function leave(wsId) {
        if (workspaceId !== wsId) return;
        showDelay.stop();
        hideDelay.restart();
    }
    function close() {
        showDelay.stop(); hideDelay.stop(); opened = false;
        highlightedAddress = "";
    }
    Timer {
        id: showDelay
        interval: 280
        onTriggered: { if (root.anchorItem && Workspaces.occupiedWorkspaceIds.includes(root.workspaceId)) root.opened = true; }
    }
    Timer { id: hideDelay; interval: 90; onTriggered: root.close() }
    Connections { target: root.barWindow; function onCloseAllPopups() { root.close(); } }
    Connections {
        target: Workspaces
        function onOccupiedWorkspaceIdsChanged() { if (!Workspaces.occupiedWorkspaceIds.includes(root.workspaceId)) root.close(); }
    }
    PopupWindow {
        id: popup
        visible: root.opened && !!root.anchorItem && !!root.barWindow?.visible
        anchor.window: root.barWindow
        anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.SlideY
        anchor.onAnchoring: {
            if (!root.anchorItem || !root.barWindow?.contentItem) return;
            const point = root.anchorItem.mapToItem(root.barWindow.contentItem, 0, 0);
            const pos = Placement.position(Theme.barPosition, point.x, point.y,
                root.anchorItem.width, root.anchorItem.height, root.barWindow.width, root.barWindow.height,
                popup.width, popup.height, "center", 0, false);
            popup.anchor.rect = Qt.rect(pos.x, pos.y, 1, 1);
        }
        implicitWidth: root.previewWidth + Settings.popupPadding * 2
        implicitHeight: (content.item?.implicitHeight || 0) + Settings.popupPadding * 2
        color: "transparent"
        // Passive preview: never intercept clicks or grab keyboard focus.
        mask: Region {}
        UI.MenuSurface {
            anchors.fill: parent
        }
        Loader {
            id: content
            active: popup.visible
            x: Settings.popupPadding; y: Settings.popupPadding
            width: root.previewWidth
            sourceComponent: WorkspacePreviewContent {
                workspaceId: root.workspaceId
                monitorName: root.monitor?.name || root.screen?.name || ""
                monitorBounds: root.monitorBounds
                highlightedAddress: root.highlightedAddress
            }
        }
    }
}
