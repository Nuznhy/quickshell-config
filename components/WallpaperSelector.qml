pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "../config"

GridLayout {
    id: root
    columns: Math.max(1, Math.min(cards.count, Math.floor((width + columnSpacing) / 252)))
    columnSpacing: 12
    rowSpacing: 12
    readonly property bool choosingWallpaper: picker.visible

    function localImageUrl(urls) {
        if (!urls || urls.length !== 1) return "";
        const source = urls[0].toString();
        return source.startsWith("file:///") ? source : "";
    }
    function choose(monitorName, source) {
        for (let index = 0; index < cards.count; ++index) {
            const card = cards.itemAt(index);
            if (card && card.modelData.name === monitorName) {
                card.loadImage(source.toString());
                return;
            }
        }
    }
    function browse(monitorName) {
        picker.monitorName = monitorName;
        picker.open();
    }
    FileDialog {
        id: picker
        property string monitorName: ""
        title: "Wallpaper for " + monitorName
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp *.avif *.svg)", "All files (*)"]
        onAccepted: root.choose(monitorName, selectedFile)
    }

    component IconButton: NotificationButton {
        id: control
        implicitWidth: 32
        implicitHeight: 32
        leftPadding: 6
        rightPadding: 6
        ToolTip.visible: hovered
        ToolTip.delay: 600
        ToolTip.text: Accessible.name
        contentItem: Text {
            text: control.text
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 18
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Repeater {
        id: cards
        model: Theme.connectedScreens
        delegate: Rectangle {
            id: card
            required property var modelData
            objectName: "wallpaper-card-" + modelData.name
            readonly property string source: Theme.wallpaperFor(modelData.name)
            property string candidate: ""
            property string errorMessage: ""
            readonly property bool loading: probe.status === Image.Loading
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            Layout.minimumWidth: 0
            implicitHeight: content.implicitHeight + 24
            radius: 12
            color: Theme.surface
            border.color: dropArea.containsDrag ? Theme.iris : Theme.highlightMed
            border.width: dropArea.containsDrag ? 2 : 1
            Behavior on border.color { ColorAnimation { duration: 120 } }

            function loadImage(value) {
                if (!Theme.ready) return;
                candidate = "";
                errorMessage = "";
                if (!root.localImageUrl([value])) {
                    errorMessage = "Choose one image from your computer.";
                    return;
                }
                candidate = value;
            }
            function acceptDrop(drop) {
                const value = root.localImageUrl(drop.urls);
                if (!Theme.ready || !drop.hasUrls || !value || !(drop.supportedActions & Qt.CopyAction)) {
                    drop.accepted = false;
                    return;
                }
                // Never accept a file-manager Move action: the original stays put.
                drop.accept(Qt.CopyAction);
                loadImage(value);
            }
            Image {
                id: probe
                visible: false
                source: card.candidate
                asynchronous: true
                cache: false
                sourceSize: Qt.size(640, 360)
                onStatusChanged: {
                    if (!card.candidate) return;
                    if (status === Image.Ready) {
                        Theme.setWallpaper(card.modelData.name, card.candidate);
                        card.candidate = "";
                    } else if (status === Image.Error) {
                        card.errorMessage = "Could not open this image. Try another file.";
                        card.candidate = "";
                    }
                }
            }
            ColumnLayout {
                id: content
                x: 12
                y: 12
                width: parent.width - 24
                spacing: 10
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: "󰍹"
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        color: Theme.iris
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: card.modelData.name
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.text
                    }
                }
                Button {
                    id: previewButton
                    objectName: "wallpaper-browse-" + card.modelData.name
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(140, Math.min(200, width * 9 / 16))
                    padding: 0
                    topInset: 0
                    bottomInset: 0
                    hoverEnabled: true
                    enabled: Theme.ready
                    Accessible.name: "Choose wallpaper for " + card.modelData.name
                    onClicked: root.browse(card.modelData.name)
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    background: Rectangle {
                        radius: 8
                        color: Theme.bg
                        border.color: previewButton.activeFocus ? Theme.iris : Theme.highlightMed
                    }
                    contentItem: Item {
                        clip: true
                        Image {
                            id: preview
                            anchors.fill: parent
                            anchors.margins: 4
                            source: card.source
                            sourceSize: Qt.size(800, 450)
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                        }
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            color: Theme.bg
                            opacity: preview.status === Image.Ready ? 0.75 : 1
                            visible: dropArea.containsDrag || previewButton.hovered || preview.status !== Image.Ready || card.loading
                        }
                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            spacing: 8
                            visible: dropArea.containsDrag || previewButton.hovered || preview.status !== Image.Ready || card.loading
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: dropArea.containsDrag ? "󰇚" : "󰥶"
                                color: Theme.iris
                                font.family: Theme.fontFamily
                                font.pixelSize: 30
                            }
                            Text {
                                width: parent.width
                                text: card.loading ? "Loading image…" : dropArea.containsDrag ? "Drop to set wallpaper"
                                    : preview.status === Image.Error ? "Choose another image" : "Drop an image or click to browse"
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: {
                            if (!card.source) return "No wallpaper";
                            const name = card.source.slice(card.source.lastIndexOf("/") + 1);
                            try { return decodeURIComponent(name); } catch (error) { return name; }
                        }
                        elide: Text.ElideMiddle
                        color: Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        textFormat: Text.PlainText
                    }
                    IconButton {
                        text: "󰉋"
                        enabled: Theme.ready
                        Accessible.name: "Browse wallpapers for " + card.modelData.name
                        onClicked: root.browse(card.modelData.name)
                    }
                    IconButton {
                        objectName: "wallpaper-clear-" + card.modelData.name
                        text: "󰆴"
                        enabled: Theme.ready && (card.source.length > 0 || card.loading)
                        Accessible.name: "Clear wallpaper for " + card.modelData.name
                        onClicked: {
                            card.candidate = "";
                            card.errorMessage = "";
                            Theme.setWallpaper(card.modelData.name, "");
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: card.errorMessage || (preview.status === Image.Error ? "Saved image is unavailable." : "")
                    color: Theme.love
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }
            DropArea {
                id: dropArea
                anchors.fill: parent
                enabled: Theme.ready
                onEntered: drag => {
                    drag.accepted = drag.hasUrls && !!root.localImageUrl(drag.urls)
                        && !!(drag.supportedActions & Qt.CopyAction);
                }
                onDropped: drop => card.acceptDrop(drop)
            }
        }
    }
}
