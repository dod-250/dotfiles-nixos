import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: calendarWindow

    visible: root.calendarVisible
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    property int calMonth: new Date().getMonth()
    property int calYear: new Date().getFullYear()
    property int selectedDay: new Date().getDate()
    property string events: "Aucun événement"

    Process {
        id: calcurseProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()
                if (line === "" || line.match(/^\d{2}\/\d{2}\/\d{4}:$/)) return
                if (calendarWindow.events === "Aucun événement")
                    calendarWindow.events = line
                else
                    calendarWindow.events += "\n" + line
            }
        }
    }

    function loadEvents(day) {
        selectedDay = day
        events = "Aucun événement"
        const d = new Date(calYear, calMonth, day)
        const mm = String(d.getMonth() + 1).padStart(2, "0")
        const dd = String(d.getDate()).padStart(2, "0")
        const yyyy = String(d.getFullYear())
        const dateStr = mm + "/" + dd + "/" + yyyy
        calcurseProc.command = [
            "bash", "-c",
            "/home/dod/.nix-profile/bin/calcurse -D /home/dod/.local/share/calcurse -Q --from " + dateStr + " --to " + dateStr + " --format-apt \"%S -> %E %m\" --format-ev \"%m\""
        ]
        calcurseProc.running = true
    }

    onVisibleChanged: { if (visible) loadEvents(selectedDay) }

    MouseArea {
        anchors.fill: parent
        onClicked: root.calendarVisible = false
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 56
        width: 300; height: 380
        radius: 10
        color: Colors.mantle
        border.color: Colors.peach; border.width: 2

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            // Navigation mois
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰁍"; font.pixelSize: 14; font.family: Colors.nerdFont; color: Colors.overlay0
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            calendarWindow.calMonth--
                            if (calendarWindow.calMonth < 0) { calendarWindow.calMonth = 11; calendarWindow.calYear-- }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(new Date(calendarWindow.calYear, calendarWindow.calMonth, 1), "MMMM yyyy")
                    font.pixelSize: 13; font.weight: Font.Medium; color: Colors.text
                }

                Text {
                    text: "󰁔"; font.pixelSize: 14; font.family: Colors.nerdFont; color: Colors.overlay0
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            calendarWindow.calMonth++
                            if (calendarWindow.calMonth > 11) { calendarWindow.calMonth = 0; calendarWindow.calYear++ }
                        }
                    }
                }
            }

            // Grille jours
            GridLayout {
                Layout.fillWidth: true
                columns: 7; columnSpacing: 0; rowSpacing: 0

                Repeater {
                    model: ["L", "M", "M", "J", "V", "S", "D"]
                    delegate: Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData; font.pixelSize: 11; color: Colors.overlay0
                    }
                }

                Repeater {
                    model: 42
                    delegate: Item {
                        Layout.fillWidth: true
                        height: 28

                        property int firstDay: (new Date(calendarWindow.calYear, calendarWindow.calMonth, 1).getDay() + 6) % 7
                        property int dayNum: index - firstDay + 1
                        property int daysInMonth: new Date(calendarWindow.calYear, calendarWindow.calMonth + 1, 0).getDate()
                        property bool isCurrentMonth: dayNum >= 1 && dayNum <= daysInMonth
                        property bool isToday: {
                            const now = new Date()
                            return dayNum === now.getDate() && calendarWindow.calMonth === now.getMonth() && calendarWindow.calYear === now.getFullYear()
                        }
                        property bool isSelected: dayNum === calendarWindow.selectedDay && isCurrentMonth
                        property bool isWeekend: { const d = (firstDay + index) % 7; return d === 6 || d === 0 }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 24; height: 24; radius: 12
                            color: isToday ? Colors.peach : isSelected ? Colors.surface0 : "transparent"
                            visible: isCurrentMonth
                            border.color: isSelected && !isToday ? Colors.peach : "transparent"
                            border.width: 1
                        }

                        Text {
                            anchors.centerIn: parent
                            text: isCurrentMonth ? dayNum : ""
                            font.pixelSize: 11
                            font.weight: isToday || isSelected ? Font.Medium : Font.Normal
                            color: isToday ? Colors.mantle : isWeekend ? Colors.blue : Colors.text
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: isCurrentMonth
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendarWindow.loadEvents(dayNum)
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.surface0 }

            Text {
                text: Qt.formatDate(new Date(calendarWindow.calYear, calendarWindow.calMonth, calendarWindow.selectedDay), "dddd d MMMM")
                font.pixelSize: 11; font.weight: Font.Medium; color: Colors.peach
            }

            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; contentWidth: width; contentHeight: eventsText.implicitHeight
                Text {
                    id: eventsText
                    width: parent.width
                    text: calendarWindow.events
                    font.pixelSize: 11
                    color: calendarWindow.events === "Aucun événement" ? Colors.overlay0 : Colors.text
                    wrapMode: Text.Wrap; lineHeight: 1.5
                }
            }
        }
    }
}
