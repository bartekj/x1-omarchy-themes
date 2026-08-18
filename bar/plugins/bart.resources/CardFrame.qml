import QtQuick
import QtQuick.Effects
import qs.Commons

// The bar cards' frame, in eleven styles. Drops in where a framed Rectangle
// used to be — children go straight on this Item, so `parent` still means
// the card and anchoring to it by id still finds a parent rather than a
// grandparent. Every surface sits at z -1, so children paint over it.
//
//   none     nothing at all; the cell dividers carry the structure
//   emboss   stamped plate — narrow crisp bevel, flat graded face
//   lens     convex glass bead — soft dome, wide lit shoulder
//   dome     glass lozenge — full-height curve, gloss band, pill corners
//   bracket  no surface; machined end caps, [ readout ]
//   rail     no enclosure; an accent bar under the row
//   chamfer  octagonal cut-corner plate with a hairline edge
//   inset    a well carved into the bar — concave, not convex
//   blade    square accent edge left, rounded right; directional
//   bloom    no frame at all — a halo behind the card, coloured by load
//   flat     the original hairline-bordered rectangle
//
// All but none, bloom and flat are one shader (card.frag) branching on uStyle.
// bloom is QML instead, because its halo spills outside the item's bounds and
// takes its colour from live data — neither fits a shader clipped to the item.
//
// Source of truth: bar/shared/CardFrame.qml. Copied into each plugin by
// tools/build-plugin-shared — do not edit the copies.
Item {
  id: root

  // The bar's animated, transparency-aware foreground: the card recolors
  // with the bar, exactly as the flat frame did.
  property color lineColor: "white"

  property string frameStyle: "none"
  property real bulge: 4      // width of the domed shoulder, px (lens)
  property real specular: 0.6
  property real fillAlpha: 0.07
  property real rimGain: 0.5
  property vector2d light: Qt.vector2d(-0.45, -0.75) // upper left

  // rail and blade carry the theme accent on one edge.
  property color accentColor: Color.accent

  // bloom only: halo colour and how hard it burns, 0..1. The host widget
  // feeds these from whatever it considers "load".
  property color glowColor: lineColor
  property real glowIntensity: 0

  // Dome commits to a full pill; every other style keeps the variant's
  // corner identity, since Style.cornerRadius tracks Hyprland rounding
  // (stealth 1 ... ember 10).
  property real cornerRadius: frameStyle === "dome"
    ? height / 2
    : Math.min(Style.cornerRadius, height / 2)

  // Index IS the shader's uStyle, so membership and numbering live in one
  // place and cannot drift apart from card.frag.
  readonly property var shaderStyles: [
    "lens", "emboss", "dome", "bracket", "rail", "chamfer", "inset", "blade"
  ]
  readonly property bool wantsShader: shaderStyles.indexOf(frameStyle) >= 0
  readonly property int styleIndex: Math.max(0, shaderStyles.indexOf(frameStyle))

  // Uncompiled is the pre-first-frame state, so only a hard Error falls back;
  // gating on Compiled instead would keep the shader hidden, and a hidden
  // ShaderEffect never renders, so it would never compile in the first place.
  readonly property bool useShader: wantsShader && shader.status !== ShaderEffect.Error
  readonly property bool useBloom: frameStyle === "bloom"
  // "none" draws nothing at all: for layouts where the cell dividers carry
  // the whole structure and a container would only get in their way.
  readonly property bool useNone: frameStyle === "none"
  readonly property bool useFlat: !useShader && !useBloom && !useNone

  // Matches the icon transition in the resources cells and the bar's own
  // foreground animation.
  property color tint: lineColor
  Behavior on tint {
    ColorAnimation { duration: 160 }
  }

  ShaderEffect {
    id: shader
    anchors.fill: parent
    z: -1
    visible: root.useShader
    fragmentShader: Qt.resolvedUrl("card.frag.qsb")

    // Colour uniforms go in opaque and opacity travels separately in uFill:
    // Qt premultiplies colour properties by their alpha, which at a 0.07 fill
    // would drag the tint almost to black.
    property vector2d uSize: Qt.vector2d(Math.max(width, 1), Math.max(height, 1))
    property color uTint: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 1)
    property color uRim: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 1)
    property color uAccent: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 1)
    property vector2d uLight: root.light
    property real uRadius: root.cornerRadius
    property real uBulge: root.bulge
    property real uFill: root.fillAlpha
    property real uSpec: root.specular
    property real uRimGain: root.rimGain
    property int uStyle: root.styleIndex

    onStatusChanged: if (status === ShaderEffect.Error) console.warn("CardFrame: shader failed, using flat frame:", log)
  }

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

  // The frame this replaces, kept for "flat" and as the shader's fallback.
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
