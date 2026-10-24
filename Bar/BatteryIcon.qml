import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs

Rectangle { //Battery box
    id: batteryBox
    visible: UPower.displayDevice.isLaptopBattery
    property real uiScale: 1
    width: 100 * uiScale
    height: 36 * uiScale
    color: "transparent"
    border.color: Colors.primary
    border.width: 2 * uiScale
    radius: 8 * uiScale
    clip: true
    Layout.alignment: Qt.AlignVCenter

    property var device: UPower.devices.values[0]
    property real pct: (device?.percentage ?? 0) * 100 * 1.25
    property bool charging: device?.state === UPowerDeviceState.Charging

    property int barCount: {
      if (pct >= 80) return 5
      else if (pct >= 60) return 4
      else if (pct >= 40) return 3
      else if (pct >= 20) return 2
      else return 1
    }

    property color barColor: {
      var bat_round = Math.ceil(pct / 10) * 10 
      bat_round = Math.max(0, Math.min(80, bat_round))
      return Colors["primary" + bat_round]
    }

    RowLayout {
      anchors.fill: parent
      anchors.margins: batteryBox.border.width
      anchors.leftMargin: 5 * batteryBox.uiScale
      anchors.rightMargin: 5 * batteryBox.uiScale
      spacing: 2 * batteryBox.uiScale

      Repeater {
        model: 5
        Rectangle {
          Layout.bottomMargin: 3 * batteryBox.uiScale
          Layout.topMargin: 3 * batteryBox.uiScale
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 3
          color: index < batteryBox.barCount ? batteryBox.barColor : "transparent"
        }
      }
    }

    Text {
      anchors.centerIn: parent
      color: Colors.primary90
      font.pixelSize: 24 * batteryBox.uiScale
      font.bold: true
      style: Text.Outline
      styleColor: "black"
      text: (batteryBox.charging ? "\udb85\udc0b " : "") + Math.round(batteryBox.pct) + "%"
    }
}
