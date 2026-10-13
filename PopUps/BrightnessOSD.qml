import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import ".."

Scope {
	id: root

	property bool shouldShowOsd: false
	property real brightness: 0 // 0..1

	// Current brightness value
	FileView {
		id: brightnessFile
		path: "/sys/class/backlight/amdgpu_bl1/brightness"

		onLoaded: root.updateBrightness()
	}

	// Max brightness value (read once, doesn't change)
	FileView {
		id: maxBrightnessFile
		path: "/sys/class/backlight/amdgpu_bl1/max_brightness"

		onLoaded: root.updateBrightness()
	}

	function updateBrightness() {
		const cur = parseInt(brightnessFile.text());
		const max = parseInt(maxBrightnessFile.text());

		if (!isNaN(cur) && !isNaN(max) && max > 0) {
			root.brightness = cur / max;
		}
	}

	// Called via: qs ipc call brightness trigger
	IpcHandler {
		target: "brightness"

		function trigger(): void {
			brightnessFile.reload();
			root.shouldShowOsd = true;
			hideTimer.restart();
		}
	}

	Timer {
		id: hideTimer
		interval: 1500
		onTriggered: root.shouldShowOsd = false
	}

	// The OSD window will be created and destroyed based on shouldShowOsd.
	LazyLoader {
		active: root.shouldShowOsd

		PanelWindow {
			// Since the panel's screen is unset, it will be picked by the compositor
			// when the window is created. Most compositors pick the current active monitor.
      WlrLayershell.layer: WlrLayer.Overlay

			anchors.bottom: true
			margins.bottom: screen.height / 15
			exclusiveZone: 0

			implicitWidth: 450
			implicitHeight: 90
			color: "transparent"

			// An empty click mask prevents the window from blocking mouse events.
			mask: Region {}

			Rectangle {
				anchors.fill: parent
				radius: 12
				color: "#70" + Colors.md3.on_primary_fixed.substring(1)

				RowLayout {
					anchors {
						fill: parent
						leftMargin: 10
						rightMargin: 15
					}
					spacing: 10

          Text {
            Layout.preferredWidth: 60
            horizontalAlignment: Text.AlignHCenter
            font.family: "Symbols Nerd Font"
            font.pixelSize: 40
            color: "#eff0f1"
            text: ""   // sun
          }

					Rectangle {
						// Stretches to fill all left-over space
						Layout.fillWidth: true

						implicitHeight: 20
						radius: 4
						color: Colors.md3.background

						Rectangle {
							anchors {
								left: parent.left
								top: parent.top
								bottom: parent.bottom
							}
							color: Colors.md3.primary

							implicitWidth: parent.width * root.brightness
							radius: parent.radius
						}
					}
					Text {
						text: Math.round(root.brightness * 100)
						color: "#eff0f1"
						font.pixelSize: 32
						font.bold: true
					}
				}
			}
		}
	}
}

