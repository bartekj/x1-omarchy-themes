import QtQuick
import qs.Commons

// Cell dividers for the resources readout.
//
// With frameStyle "none" there is no container at all, so these marks are the
// only thing giving the cluster structure — they carry the grouping, the
// rhythm and the identity on their own. Each one is drawn from primitives
// rather than glyphs, so nothing depends on what the bar font happens to ship.
//
//   glitch   the line broken into offset segments, accent on top (default)
//   slash    double shear, accent on the trailing stroke
//   chevron  a pointed > between cells; gives the row a reading direction
//   tick     HUD I-beam with an accent node at its centre
//   bars     stacked dashes stepping down — a LIVE readout of aggregate load
//   hairline the original 1px rule
//
// Source of truth: bar/shared/CellDivider.qml. Copied into the plugin by
// tools/build-plugin-shared — do not edit the copy.
Item {
  id: root

  property string dividerStyle: "glitch"
  property color lineColor: "white"
  property color accentColor: Color.accent
  // Nominal height of the mark; the old hairline rule was 14.
  property real markHeight: 14

  // "bars" only: aggregate load 0..1 and the colour of the worst resource.
  // Deliberately NOT per-cell data — a divider sits between two cells and
  // belongs to neither, and each cell's own level is already carried by its
  // icon tint. This reports the one thing the readout does not otherwise
  // show: how hard the machine is working overall.
  property real meterValue: 0
  property color meterColor: accentColor

  function mix(a, b, t) {
    return Qt.rgba(a.r + (b.r - a.r) * t,
                   a.g + (b.g - a.g) * t,
                   a.b + (b.b - a.b) * t, 1)
  }

  implicitWidth: loader.item ? loader.item.implicitWidth : 1
  implicitHeight: markHeight
  anchors.verticalCenter: parent ? parent.verticalCenter : undefined

  Loader {
    id: loader
    anchors.centerIn: parent
    sourceComponent: switch (root.dividerStyle) {
      case "glitch": return glitchMark
      case "chevron": return chevronMark
      case "tick": return tickMark
      case "bars": return barsMark
      case "hairline": return hairlineMark
      default: return slashMark
    }
  }

  // Two sheared strokes, the trailing one in the theme accent. Each fades at
  // both ends so it reads as a stroke of light rather than a drawn rule.
  Component {
    id: slashMark

    Item {
      implicitWidth: 12
      implicitHeight: root.markHeight

      Repeater {
        model: [
          { x: 1.5, color: Qt.alpha(root.lineColor, 0.5) },
          { x: 7.0, color: Qt.alpha(root.accentColor, 0.85) }
        ]

        Rectangle {
          x: modelData.x
          width: 1.5
          height: root.markHeight
          rotation: 20
          antialiasing: true
          gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.35; color: modelData.color }
            GradientStop { position: 0.65; color: modelData.color }
            GradientStop { position: 1.0; color: "transparent" }
          }
        }
      }
    }
  }

  // The rule sliced into three segments and knocked out of alignment.
  Component {
    id: glitchMark

    Item {
      implicitWidth: 6
      implicitHeight: root.markHeight

      Rectangle {
        x: 3; y: 0
        width: 1; height: root.markHeight * 0.34
        color: Qt.alpha(root.accentColor, 0.9)
      }
      Rectangle {
        x: 1; y: root.markHeight * 0.40
        width: 1; height: root.markHeight * 0.28
        color: Qt.alpha(root.lineColor, 0.55)
      }
      Rectangle {
        x: 4; y: root.markHeight * 0.72
        width: 1; height: root.markHeight * 0.28
        color: Qt.alpha(root.lineColor, 0.3)
      }
    }
  }

  // Two strokes meeting at a point. Geometry is solved rather than eyeballed:
  // each stroke is a rectangle of length L rotated off vertical by atan(b/a),
  // centred on the midpoint of the segment it stands for.
  Component {
    id: chevronMark

    Item {
      id: chev
      implicitWidth: 6
      implicitHeight: root.markHeight

      readonly property real a: 4                       // half-height
      readonly property real b: 3                       // depth of the point
      readonly property real len: Math.sqrt(a * a + b * b)
      readonly property real ang: Math.atan2(b, a) * 180 / Math.PI
      readonly property real cx: 1.5
      readonly property real cy: root.markHeight / 2

      Repeater {
        model: [-1, 1]

        Rectangle {
          width: 1.4
          height: chev.len
          x: chev.cx + chev.b / 2 - width / 2
          y: chev.cy + modelData * chev.a / 2 - height / 2
          rotation: modelData * chev.ang
          transformOrigin: Item.Center
          antialiasing: true
          color: Qt.alpha(root.lineColor, 0.6)
        }
      }
    }
  }

  // An instrument tick: capped stem with an accent node on the axis.
  Component {
    id: tickMark

    Item {
      implicitWidth: 5
      implicitHeight: root.markHeight

      Rectangle {
        x: 2; y: 2
        width: 1; height: root.markHeight - 4
        color: Qt.alpha(root.lineColor, 0.35)
      }
      Rectangle {
        x: 0; y: 1
        width: 5; height: 1
        color: Qt.alpha(root.lineColor, 0.6)
      }
      Rectangle {
        x: 0; y: root.markHeight - 2
        width: 5; height: 1
        color: Qt.alpha(root.lineColor, 0.6)
      }
      Rectangle {
        x: 1.5; y: root.markHeight / 2 - 1
        width: 2; height: 2
        color: root.accentColor
      }
    }
  }

  // Stacked dashes stepping down in width — a live level readout of the
  // aggregate load, not decoration that merely looks like one.
  Component {
    id: barsMark

    Item {
      implicitWidth: 7
      implicitHeight: root.markHeight

      Repeater {
        model: [
          { w: 7, dy: -5.0, base: 0.35, from: 0.00 },
          { w: 5, dy: -0.75, base: 0.22, from: 0.33 },
          { w: 3, dy: 3.5, base: 0.14, from: 0.66 }
        ]

        Rectangle {
          // A continuous ramp rather than a discrete lit/unlit step. CPU
          // swings hard between two-second ticks, and these dividers are the
          // row's only structure — one that blinks on and off would be
          // unusable. Every dash therefore stays visible at its base alpha
          // and merely gains weight and colour as load crosses its threshold.
          readonly property real gain: Math.max(0, Math.min(1,
            (root.meterValue - modelData.from) / 0.25))

          x: 0
          y: root.markHeight / 2 + modelData.dy
          width: modelData.w
          height: 1.5
          color: Qt.alpha(root.mix(root.lineColor, root.meterColor, gain),
                          modelData.base + gain * 0.6)

          Behavior on color {
            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
          }
        }
      }
    }
  }

  Component {
    id: hairlineMark

    Rectangle {
      implicitWidth: 1
      implicitHeight: root.markHeight
      width: 1
      height: root.markHeight
      color: Qt.alpha(root.lineColor, 0.12)
    }
  }
}
