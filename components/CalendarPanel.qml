pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import "../config"

FocusScope {
    id: root
    property date today: new Date()
    property bool active: false
    property date selectedDate: today
    property date displayedMonth: new Date(today.getFullYear(), today.getMonth(), 1)
    readonly property int firstWeekday: Qt.locale().firstDayOfWeek % 7
    readonly property int leadingDays: (displayedMonth.getDay() - firstWeekday + 7) % 7
    implicitHeight: content.implicitHeight
    signal dismissed

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

    component CalendarButton: Button {
        id: control
        hoverEnabled: true
        font.family: Theme.fontFamily
        font.pixelSize: 13
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        background: Rectangle {
            radius: 9
            color: control.hovered ? Theme.highlightMed : Theme.surface
            border.color: control.activeFocus ? Theme.iris : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        contentItem: Text {
            text: control.text
            font: control.font
            color: Theme.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
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
                    strokeColor: Theme.text
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
        width: parent.width
        spacing: 14

        Item {
            width: parent.width
            height: 32
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(root.displayedMonth, "MMMM yyyy")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.bold: true
            }
            Row {
                anchors.right: parent.right
                spacing: 6
                MonthButton { direction: -1 }
                MonthButton { direction: 1 }
            }
        }

        Column {
            width: parent.width
            spacing: 6
            Row {
                width: parent.width
                Repeater {
                    model: 7
                    Text {
                        required property int index
                        width: content.width / 7
                        height: 22
                        text: Qt.locale().standaloneDayName((root.firstWeekday + index) % 7, Locale.ShortFormat)
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }
            }
            Grid {
                columns: 7
                Repeater {
                    model: 42
                    Button {
                        id: dayCell
                        required property int index
                        readonly property date cellDate: root.dateAt(index)
                        readonly property bool isToday: root.sameDay(cellDate, root.today)
                        readonly property bool selected: root.sameDay(cellDate, root.selectedDate)
                        readonly property bool inMonth: cellDate.getMonth() === root.displayedMonth.getMonth()
                        width: content.width / 7
                        height: 38
                        hoverEnabled: true
                        Accessible.name: Qt.formatDate(cellDate, "dddd, d MMMM yyyy")
                        Accessible.description: isToday ? "Today" : ""
                        onClicked: {
                            root.selectedDate = cellDate;
                            if (!inMonth)
                                root.displayedMonth = new Date(cellDate.getFullYear(), cellDate.getMonth(), 1);
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        background: Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: 9
                            color: dayCell.isToday ? Theme.iris
                                : dayCell.hovered || dayCell.selected ? Theme.highlightMed : "transparent"
                            border.color: dayCell.activeFocus || (dayCell.selected && !dayCell.isToday)
                                ? Theme.iris : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        contentItem: Text {
                            text: dayCell.cellDate.getDate()
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: dayCell.isToday ? Theme.bg : dayCell.inMonth ? Theme.text : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: dayCell.isToday || dayCell.selected
                        }
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.highlightMed }

        Item {
            width: parent.width
            height: 30
            Text {
                anchors.left: parent.left
                anchors.right: todayButton.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(root.selectedDate, "ddd, d MMM yyyy")
                elide: Text.ElideRight
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 11
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
}
