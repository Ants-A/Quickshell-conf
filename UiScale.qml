pragma Singleton
import QtQuick
import Quickshell

QtObject {
  readonly property real referenceWidth: 2560
  readonly property real screenWidth: {
    const screens = Quickshell.screens.values
    return screens.length > 0 && screens[0].width > 0
      ? screens[0].width
      : referenceWidth
  }
  readonly property real screenFactor: screenWidth / referenceWidth

  // Lock screen values at the 2560px reference resolution.
  readonly property real lockBlurRadius: scaled(32)
  readonly property real lockBottomMargin: scaled(52)
  readonly property real lockBorderWidth: scaled(5)
  readonly property real lockRadius: scaled(30)
  readonly property real lockFontPixelSize: scaled(36)
  readonly property real lockHorizontalPadding: scaled(52)
  readonly property real lockWidth: scaled(512)
  readonly property real lockHeight: scaled(81)

  function scaled(value) {
    return value * screenFactor
  }

  function factor(width) {
    return width > 0 ? width / referenceWidth : screenFactor
  }
}
