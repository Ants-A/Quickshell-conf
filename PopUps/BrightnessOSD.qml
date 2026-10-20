import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import qs

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
      readonly property real uiScale: UiScale.factor(screen.width)
			// Since the panel's screen is unset, it will be picked by the compositor
			// when the window is created. Most compositors pick the current active monitor.
      WlrLayershell.layer: WlrLayer.Overlay

			anchors.bottom: true
			margins.bottom: screen.height / 15
			exclusiveZone: 0

			implicitWidth: 450 * uiScale
			implicitHeight: 90 * uiScale
			color: "transparent"

			// An empty click mask prevents the window from blocking mouse events.
			mask: Region {}

			Rectangle {
				anchors.fill: parent
				radius: 12 * uiScale
        color: Colors.background_dark
        opacity: 0.8

				RowLayout {
					anchors {
						fill: parent
						leftMargin: 10 * uiScale
						rightMargin: 15 * uiScale
					}
					spacing: 10 * uiScale

          Text {
            Layout.preferredWidth: 60 * uiScale
            horizontalAlignment: Text.AlignHCenter
            font.family: "Symbols Nerd Font"
            font.pixelSize: 40 * uiScale
            color: "#eff0f1"
            text: ""   // sun
          }

					Rectangle {
						// Stretches to fill all left-over space
						Layout.fillWidth: true

						implicitHeight: 20 * uiScale
						radius: 4 * uiScale
						color: Colors.background

						Rectangle {
							anchors {
								left: parent.left
								top: parent.top
								bottom: parent.bottom
							}
							color: Colors.primary

							implicitWidth: parent.width * root.brightness
							radius: parent.radius
						}
					}
					Text {
						text: Math.round(root.brightness * 100)
						color: "#eff0f1"
						font.pixelSize: 32 * uiScale
						font.bold: true
					}
				}
			}
		}
	}
}
