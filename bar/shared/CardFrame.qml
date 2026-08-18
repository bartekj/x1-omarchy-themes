import QtQuick
import QtQuick.Effects
import qs.Commons

// The bar cards' frame. Drops in where a framed Rectangle used to be —
// children go straight on this Item, so `parent` still means the card and
// anchoring to it by id still finds a parent rather than a grandparent.
// Every surface sits at z -1, so children paint over it.
//
//   none   nothing at all; the cell dividers carry the structure (default)
//   bloom  no frame — a halo behind the card, coloured by load
//   flat   the original hairline-bordered rectangle
//
// Source of truth: bar/shared/CardFrame.qml. Copied into each plugin by
// tools/build-plugin-shared — do not edit the copies.
Item {
  id: root

  // The bar's animated, transparency-aware foreground: the card recolors
  // with the bar, exactly as the flat frame did.
  property color lineColor: "white"

  property string frameStyle: "none"
  property real fillAlpha: 0.07

  // bloom only: halo colour and how hard it burns, 0..1. The host widget
  // feeds these from whatever it considers "load".
  property color glowColor: lineColor
  property real glowIntensity: 0

  // Style.cornerRadius tracks Hyprland rounding, so the cards share the
  // family's one corner identity.
  property real cornerRadius: Math.min(Style.cornerRadius, height / 2)

  // Stale style names from an older shell.json (lens, emboss, ...) fall
  // back to "none" rather than erroring or surprising with a flat box.
  readonly property string effectiveStyle:
    ["none", "flat", "bloom"].indexOf(frameStyle) >= 0 ? frameStyle : "none"
  readonly property bool useBloom: effectiveStyle === "bloom"
  readonly property bool useNone: effectiveStyle === "none"
  readonly property bool useFlat: effectiveStyle === "flat"

  // Bloom: the card is defined by light rather than by an edge. The halo is
  // a blurred copy of the card's own shape sitting behind it, so it swells
  // and colours with load instead of just decorating.
  Loader {
    anchors.fill: parent
    z: -2
    active: root.useBloom

    sourceComponent: Item {
      Rectangle {
        id: haloSource
        anchors.fill: parent
        radius: root.cornerRadius
        // An outline, not a fill: blurring a filled rect leaves the middle
        // fully coloured, which fogs the readout instead of haloing it. A
        // ring blurs outward from the edge and leaves the centre clear.
        color: "transparent"
        border.color: root.glowColor
        border.width: 2
        // Drawn only through the effect below; showing it too would stack a
        // hard-edged copy under the halo.
        visible: false
      }

      MultiEffect {
        source: haloSource
        anchors.fill: haloSource
        blurEnabled: true
        blur: 1.0
        blurMax: 16
        autoPaddingEnabled: true
        opacity: 0.35 + 0.55 * Math.max(0, Math.min(1, root.glowIntensity))

        Behavior on opacity {
          NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
      }
    }
  }

  // Bloom still needs a body, or the text floats on a bare halo.
  Rectangle {
    anchors.fill: parent
    z: -1
    visible: root.useBloom
    radius: root.cornerRadius
    color: Qt.alpha(root.lineColor, root.fillAlpha * 0.8)
  }

  // The original hairline-bordered rectangle, kept for "flat".
  Rectangle {
    anchors.fill: parent
    z: -1
    visible: root.useFlat
    radius: root.cornerRadius
    color: Style.normalFillFor(root.lineColor, root.lineColor)
    border.width: Style.normalBorderWidth
    border.color: Style.normalBorderFor(root.lineColor, root.lineColor)
  }
}
