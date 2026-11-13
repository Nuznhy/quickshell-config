pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components.shared
import qs.components.ui as UI
import qs.config
import qs.services.wallpaper

UI.ColumnLayout {
    id: root
    required property string activeMonitor
    required property string wallpaperMode
    // Physical pixel size of the target monitor, for the resolution filter.
    property size monitorSize: Qt.size(0, 0)
    readonly property string atleast: monitorSize.width > 0 && monitorSize.height > 0 ? Math.round(monitorSize.width) + "x" + Math.round(monitorSize.height) : ""
    readonly property bool inCollection: Wallhaven.collection > 0
    readonly property var sortLabels: ({
            toplist: "Top",
            date_added: "Latest",
            relevance: "Relevance",
            random: "Random",
            views: "Views",
            favorites: "Favorites"
        })
    readonly property var rangeLabels: ({
            "1d": "Day",
            "3d": "3 days",
            "1w": "Week",
            "1M": "Month",
            "3M": "3 months",
            "6M": "6 months",
            "1y": "Year"
        })
    readonly property var sourceModel: [
        {
            id: 0,
            label: "Search"
        }
    ].concat(Wallhaven.collections.map(entry => ({
                id: entry.id,
                label: entry.label + " · " + entry.count
            })))
    property bool accountOpen: false
    signal chosen(string monitorName, string fileUrl)
    spacing: Design.space8

    function refresh(page) {
        Wallhaven.search(page || 1, root.atleast);
    }
    function toggleBit(value, index) {
        return value.slice(0, index) + (value[index] === "1" ? "0" : "1") + value.slice(index + 1);
    }
    function setFilter(name, value) {
        if (Wallhaven.setOption(name, value))
            refresh(1);
    }
    function isCurrent(id) {
        return Theme.wallpaperFor(activeMonitor, wallpaperMode).indexOf("/wallhaven-" + id + ".") >= 0;
    }

    Component.onCompleted: {
        if (!Wallhaven.searched)
            refresh(1);
    }
    onAtleastChanged: {
        if (Wallhaven.matchResolution && Wallhaven.searched)
            refresh(1);
    }
    Connections {
        target: Wallhaven
        function onDownloaded(id, fileUrl, context) {
            // Drop a download whose mode was switched away while it ran.
            if (context.mode === root.wallpaperMode)
                root.chosen(context.monitor, fileUrl);
        }
    }

    UI.RowLayout {
        Layout.fillWidth: true
        spacing: Design.space8
        UI.TextField {
            id: queryField
            objectName: "wallhaven-query"
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            visible: !root.inCollection
            text: Wallhaven.query
            placeholderText: "Search Wallhaven"
            Accessible.name: "Search Wallhaven"
            onAccepted: root.setFilter("query", text)
        }
        NotificationButton {
            objectName: "wallhaven-search"
            visible: !root.inCollection
            text: "Search"
            accent: true
            onClicked: root.setFilter("query", queryField.text)
        }
        UI.ComboBox {
            objectName: "wallhaven-source"
            visible: Wallhaven.collections.length > 0
            Layout.fillWidth: root.inCollection
            Layout.preferredWidth: Math.min(220, root.width * 0.35)
            model: root.sourceModel
            textRole: "label"
            currentIndex: Math.max(0, root.sourceModel.findIndex(entry => entry.id === Wallhaven.collection))
            onActivated: index => root.setFilter("collection", root.sourceModel[index].id)
            Accessible.name: "Wallhaven source"
        }
        UI.IconButton {
            text: "󰀄"
            highlighted: root.accountOpen
            Accessible.name: "Wallhaven account"
            onClicked: root.accountOpen = !root.accountOpen
        }
    }

    UI.ColumnLayout {
        objectName: "wallhaven-account"
        visible: root.accountOpen
        Layout.fillWidth: true
        spacing: Design.space8
        UI.RowLayout {
            Layout.fillWidth: true
            spacing: Design.space8
            UI.TextField {
                id: keyField
                objectName: "wallhaven-api-key"
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: Wallhaven.apiKey
                echoMode: TextInput.Password
                placeholderText: "API key"
                Accessible.name: "Wallhaven API key"
            }
            UI.TextField {
                id: userField
                objectName: "wallhaven-username"
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: Wallhaven.username
                placeholderText: "Username"
                Accessible.name: "Wallhaven username"
            }
            NotificationButton {
                text: "Save"
                onClicked: {
                    Wallhaven.setAccount(keyField.text, userField.text);
                    root.refresh(1);
                }
            }
        }
        UI.Text {
            Layout.fillWidth: true
            text: Wallhaven.collectionsError || "The API key from wallhaven.cc account settings unlocks NSFW results and your collections. It is saved in the shell state folder."
            color: Wallhaven.collectionsError ? Design.danger : Design.textSecondary
            font.family: Design.fontFamily
            role: "caption"
            wrapMode: Text.WordWrap
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: Design.space8
        Repeater {
            model: root.inCollection ? [] : ["General", "Anime", "People"]
            delegate: NotificationButton {
                required property string modelData
                required property int index
                objectName: "wallhaven-category-" + modelData.toLowerCase()
                text: modelData
                accent: Wallhaven.categories[index] === "1"
                onClicked: root.setFilter("categories", root.toggleBit(Wallhaven.categories, index))
            }
        }
        Repeater {
            model: ["SFW", "Sketchy", "NSFW"]
            delegate: NotificationButton {
                required property string modelData
                required property int index
                objectName: "wallhaven-purity-" + modelData.toLowerCase()
                text: modelData
                accent: Wallhaven.purity[index] === "1"
                enabled: index < 2 || Wallhaven.hasKey
                onClicked: root.setFilter("purity", root.toggleBit(Wallhaven.purity, index))
            }
        }
        UI.ComboBox {
            objectName: "wallhaven-sorting"
            visible: !root.inCollection
            width: 150
            model: Wallhaven.sortings.map(value => root.sortLabels[value])
            currentIndex: Wallhaven.sortings.indexOf(Wallhaven.sorting)
            onActivated: index => root.setFilter("sorting", Wallhaven.sortings[index])
            Accessible.name: "Wallhaven sorting"
        }
        UI.ComboBox {
            objectName: "wallhaven-range"
            visible: !root.inCollection && Wallhaven.sorting === "toplist"
            width: 130
            model: Wallhaven.topRanges.map(value => root.rangeLabels[value])
            currentIndex: Wallhaven.topRanges.indexOf(Wallhaven.topRange)
            onActivated: index => root.setFilter("topRange", Wallhaven.topRanges[index])
            Accessible.name: "Wallhaven top range"
        }
        UI.CheckBox {
            objectName: "wallhaven-match-resolution"
            visible: !root.inCollection && root.atleast.length > 0
            text: "At least " + root.atleast
            checked: Wallhaven.matchResolution
            onToggled: root.setFilter("matchResolution", checked)
        }
    }

    UI.Text {
        Layout.fillWidth: true
        visible: text.length > 0
        text: Wallhaven.errorMessage || Wallhaven.downloadError || (Wallhaven.loading && !Wallhaven.items.length ? "Searching Wallhaven…" : Wallhaven.searched && !Wallhaven.items.length ? "No wallpapers match these filters." : "")
        color: Wallhaven.errorMessage || Wallhaven.downloadError ? Design.danger : Design.textSecondary
        font.family: Design.fontFamily
        role: "body"
        wrapMode: Text.WordWrap
    }

    GridView {
        id: results
        objectName: "wallhaven-gallery"
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(420, Math.ceil(count / columns) * cellHeight)
        readonly property int columns: Math.max(1, Math.floor(width / 170))
        cellWidth: width / columns
        cellHeight: cellWidth * 9 / 16 + 38
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        visible: count > 0
        opacity: Wallhaven.loading ? 0.6 : 1
        model: Wallhaven.items
        ScrollBar.vertical: UI.ScrollBar {}
        delegate: UI.Button {
            id: tile
            required property var modelData
            readonly property bool fetching: Wallhaven.downloadingId === modelData.id
            objectName: "wallhaven-image-" + modelData.id
            width: results.cellWidth - 10
            height: results.cellHeight - 10
            padding: Design.space4
            topInset: 0
            bottomInset: 0
            highlighted: root.isCurrent(modelData.id)
            enabled: Theme.ready && root.activeMonitor !== ""
            Accessible.name: "Download and set Wallhaven " + modelData.id + " on " + root.activeMonitor + " for " + root.wallpaperMode
            onClicked: Wallhaven.download(modelData, {
                monitor: root.activeMonitor,
                mode: root.wallpaperMode
            })

            contentItem: Column {
                spacing: Design.space4
                Image {
                    id: thumbnail
                    width: parent.width
                    height: tile.height - 34
                    source: tile.modelData.thumb
                    sourceSize: Qt.size(400, 225)
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    Rectangle {
                        anchors.fill: parent
                        visible: tile.fetching
                        color: Design.background
                        opacity: 0.7
                    }
                    UI.Text {
                        anchors.centerIn: parent
                        visible: tile.fetching || thumbnail.status !== Image.Ready
                        text: tile.fetching ? "Downloading…" : thumbnail.status === Image.Error ? "Unavailable" : "Loading…"
                        color: tile.fetching ? Design.text : Design.textSecondary
                        font.family: Design.fontFamily
                        role: "caption"
                    }
                }
                UI.Text {
                    width: parent.width
                    text: tile.modelData.resolution + (tile.modelData.purity !== "sfw" ? " · " + tile.modelData.purity : "")
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: Design.text
                    font.family: Design.fontFamily
                    role: "caption"
                }
            }
        }
    }

    UI.RowLayout {
        Layout.fillWidth: true
        visible: Wallhaven.items.length > 0
        spacing: Design.space8
        NotificationButton {
            objectName: "wallhaven-previous"
            text: "‹ Previous"
            enabled: Wallhaven.page > 1 && !Wallhaven.loading
            onClicked: root.refresh(Wallhaven.page - 1)
        }
        UI.Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "Page " + Wallhaven.page + " / " + Wallhaven.lastPage + " · " + Wallhaven.total + " wallpapers"
            color: Design.textSecondary
            font.family: Design.fontFamily
            role: "label"
        }
        NotificationButton {
            objectName: "wallhaven-next"
            text: "Next ›"
            enabled: Wallhaven.page < Wallhaven.lastPage && !Wallhaven.loading
            onClicked: root.refresh(Wallhaven.page + 1)
        }
    }
}
