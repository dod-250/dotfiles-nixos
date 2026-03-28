import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    visible: root.pickerVisible
    anchors.top: true; anchors.left: true; anchors.right: true; anchors.bottom: true
    exclusiveZone: 0; exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    MouseArea { anchors.fill: parent; onClicked: root.pickerVisible = false }

    Rectangle {
        anchors.centerIn: parent
        width: 560
        height: Math.min(Math.ceil(root.wallpapers.length / 3) * 168 + 60, 600)
        radius: 10
        color: Colors.mantle
        border.color: Colors.peach; border.width: 2

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Wallpapers"
                    font.pixelSize: 14; font.weight: Font.Medium
                    color: Colors.text; Layout.fillWidth: true
                }
                Text {
                    text: "󰅖"; font.pixelSize: 14; font.family: Colors.nerdFont; color: Colors.overlay0
                    MouseArea {
                        anchors.fill: parent; onClicked: root.pickerVisible = false
                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onEntered: parent.color = Colors.peach; onExited: parent.color = Colors.overlay0
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                contentWidth: width; contentHeight: Math.ceil(root.wallpapers.length / 3) * 168

                GridView {
                    anchors.fill: parent; cellWidth: 168; cellHeight: 168
                    model: root.wallpapers

                    delegate: Item {
                        width: 160; height: 160

                        Rectangle {
                            anchors.fill: parent; anchors.margins: 4
                            radius: 6; color: Colors.surface0; clip: true

                            Image {
                                anchors.fill: parent
                                source: "file://" + modelData
                                fillMode: Image.PreserveAspectCrop
                                smooth: true; asynchronous: true
                            }

                            Rectangle {
                                id: overlay
                                anchors.fill: parent; radius: 6
                                color: "#000000"; opacity: 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered: overlay.opacity = 0.3
                                onExited: overlay.opacity = 0
                                onClicked: {
                                    const wp = modelData
                                    root.preloadProc.command = ["hyprctl", "hyprpaper", "preload", wp]
                                    root.applyProc.command = ["hyprctl", "hyprpaper", "wallpaper",
                                        Hyprland.monitors.values[0].name + "," + wp]
                                    root.preloadProc.running = true
                                    root.pickerVisible = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
