import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

PanelWindow {
    id: popupWindow

    visible: false
    anchors.top: true
    anchors.right: true
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 360
    implicitHeight: popupContent.implicitHeight + 16 + 56
    color: "transparent"

    property var currentNotif: null
    property string notifAppName: ""
    property string notifSummary: ""
    property string notifBody: ""

    function show(notif) {
        notifAppName = notif.appName ?? ""
        notifSummary = notif.summary ?? ""
        notifBody = notif.body ?? ""
        currentNotif = notif
        visible = true
        popupTimer.restart()
    }

    Timer {
        id: popupTimer
        interval: 7000
        repeat: false
        onTriggered: popupWindow.visible = false
    }

    Rectangle {
        id: popupContent
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 56
            rightMargin: 8
        }
        width: 350
        radius: 10
        color: Colors.mantle
        border.color: {
            const u = popupWindow.currentNotif?.urgency
            if (u === NotificationUrgency.Critical) return Colors.red
            if (u === NotificationUrgency.Normal)   return Colors.peach
            return Colors.surface0
        }
        border.width: 2
        implicitHeight: popupInner.implicitHeight + 20

        MouseArea {
            anchors.fill: parent
            onClicked: popupWindow.visible = false
        }

        ColumnLayout {
            id: popupInner
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: popupWindow.notifAppName
                    font.pixelSize: 10; font.weight: Font.Medium
                    color: Colors.peach
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "󰅖"
                    font.pixelSize: 11; font.family: Colors.nerdFont; color: Colors.overlay0
                    MouseArea {
                        anchors.fill: parent
                        onClicked: popupWindow.visible = false
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: popupWindow.notifSummary
                font.pixelSize: 12; font.weight: Font.Medium
                color: Colors.text; wrapMode: Text.Wrap
                visible: text !== ""
            }

            Text {
                Layout.fillWidth: true
                text: popupWindow.notifBody
                font.pixelSize: 11; color: Colors.subtext0
                wrapMode: Text.Wrap; visible: text !== ""
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: (popupWindow.currentNotif?.actions?.length ?? 0) > 0

                Repeater {
                    model: popupWindow.currentNotif?.actions ?? []
                    delegate: Rectangle {
                        required property var modelData
                        height: 24
                        implicitWidth: actionText.implicitWidth + 16
                        radius: 4
                        color: Colors.surface0
                        border.color: Colors.surface1; border.width: 1

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: modelData.text
                            font.pixelSize: 10; color: Colors.text
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { modelData.invoke(); popupWindow.visible = false }
                        }
                    }
                }
            }
        }
    }
}
