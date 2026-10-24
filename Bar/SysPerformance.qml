import QtQuick
import Quickshell.Io
import qs

Row {
  id: root
  property real uiScale: 1

  property real cpuUsage: 0
  property real gpuUsage: 0
  property real memUsage: 0
  property real memUsedGb: 0
  property real memTotalGb: 0
  property real lastIdle: 0
  property real lastTotal: 0

  // "" = still detecting, otherwise "nvidia" | "amd" | "intel" | "none"
  property string gpuMode: ""

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

  // ---- GPU detection (runs once) ----
  Process {
    id: gpuDetect
    running: true
    command: ["sh", "-c", `
      # NVIDIA: prefer if nvidia-smi works
      if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
        echo nvidia; exit 0
      fi

      # AMD: pick the card with the most VRAM (the dGPU if you also have an iGPU)
      best=""; bestmem=-1
      for d in /sys/class/drm/card[0-9]*/device; do
        [ -r "$d/gpu_busy_percent" ] || continue
        m=$(cat "$d/mem_info_vram_total" 2>/dev/null || echo 0)
        if [ "$m" -gt "$bestmem" ]; then best="$d/gpu_busy_percent"; bestmem=$m; fi
      done
      if [ -n "$best" ]; then echo "amd:$best"; exit 0; fi

      # Intel (i915): approximate load from current/max frequency
      for c in /sys/class/drm/card[0-9]*; do
        if [ -r "$c/gt_act_freq_mhz" ] && [ -r "$c/gt_RP0_freq_mhz" ]; then
          echo "intel:$c"; exit 0
        fi
      done

      echo none
    `]
    stdout: StdioCollector {
      onStreamFinished: {
        const out = text.trim()
        const sep = out.indexOf(":")
        const mode = sep < 0 ? out : out.slice(0, sep)
        const arg = sep < 0 ? "" : out.slice(sep + 1)

        if (mode === "amd") {
          gpuFile.path = arg
        } else if (mode === "nvidia") {
          gpuProc.command = ["nvidia-smi",
            "--query-gpu=utilization.gpu",
            "--format=csv,noheader,nounits"]
        } else if (mode === "intel") {
          gpuProc.command = ["sh", "-c",
            `a=$(cat ${arg}/gt_act_freq_mhz); m=$(cat ${arg}/gt_RP0_freq_mhz); echo $((a * 100 / m))`]
        }
        root.gpuMode = mode === "" ? "none" : mode
      }
    }
  }

  // AMD: sysfs file
  FileView {
    id: gpuFile
    onLoaded: root.gpuUsage = parseInt(text()) || 0
  }

  // NVIDIA / Intel: command output
  Process {
    id: gpuProc
    stdout: StdioCollector {
      onStreamFinished: {
        const vals = text.trim().split("\n").map(Number).filter(n => !isNaN(n))
        root.gpuUsage = vals.length > 0 ? Math.max(...vals) : 0
      }
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

      if (root.gpuMode === "amd")
        gpuFile.reload()
      else if ((root.gpuMode === "nvidia" || root.gpuMode === "intel") && !gpuProc.running)
        gpuProc.running = true
    }
  }

  // CPU pill
  Rectangle {
    implicitWidth: cpuText.implicitWidth + 24 * root.uiScale
    height: 36 * root.uiScale
    color: "transparent"
    radius: 8 * root.uiScale
    border.color: Colors.primary
    border.width: 2 * root.uiScale

    Text {
      id: cpuText
      anchors.centerIn: parent
      text: "󰍛 " + Math.round(root.cpuUsage).toString().padStart(2, " ") + "%"
      font.pixelSize: 24 * root.uiScale
      font.bold: true
      font.family: "monospace"   // fixed width so the bar doesn't jitter
      color: Colors.primary90
    }
  }

  // GPU pill (hidden until detected, and if no supported GPU exists)
  Rectangle {
    visible: root.gpuMode !== "" && root.gpuMode !== "none"
    implicitWidth: gpuText.implicitWidth + 24 * root.uiScale
    height: 36 * root.uiScale
    color: "transparent"
    radius: 8 * root.uiScale
    border.color: Colors.primary
    border.width: 2 * root.uiScale

    Text {
      id: gpuText
      anchors.centerIn: parent
      text: "󰢮 " + Math.round(root.gpuUsage).toString().padStart(2, " ") + "%"
      font.pixelSize: 24 * root.uiScale
      font.bold: true
      font.family: "monospace"
      color: Colors.primary90
    }
  }

  // RAM pill
  Rectangle {
    implicitWidth: ramText.implicitWidth + 24 * root.uiScale
    height: 36 * root.uiScale
    color: "transparent"
    radius: 8 * root.uiScale
    border.color: Colors.primary
    border.width: 2 * root.uiScale

    Text {
      id: ramText
      anchors.centerIn: parent
      text: "  " + root.memUsedGb.toFixed(1) + " GB"
      font.pixelSize: 24 * root.uiScale
      font.bold: true
      font.family: "Symbols Nerd Font"
      color: Colors.primary90
    }
  }
}
