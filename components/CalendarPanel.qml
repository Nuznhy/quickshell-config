pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Shapes
import "../config"
import "../services"

FocusScope {
    id: root
    property date today: new Date()
    property bool active: false
    property date selectedDate: today
    property date displayedMonth: new Date(today.getFullYear(), today.getMonth(), 1)
    readonly property int firstWeekday: Qt.locale().firstDayOfWeek % 7
    readonly property int leadingDays: (displayedMonth.getDay() - firstWeekday + 7) % 7
    implicitHeight: Math.max(content.implicitHeight, 350)
    signal dismissed
    property date agendaDate: selectedDate
    readonly property var dayEvents: agenda.eventsOn(selectedDate)
    property string renderedAgenda: ""
    ListModel { id: eventModel }

    function agendaRows() {
        return dayEvents.map(event => ({title: event.title, calendar: event.calendar,
            timeLabel: event.allDay ? "All day" :
                Qt.formatDateTime(new Date(event.start), "hh:mm") + " – " +
                Qt.formatDateTime(new Date(event.end), sameDay(new Date(event.start), new Date(event.end)) ? "hh:mm" : "ddd hh:mm")}));
    }
    function commitAgenda() {
        const rows = agendaRows();
        // Keep one model and update existing rows instead of resetting the view.
        for (let i = 0; i < rows.length; ++i) {
            if (i < eventModel.count) eventModel.set(i, rows[i]);
            else eventModel.append(rows[i]);
        }
        if (eventModel.count > rows.length) eventModel.remove(rows.length, eventModel.count - rows.length);
        if (!sameDay(agendaDate, selectedDate)) eventList.positionViewAtBeginning();
        agendaDate = selectedDate;
        renderedAgenda = Qt.formatDate(selectedDate, "yyyy-MM-dd") + JSON.stringify(rows);
    }
    function updateAgenda() {
        if (!active || !CalendarFeed.enabled || CalendarFeed.busy) {
            dayTransition.stop();
            eventModel.clear();
            renderedAgenda = "";
            agendaBody.opacity = 1;
            return;
        }
        const next = Qt.formatDate(selectedDate, "yyyy-MM-dd") + JSON.stringify(agendaRows());
        if (next === renderedAgenda) return;
        dayTransition.restart();
    }
    onDayEventsChanged: Qt.callLater(updateAgenda)
    onSelectedDateChanged: Qt.callLater(updateAgenda)
    SequentialAnimation {
        id: dayTransition
        NumberAnimation { target: agendaBody; property: "opacity"; to: 0; duration: 65; easing.type: Easing.OutQuad }
        ScriptAction { script: root.commitAgenda() }
        NumberAnimation { target: agendaBody; property: "opacity"; to: 1; duration: 115; easing.type: Easing.OutQuad }
    }

    CalendarEvents {
        id: agenda
        objectName: "calendar-events"
        active: root.active && CalendarFeed.enabled && !CalendarFeed.busy
        firstDate: root.dateAt(0)
        endDate: root.dateAt(42)
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function reset() {
        selectedDate = today;
        displayedMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    }

    function changeMonth(offset) {
        displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + offset, 1);
    }

    function dateAt(index) {
        return new Date(displayedMonth.getFullYear(), displayedMonth.getMonth(), index - leadingDays + 1);
    }

    onActiveChanged: {
        if (active) {
            reset();
            forceActiveFocus();
        }
        updateAgenda();
    }
    Keys.onEscapePressed: dismissed()
    Keys.onLeftPressed: changeMonth(-1)
    Keys.onRightPressed: changeMonth(1)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home) {
            reset();
            event.accepted = true;
        }
    }

    component CalendarButton: UI.Button {
        id: control
        font.family: Design.fontFamily
        font.pixelSize: Design.bodySize

    }

    component MonthButton: CalendarButton {
        id: navigation
        required property int direction
        width: 30
        height: 32
        padding: 0
        topInset: 0
        bottomInset: 0
        leftInset: 0
        rightInset: 0
        Accessible.name: direction < 0 ? "Previous month" : "Next month"
        onClicked: root.changeMonth(direction)
        contentItem: Item {
            Shape {
                anchors.centerIn: parent
                width: 12
                height: 12
                rotation: navigation.direction < 0 ? 0 : 180
                ShapePath {
                    strokeColor: Design.text
                    strokeWidth: 1.5
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    startX: 8; startY: 2
                    PathLine { x: 4; y: 6 }
                    PathLine { x: 8; y: 10 }
                }
            }
        }
    }

    Column {
        id: content
        x: 0
        y: 0
        width: CalendarFeed.enabled ? Math.floor((root.width - Design.space32 - 1) * 0.49) : root.width
        spacing: Design.space12

        Item {
            width: parent.width
            height: 32
            UI.Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(root.displayedMonth, "MMMM yyyy")
                color: Design.text
                font.family: Design.fontFamily
                role: "section"
                font.bold: true
            }
            Row {
                anchors.right: parent.right
                spacing: Design.space4
                MonthButton { direction: -1 }
                MonthButton { direction: 1 }
            }
        }

        Column {
            width: parent.width
            spacing: Design.space4
            Row {
                width: parent.width
                Repeater {
                    model: 7
                    UI.Text {
                        required property int index
                        width: content.width / 7
                        height: 22
                        text: Qt.locale().standaloneDayName((root.firstWeekday + index) % 7, Locale.ShortFormat)
                        horizontalAlignment: Text.AlignHCenter
                        color: Design.textSecondary
                        font.family: Design.fontFamily
                        role: "caption"
                    }
                }
            }
            Grid {
                columns: 7
                Repeater {
                    model: 42
                    UI.Button {
                        highlighted: isToday || selected
                        variant: "ghost"
                        id: dayCell
                        required property int index
                        readonly property date cellDate: root.dateAt(index)
                        readonly property bool isToday: root.sameDay(cellDate, root.today)
                        readonly property bool selected: root.sameDay(cellDate, root.selectedDate)
                        readonly property bool inMonth: cellDate.getMonth() === root.displayedMonth.getMonth()
                        width: content.width / 7
                        height: 38
                        Accessible.name: Qt.formatDate(cellDate, "dddd, d MMMM yyyy")
                        Accessible.description: isToday ? "Today" : ""
                        onClicked: {
                            root.selectedDate = cellDate;
                            if (!inMonth)
                                root.displayedMonth = new Date(cellDate.getFullYear(), cellDate.getMonth(), 1);
                        }

                        contentItem: UI.Text {
                            text: dayCell.cellDate.getDate()
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: dayCell.highlighted ? Design.textOnAccent : dayCell.inMonth ? Design.text : Design.textMuted
                            font.family: Design.fontFamily
                            role: "body"
                            font.bold: dayCell.isToday || dayCell.selected
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                            width: 4; height: 4; radius: 2
                            color: dayCell.highlighted ? Design.textOnAccent : Design.accent
                            visible: CalendarFeed.enabled && agenda.eventsOn(dayCell.cellDate).length > 0
                        }
                    }
                }
            }
        }

        UI.Divider { width: parent.width; height: implicitHeight }

        Item {
            width: parent.width
            height: 30
            UI.Text {
                anchors.left: parent.left
                anchors.right: todayButton.left
                anchors.rightMargin: Design.space8
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(root.selectedDate, "ddd, d MMM yyyy")
                elide: Text.ElideRight
                color: Design.textSecondary
                font.family: Design.fontFamily
                role: "label"
            }
            CalendarButton {
                id: todayButton
                anchors.right: parent.right
                width: 64; height: 30
                text: "Today"
                onClicked: root.reset()
            }
        }

    }
    Rectangle {
        visible: CalendarFeed.enabled
        x: content.width + Design.space16
        width: 1
        height: parent.height
        color: Design.border
    }
    Item {
        id: agendaPane
        objectName: "calendar-agenda-pane"
        visible: CalendarFeed.enabled
        x: content.width + Design.space32 + 1
        width: root.width - x
        height: root.height
        Row {
            id: agendaHeader
            width: parent.width
            spacing: Design.space8
            Column {
                width: parent.width - refreshButton.width - parent.spacing
                spacing: Design.space4
                UI.Text { text: "Events"; role: "section"; font.bold: true }
                UI.Text {
                    width: parent.width
                    text: Qt.formatDate(root.agendaDate, "dddd, d MMMM")
                    elide: Text.ElideRight
                    role: "label"
                    color: Design.textSecondary
                }
            }
            CalendarButton {
                id: refreshButton
                text: "Refresh"
                width: 72
                enabled: !CalendarFeed.busy && !agenda.loading
                onClicked: agenda.refresh()
            }
        }
        UI.Text {
            id: agendaStatus
            anchors.top: agendaHeader.bottom
            anchors.topMargin: Design.space8
            width: parent.width
            height: 38
            text: agenda.loading ? "Updating calendar…" : agenda.errorMessage
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            role: "caption"
            color: agenda.errorMessage ? Design.warning : Design.textSecondary
            HoverHandler { id: statusHover }
            ToolTip.visible: statusHover.hovered && agenda.errorMessage.length > 0
            ToolTip.text: agenda.errorMessage
        }
        Item {
            id: agendaBody
            anchors.top: agendaStatus.bottom
            anchors.topMargin: Design.space8
            anchors.bottom: parent.bottom
            width: parent.width
            clip: true
            UI.Text {
                anchors.centerIn: parent
                width: parent.width - Design.space24
                horizontalAlignment: Text.AlignHCenter
                text: "No events on this day"
                color: Design.textMuted
                visible: eventModel.count === 0 && !agenda.loading && !agenda.errorMessage
            }
            ListView {
                id: eventList
                objectName: "calendar-event-list"
                anchors.fill: parent
                clip: true
                spacing: Design.space8
                model: eventModel
                reuseItems: true
                boundsBehavior: Flickable.StopAtBounds
                UI.ScrollBar.vertical: UI.ScrollBar {}
                delegate: UI.Card {
                    id: eventCard
                    required property string title
                    required property string calendar
                    required property string timeLabel
                    width: eventList.width - Design.space12
                    height: eventContent.implicitHeight + Design.space24
                    Rectangle {
                        x: 0; y: Design.space12
                        width: 3
                        height: parent.height - Design.space24
                        radius: 1.5
                        color: Design.accent
                    }
                    Column {
                        id: eventContent
                        x: Design.space12
                        y: Design.space12
                        width: parent.width - Design.space24
                        spacing: Design.space4
                        UI.Text {
                            text: eventCard.timeLabel
                            role: "caption"
                            color: Design.accent
                        }
                        UI.Text {
                            width: parent.width
                            text: eventCard.title
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            font.bold: true
                        }
                        UI.Text {
                            width: parent.width
                            text: eventCard.calendar
                            elide: Text.ElideRight
                            role: "caption"
                            color: Design.textSecondary
                        }
                    }
                }
            }
        }
    }
}
