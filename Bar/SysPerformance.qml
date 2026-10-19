import QtQuick
import Quickshell.Io
import ".."

Row {
  id: root
  property real uiScale: 1

  property real cpuUsage: 0
  property real memUsage: 0
  property real memUsedGb: 0
  property real memTotalGb: 0
  property real lastIdle: 0
  property real lastTotal: 0

  spacing: 16 * uiScale

  FileView {
    id: statFile
    path: "/proc/stat"
    onLoaded: {
      const line = text().split("\n")[0]
      const p = line.trim().split(/\s+/).slice(1, 9).map(Number)
      const idle = p[3] + p[4]
      const total = p.reduce((a, b) => a + b, 0)
      const dTotal = total - root.lastTotal
      const dIdle = idle - root.lastIdle
      if (dTotal > 0)
        root.cpuUsage = (1 - dIdle / dTotal) * 100
      root.lastIdle = idle
      root.lastTotal = total
    }
  }

  FileView {
    id: memFile
    path: "/proc/meminfo"
    onLoaded: {
      const t = text()
      const total = parseInt(t.match(/MemTotal:\s+(\d+)/)[1])
      const avail = parseInt(t.match(/MemAvailable:\s+(\d+)/)[1])
      const used = total - avail
      root.memUsage = used / total * 100
      root.memUsedGb = used / 1048576
      root.memTotalGb = total / 1048576
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      statFile.reload()
      memFile.reload()
    }
  }

  // CPU pill
  Rectangle {
    implicitWidth: cpuText.implicitWidth + 24 * root.uiScale
    height: 36 * root.uiScale
    color: "transparent"
    radius: 8 * root.uiScale
    border.color: Colors.md3.primary
    border.width: 2 * root.uiScale

    Text {
      id: cpuText
      anchors.centerIn: parent
      text: "󰍛 " + Math.round(root.cpuUsage).toString().padStart(2, " ") + "%"
      font.pixelSize: 24 * root.uiScale
      font.bold: true
      font.family: "monospace"   // fixed width so the bar doesn't jitter
      color: Colors.palette.primary90
    }
  }

  // RAM pill
  Rectangle {
    implicitWidth: ramText.implicitWidth + 24 * root.uiScale
    height: 36 * root.uiScale
    color: "transparent"
    radius: 8 * root.uiScale
    border.color: Colors.md3.primary
    border.width: 2 * root.uiScale

    Text {
      id: ramText
      anchors.centerIn: parent
      text: "  " + root.memUsedGb.toFixed(1) + " GB"
      font.pixelSize: 24 * root.uiScale
      font.bold: true
      font.family: "Symbols Nerd Font"
      color: Colors.palette.primary90
    }
  }
}
