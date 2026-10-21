import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQml.Models
import qs

Rectangle {
  id: root
  readonly property real uiScale: UiScale.factor(screen.width)

  Layout.fillWidth: true
  Layout.fillHeight: true
  Layout.leftMargin: 10 * uiScale
  Layout.rightMargin: 10 * uiScale

  width: parent.width
  color: Colors.background
  implicitHeight: 256 * uiScale
  radius: 16 * uiScale
  border.width: 2 * uiScale
  border.color: Colors.primary_container

  MouseArea {
    objectName: "cardMouseArea"
    anchors.fill: parent
    onClicked: Quickshell.execDetached(["notify-send", "Mousearea works"])
  }
}

