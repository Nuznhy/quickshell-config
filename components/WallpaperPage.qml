pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.folderlistmodel
import "../config"

ColumnLayout {
    id: root
    spacing: 14
    property string selectedMonitor: ""
    readonly property string activeMonitor: Theme.connectedScreens.some(screen => screen.name === selectedMonitor)
        ? selectedMonitor : (Theme.connectedScreens[0]?.name || "")
    readonly property int imageCount: folderLoader.item?.files.count || 0
    readonly property bool folderLoading: folderLoader.item?.files.status === FolderListModel.Loading
    signal dismissed
    Keys.onEscapePressed: dismissed()

    FolderDialog {
        id: folderPicker
        title: "Wallpaper folder"
        onAccepted: Theme.setWallpaperFolder(selectedFolder.toString())
    }
    Loader {
        id: folderLoader
        active: root.visible && Theme.ready && Theme.wallpaperFolder.length > 0
        visible: false
        sourceComponent: Item {
            property alias files: files
            FolderListModel {
                id: files
                folder: Theme.wallpaperFolder
                nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.avif", "*.svg"]
                caseSensitive: false
                showDirs: false
                showDotAndDotDot: false
                showOnlyReadable: true
                sortField: FolderListModel.Name
                sortCaseSensitive: false
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: "Wallpapers"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 19
            font.bold: true
        }
        NotificationButton {
            text: "Choose folder…"
            enabled: Theme.ready
            onClicked: {
                if (Theme.wallpaperFolder) folderPicker.currentFolder = Theme.wallpaperFolder;
                folderPicker.open();
            }
        }
        NotificationButton {
            text: "×"
            implicitWidth: 32
            visible: Theme.wallpaperFolder.length > 0
            enabled: Theme.ready
            Accessible.name: "Remove gallery folder"
            ToolTip.visible: hovered
            ToolTip.text: Accessible.name
            ToolTip.delay: 600
            onClicked: Theme.setWallpaperFolder("")
        }
    }
    Text {
        Layout.fillWidth: true
        visible: Theme.wallpaperFolder.length > 0
        text: {
            try { return decodeURIComponent(Theme.wallpaperFolder.replace(/^file:\/\//, "")); }
            catch (error) { return Theme.wallpaperFolder; }
        }
        elide: Text.ElideMiddle
        textFormat: Text.PlainText
        color: Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }
    WallpaperSelector {
        id: monitors
        Layout.fillWidth: true
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
            Layout.fillWidth: true
            text: "Images" + (Theme.wallpaperFolder ? " · " + root.imageCount : "")
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.bold: true
        }
        Text {
            text: "Apply to"
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
        ComboBox {
            id: monitorPicker
            objectName: "wallpaper-target"
            Layout.preferredWidth: Math.min(200, root.width * 0.4)
            model: Theme.connectedScreens
            textRole: "name"
            currentIndex: Theme.connectedScreens.findIndex(screen => screen.name === root.activeMonitor)
            onActivated: index => root.selectedMonitor = Theme.connectedScreens[index].name
            enabled: Theme.connectedScreens.length > 0
            Accessible.name: "Monitor for gallery wallpaper"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            palette.buttonText: Theme.text
            palette.text: Theme.text
            palette.window: Theme.surface
            palette.base: Theme.surface
            palette.highlight: Theme.overlay
            palette.highlightedText: Theme.text
            background: Rectangle {
                radius: 8
                color: Theme.surface
                border.color: monitorPicker.activeFocus ? Theme.iris : Theme.highlightMed
            }
        }
    }
    Text {
        Layout.fillWidth: true
        visible: !root.imageCount || root.folderLoading
        text: !Theme.wallpaperFolder ? "Choose a folder to browse its images here."
            : root.folderLoading ? "Loading images…" : "No supported images found. The folder may be empty or unavailable."
        color: Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }
    GridView {
        id: gallery
        objectName: "wallpaper-gallery"
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(420, Math.ceil(count / columns) * cellHeight)
        readonly property int columns: Math.max(1, Math.floor(width / 170))
        cellWidth: width / columns
        cellHeight: cellWidth * 9 / 16 + 38
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        visible: count > 0
        model: folderLoader.item?.files || null
        ScrollBar.vertical: ScrollBar {}
        delegate: Button {
            id: tile
            required property url fileUrl
            required property string fileName
            objectName: "wallpaper-image-" + fileName
            width: gallery.cellWidth - 10
            height: gallery.cellHeight - 10
            padding: 5
            topInset: 0
            bottomInset: 0
            hoverEnabled: true
            enabled: Theme.ready && root.activeMonitor !== "" && thumbnail.status === Image.Ready
            Accessible.name: "Set " + fileName + " on " + root.activeMonitor
            onClicked: monitors.choose(root.activeMonitor, fileUrl)
            HoverHandler { cursorShape: tile.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
            background: Rectangle {
                radius: 10
                color: tile.hovered ? Theme.overlay : Theme.surface
                border.width: 2
                border.color: tile.activeFocus || Theme.wallpaperFor(root.activeMonitor) === tile.fileUrl.toString()
                    ? Theme.iris : tile.hovered ? Theme.highlightHigh : Theme.highlightMed
            }
            contentItem: Column {
                spacing: 6
                Image {
                    id: thumbnail
                    width: parent.width
                    height: tile.height - 34
                    source: tile.fileUrl
                    sourceSize: Qt.size(400, 225)
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    Text {
                        anchors.centerIn: parent
                        visible: thumbnail.status !== Image.Ready
                        text: thumbnail.status === Image.Error ? "Unavailable" : "Loading…"
                        color: Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }
                Text {
                    width: parent.width
                    text: tile.fileName
                    textFormat: Text.PlainText
                    elide: Text.ElideMiddle
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }
    }
}
