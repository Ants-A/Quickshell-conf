import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland 
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import ".."

Scope {
	id: root

	// Bind the pipewire node so its volume will be tracked
	PwObjectTracker {
		objects: [ Pipewire.defaultAudioSink ]
	}

	Connections {
		target: Pipewire.defaultAudioSink?.audio

		function onVolumeChanged() {
			root.shouldShowOsd = true;
			hideTimer.restart();
		}

		function onMutedChanged() {
			root.shouldShowOsd = true;
			hideTimer.restart();
		}
	}

	property bool shouldShowOsd: false

	Timer {
		id: hideTimer
		interval: 1500
		onTriggered: root.shouldShowOsd = false
	}

	// The OSD window will be created and destroyed based on shouldShowOsd.
	// PanelWindow.visible could be set instead of using a loader, but using
	// a loader will reduce the memory overhead when the window isn't open.
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

            text: {
              const audio = Pipewire.defaultAudioSink?.audio;
              if (!audio || audio.muted || audio.volume === 0)
                  return "󰖁";      // volume off
              return "\uf028";          // volume up
            }
          }

					Rectangle {
						// Stretches to fill all left-over space
						Layout.fillWidth: true

						implicitHeight: 20
						radius: 3
            color: Colors.md3.background

						Rectangle {
							anchors {
								left: parent.left
								top: parent.top
								bottom: parent.bottom
							}
              color: ((Pipewire.defaultAudioSink?.audio.muted ?? false) ?  Colors.md3.on_primary : Colors.md3.primary)

							implicitWidth: parent.width * Pipewire.defaultAudioSink?.audio.volume ?? 0
							radius: parent.radius
						}
          }
          Text {
            text: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100)
            color: "#eff0f1"
            font.pixelSize: 32
            font.bold: true
          }
				}
			}
		}
	}
}
