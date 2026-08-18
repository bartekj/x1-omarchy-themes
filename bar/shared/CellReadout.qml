import QtQuick
import qs.Commons

// How a single resource cell states its value.
//
//   sparkwide  the number, then the sparkline beside it (default)
//   text       the padded number, as the cluster has always shown it
//   meter      the number with a progress rule under it
//   segments   a five-segment LED bar instead of the number
//   spark      the number over a faint sparkline of recent history
//
// spark and sparkwide both keep the digits: a graph alone shows trend but
// loses the reading, and at bar size the reading is what you actually glance
// for. They differ only in the trade — spark costs no extra width but sits
// the number on top of the graph, sparkwide keeps them apart at the cost of
// roughly 26px per cell.
//
// segments is the one mode that drops the number, deliberately: it trades the
// exact value for fill. Exact figures stay one click away in the detail panel.
//
// Every mode keeps a fixed width. The value text is space-padded upstream, so
// nothing in the row shifts as 2% becomes 100%.
//
// Source of truth: bar/shared/CellReadout.qml. Copied into the plugin by
// tools/build-plugin-shared — do not edit the copy.
Item {
  id: root

  property string readoutStyle: "sparkwide"
  property string value: ""
  // 0..1, already normalised by the host — temperature is not a percentage.
  property real fraction: 0
  // Oldest-to-newest normalised samples; only the spark modes read it.
  property var history: []

  property color textColor: "white"
  property color levelColor: "white"
  property string fontFamily: "monospace"
  property real fontSize: 12

  implicitWidth: loader.item ? loader.item.implicitWidth : 0
  implicitHeight: loader.item ? loader.item.implicitHeight : fontSize

  readonly property real clamped: Math.max(0, Math.min(1, fraction))

  // Filled sparkline over root.history. Repaint is driven explicitly:
  // Canvas has no idea the array or the colour changed.
  component SparkCanvas: Canvas {
    id: spark

    property real strokeAlpha: 1.0
    property real areaAlpha: 0.2

    renderStrategy: Canvas.Cooperative

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()

      var h = root.history
      if (!h || h.length < 2) return

      var step = width / (h.length - 1)
      function px(i) { return i * step }
      function py(i) { return height - Math.max(0, Math.min(1, h[i])) * (height - 1) - 0.5 }

      ctx.beginPath()
      ctx.moveTo(px(0), py(0))
      for (var i = 1; i < h.length; i++) ctx.lineTo(px(i), py(i))

      ctx.lineWidth = 1
      ctx.strokeStyle = Qt.alpha(root.levelColor, spark.strokeAlpha)
      ctx.stroke()

      ctx.lineTo(width, height)
      ctx.lineTo(0, height)
      ctx.closePath()
      ctx.fillStyle = Qt.alpha(root.levelColor, spark.areaAlpha)
      ctx.fill()
    }

    Connections {
      target: root
      function onHistoryChanged() { spark.requestPaint() }
      function onLevelColorChanged() { spark.requestPaint() }
    }

    Component.onCompleted: requestPaint()
  }

  Loader {
    id: loader
    anchors.centerIn: parent
    sourceComponent: switch (root.readoutStyle) {
      case "meter": return meterMode
      case "segments": return segmentsMode
      case "spark": return sparkMode
      case "sparkwide": return sparkWideMode
      default: return textMode
    }
  }

  Component {
    id: textMode

    Text {
      text: root.value
      color: root.textColor
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
    }
  }

  // The number, underlined by how full it is.
  Component {
    id: meterMode

    Item {
      implicitWidth: label.implicitWidth
      implicitHeight: label.implicitHeight + 4

      Text {
        id: label
        text: root.value
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
      }

      Rectangle {
        y: label.implicitHeight + 2
        width: parent.width
        height: 1.5
        color: Qt.alpha(root.textColor, 0.14)

        Rectangle {
          width: parent.width * root.clamped
          height: parent.height
          color: root.levelColor

          Behavior on width {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
          }
          Behavior on color {
            ColorAnimation { duration: 300 }
          }
        }
      }
    }
  }

  // Five segments, each lighting across its own fifth of the range so the
  // bar fills smoothly rather than stepping.
  Component {
    id: segmentsMode

    Row {
      spacing: 1.5

      Repeater {
        model: 5

        Rectangle {
          readonly property real gain: Math.max(0, Math.min(1,
            (root.clamped - index / 5) * 5))

          width: 3.5
          height: 11
          color: Qt.alpha(gain > 0 ? root.levelColor : root.textColor,
                          0.12 + gain * 0.78)

          Behavior on color {
            ColorAnimation { duration: 300 }
          }
        }
      }
    }
  }

  // History behind the reading. Costs no width, so the row stays as compact
  // as plain text; the graph is held well back so the digits stay first.
  Component {
    id: sparkMode

    Item {
      implicitWidth: Math.max(overlayLabel.implicitWidth, 26)
      implicitHeight: overlayLabel.implicitHeight

      SparkCanvas {
        anchors.fill: parent
        strokeAlpha: 0.45
        areaAlpha: 0.16
      }

      Text {
        id: overlayLabel
        anchors.centerIn: parent
        text: root.value
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
      }
    }
  }

  // Reading and history side by side, both at full contrast. The honest cost
  // is width: about 26px per cell, four cells, so the cluster grows.
  Component {
    id: sparkWideMode

    Row {
      spacing: 4

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
      }

      SparkCanvas {
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 12
        strokeAlpha: 1.0
        areaAlpha: 0.22
      }
    }
  }
}
