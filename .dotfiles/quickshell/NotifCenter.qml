import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
    id: notifCenter

    visible: root.notifCenterVisible
    anchors.top: true
    anchors.right: true
    anchors.bottom: true
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 380
    color: "transparent"

    MouseArea {
        anchors.fill: parent
        onClicked: root.notifCenterVisible = false
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
            topMargin: 56
            rightMargin: 8
            bottomMargin: 8
        }
        width: 360
        radius: 10
        color: Colors.mantle
        border.color: Colors.peach
        border.width: 2

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Notifications"
                    font.pixelSize: 14; font.weight: Font.Medium
                    color: Colors.text; Layout.fillWidth: true
                }

                Text {
                    text: "󰃢"
                    font.pixelSize: 13; font.family: Colors.nerdFont
                    color: notifModel.count > 0 ? Colors.overlay0 : Colors.surface1
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { notifModel.clear(); root.unreadCount = 0 }
                    }
                }
            }

            // Liste
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: notifColumn.implicitHeight

                Column {
                    id: notifColumn
                    width: parent.width
                    spacing: 6

                    Text {
                        width: parent.width
                        visible: notifModel.count === 0
                        text: "Aucune notification"
                        font.pixelSize: 12; color: Colors.overlay0
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 20
                    }

                    Repeater {
                        model: notifModel
                        delegate: Rectangle {
                            width: notifColumn.width
                            radius: 8
                            color: Colors.base
                            border.color: Colors.surface0; border.width: 1
                            implicitHeight: notifInner.implicitHeight + 20

                            ColumnLayout {
                                id: notifInner
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: model.appName
                                        font.pixelSize: 10; font.weight: Font.Medium
                                        color: Colors.peach; Layout.fillWidth: true
                                    }
                                    Text {
                                        text: "󰅖"
                                        font.pixelSize: 11; font.family: Colors.nerdFont; color: Colors.overlay0
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: notifModel.remove(index)
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: model.summary
                                    font.pixelSize: 12; font.weight: Font.Medium
                                    color: Colors.text; wrapMode: Text.Wrap
                                    visible: text !== ""
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: model.body
                                    font.pixelSize: 11; color: Colors.subtext0
                                    wrapMode: Text.Wrap; visible: text !== ""
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    visible: model.actions !== undefined && model.actions !== null && model.actions.length > 0

                                    Repeater {
                                        model: model.actions ?? []
                                        delegate: Rectangle {
                                            required property var modelData
                                            height: 24
                                            implicitWidth: actText.implicitWidth + 16
                                            radius: 4
                                            color: Colors.surface0
                                            border.color: Colors.surface1; border.width: 1
                                            Text {
                                                id: actText
                                                anchors.centerIn: parent
                                                text: modelData.text
                                                font.pixelSize: 10; color: Colors.text
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: modelData.invoke()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
