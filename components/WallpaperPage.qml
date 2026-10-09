pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.folderlistmodel
import "../config"

UI.ColumnLayout {
    id: root
    spacing: Design.space12
    property string selectedMonitor: ""
    property string selectedMode: Theme.mode
    readonly property string wallpaperMode: Theme.separateWallpapers ? selectedMode : "shared"
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
    UI.RowLayout {
        Layout.fillWidth: true
        UI.Text {
            Layout.fillWidth: true
            text: "Wallpapers"
            color: Design.text
            font.family: Design.fontFamily
            role: "panel"
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
        UI.IconButton {
            text: "×"
            implicitWidth: 32
            visible: Theme.wallpaperFolder.length > 0
            enabled: Theme.ready
            Accessible.name: "Remove gallery folder"
            onClicked: Theme.setWallpaperFolder("")
        }
    }
    UI.Text {
        Layout.fillWidth: true
        visible: Theme.wallpaperFolder.length > 0
        text: {
            try { return decodeURIComponent(Theme.wallpaperFolder.replace(/^file:\/\//, "")); }
            catch (error) { return Theme.wallpaperFolder; }
        }
        elide: Text.ElideMiddle
        textFormat: Text.PlainText
        color: Design.textSecondary
        font.family: Design.fontFamily
        role: "label"
    }
    UI.RowLayout {
        Layout.fillWidth: true
        spacing: Design.space12
        UI.Text {
            Layout.fillWidth: true
            text: "Different wallpapers for light and dark"
            wrapMode: Text.WordWrap
            color: Design.text
            font.family: Design.fontFamily
            role: "body"
        }
        ControlSwitch {
            objectName: "wallpaper-separate-modes"
            value: Theme.separateWallpapers
            enabled: Theme.ready
            Accessible.name: "Different wallpapers for light and dark"
            onChangeRequested: value => {
                if (value) root.selectedMode = Theme.mode;
                Theme.setSeparateWallpapers(value);
            }
        }
    }
    UI.RowLayout {
        objectName: "wallpaper-mode-options"
        visible: Theme.separateWallpapers
        Layout.fillWidth: true
        spacing: Design.space8
        Repeater {
            model: ["light", "dark"]
            delegate: NotificationButton {
                required property string modelData
                objectName: "wallpaper-mode-" + modelData
                text: modelData === "light" ? "Light" : "Dark"
                accent: root.selectedMode === modelData
                enabled: Theme.ready
                onClicked: root.selectedMode = modelData
            }
        }
        Item { Layout.fillWidth: true }
    }
    WallpaperSelector {
        id: monitors
        Layout.fillWidth: true
        wallpaperMode: root.wallpaperMode
    }
    UI.RowLayout {
        Layout.fillWidth: true
        spacing: Design.space8
        UI.Text {
            Layout.fillWidth: true
            text: "Images" + (Theme.wallpaperFolder ? " · " + root.imageCount : "")
            color: Design.text
            font.family: Design.fontFamily
            role: "section"
            font.bold: true
        }
        UI.Text {
            text: "Apply to"
            color: Design.textSecondary
            font.family: Design.fontFamily
            role: "label"
        }
        UI.ComboBox {
            id: monitorPicker
            objectName: "wallpaper-target"
            Layout.preferredWidth: Math.min(200, root.width * 0.4)
            model: Theme.connectedScreens
            textRole: "name"
            currentIndex: Theme.connectedScreens.findIndex(screen => screen.name === root.activeMonitor)
            onActivated: index => root.selectedMonitor = Theme.connectedScreens[index].name
            enabled: Theme.connectedScreens.length > 0
            Accessible.name: "Monitor for gallery wallpaper"

        }
    }
    UI.Text {
        Layout.fillWidth: true
        visible: !root.imageCount || root.folderLoading
        text: !Theme.wallpaperFolder ? "Choose a folder to browse its images here."
            : root.folderLoading ? "Loading images…" : "No supported images found. The folder may be empty or unavailable."
        color: Design.textSecondary
        font.family: Design.fontFamily
        role: "body"
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
        ScrollBar.vertical: UI.ScrollBar {}
        delegate: UI.Button {
        highlighted: Theme.wallpaperFor(root.activeMonitor, root.wallpaperMode) === fileUrl.toString()
            id: tile
            required property url fileUrl
            required property string fileName
            objectName: "wallpaper-image-" + fileName
            width: gallery.cellWidth - 10
            height: gallery.cellHeight - 10
            padding: Design.space4
            topInset: 0
            bottomInset: 0
            enabled: Theme.ready && root.activeMonitor !== "" && thumbnail.status === Image.Ready
            Accessible.name: "Set " + fileName + " on " + root.activeMonitor + " for " + root.wallpaperMode
            onClicked: monitors.choose(root.activeMonitor, fileUrl)

            contentItem: Column {
                spacing: Design.space4
                Image {
                    id: thumbnail
                    width: parent.width
                    height: tile.height - 34
                    source: tile.fileUrl
                    sourceSize: Qt.size(400, 225)
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    UI.Text {
                        anchors.centerIn: parent
                        visible: thumbnail.status !== Image.Ready
                        text: thumbnail.status === Image.Error ? "Unavailable" : "Loading…"
                        color: Design.textSecondary
                        font.family: Design.fontFamily
                        role: "caption"
                    }
                }
                UI.Text {
                    width: parent.width
                    text: tile.fileName
                    textFormat: Text.PlainText
                    elide: Text.ElideMiddle
                    color: Design.text
                    font.family: Design.fontFamily
                    role: "caption"
                }
            }
        }
    }
}
