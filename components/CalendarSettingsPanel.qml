pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import "../config"
import "../services"

Column {
    id: root
    property bool active: false
    signal backRequested
    spacing: Design.space16
    onActiveChanged: { if (!active) feedUrl.clear(); }
    onVisibleChanged: { if (!visible) feedUrl.clear(); }

    Row {
        width: parent.width
        spacing: Design.space12
        UI.IconButton {
            text: "‹"
            Accessible.name: "Back to bar layout"
            onClicked: { feedUrl.clear(); root.backRequested(); }
        }
        UI.Text { text: "Clock and calendar"; role: "panel" }
    }
    Row {
        width: parent.width
        spacing: Design.space12
        UI.Text {
            width: parent.width - calendarSwitch.width - parent.spacing
            height: calendarSwitch.height
            verticalAlignment: Text.AlignVCenter
            text: "Show iCalendar events"
        }
        UI.Switch {
            id: calendarSwitch
            Accessible.name: "Show iCalendar events"
            checked: CalendarFeed.enabled
            enabled: CalendarFeed.ready && !CalendarFeed.busy
            onToggled: CalendarFeed.enabled = checked
        }
    }
    Column {
        width: parent.width
        spacing: Design.space8
        UI.Text {
            width: parent.width
            text: "Private iCalendar address"
            role: "label"
        }
        UI.TextField {
            id: feedUrl
            objectName: "calendar-feed-url"
            width: parent.width
            placeholderText: "Paste HTTPS iCal URL"
            echoMode: TextInput.Password
            passwordMaskDelay: 0
            maximumLength: 8192
            inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            enabled: !CalendarFeed.busy
            Accessible.name: "Private iCalendar address"
            onAccepted: saveFeed.clicked()
        }
        Row {
            width: parent.width
            spacing: Design.space8
            UI.Button {
                id: saveFeed
                objectName: "calendar-feed-save"
                width: (parent.width - parent.spacing) / 2
                text: "Save feed"
                enabled: CalendarFeed.ready && !CalendarFeed.busy && feedUrl.length > 0
                onClicked: {
                    if (feedUrl.length && CalendarFeed.save(feedUrl.text)) feedUrl.clear();
                }
            }
            UI.Button {
                objectName: "calendar-feed-remove"
                width: (parent.width - parent.spacing) / 2
                text: "Remove feed"
                enabled: CalendarFeed.ready && !CalendarFeed.busy
                onClicked: { feedUrl.clear(); CalendarFeed.forget(); }
            }
        }
        UI.Text {
            width: parent.width
            text: "Use Google Calendar’s “Secret address in iCal format”. The address is saved in GNOME Keyring and is never shown again. Clear your clipboard after pasting."
            wrapMode: Text.WordWrap
            role: "caption"
            color: Design.textSecondary
        }
    }
    UI.Text {
        width: parent.width
        visible: CalendarFeed.busy || CalendarFeed.message.length > 0
        text: CalendarFeed.busy ? "Waiting for keyring… Unlock it if prompted." : CalendarFeed.message
        wrapMode: Text.WordWrap
        role: "caption"
        color: CalendarFeed.failed ? Design.warning : Design.textSecondary
    }
}
