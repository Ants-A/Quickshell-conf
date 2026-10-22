import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
  id: root
  readonly property real uiScale: UiScale.factor(screen.width)

  // Bluetooth state
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool btEnabled: adapter ? adapter.enabled : false
  readonly property var connectedDevices: Bluetooth.devices.values.filter(d => d.connected)
  readonly property int connectedCount: connectedDevices.length

  Layout.fillWidth: true
  Layout.leftMargin: 10 * uiScale
  Layout.rightMargin: 10 * uiScale

  color: "#50000000"
  implicitHeight: 96 * uiScale
  radius: 16 * uiScale
  border.width: 2 * uiScale
  border.color: Colors.primary_container

  RowLayout {
    anchors {
      left: parent.left
      leftMargin: 32 * uiScale
      verticalCenter: parent.verticalCenter
    }
    spacing: 24 * uiScale


    // Bluetooth icon (nf-fa-bluetooth_b)
    Text {
      Layout.alignment: Qt.AlignHCenter
      text: "\uF294"
      font.family: "JetBrainsMono Nerd Font"   // use your installed Nerd Font
      font.pixelSize: 52 * root.uiScale
      color: root.btEnabled ? Colors.primary : Colors.outline
    }

    // Status text
    Text {
      Layout.alignment: Qt.AlignHCenter
      text: !root.btEnabled
            ? "Bluetooth off"
            : root.connectedCount === 1
              ? root.connectedDevices[0].name
              : root.connectedCount + " devices connected"
      color: Colors.primary
      font.pixelSize: 28 * root.uiScale
    }
  }

  MouseArea {
    objectName: "cardMouseArea"
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached(["blueman-manager"])
  }
}
