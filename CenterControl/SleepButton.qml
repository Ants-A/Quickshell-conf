import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQml.Models
import qs

Rectangle {
  id: root
  readonly property real uiScale: UiScale.factor(screen.width)

  // nf-md-weather_night (moon), built from a code point so it can't get mangled by copy/paste.
  readonly property string icon: String.fromCodePoint(0xF0594) // 󰖔

  Layout.fillWidth: true
  Layout.leftMargin: 10 * uiScale
  Layout.rightMargin: 10 * uiScale

  color: mouseArea.containsMouse ? "#30ffffff" : "#50000000"
  Behavior on color { ColorAnimation { duration: 250 } }
  implicitHeight: 96 * uiScale
  radius: 12 * uiScale
  border.width: 2 * uiScale
  border.color: Colors.primary_container

  Text {
    anchors.centerIn: parent
    text: root.icon
    color: Colors.primary
    font.family: "JetBrainsMono Nerd Font"   // use whatever Nerd Font you have installed
    font.pixelSize: 52 * uiScale
  }

  MouseArea {
    id: mouseArea
    objectName: "cardMouseArea"
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached(["systemctl", "suspend"])
  }
}
