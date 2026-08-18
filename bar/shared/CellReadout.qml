import QtQuick

// How a single resource cell states its value.
//
//   columns  the number, then a mini bar-chart of history (default)
//   meter    the number with a progress rule under it
//   text     the padded number, as the cluster has always shown it
//
// columns keeps the digits: a graph alone shows trend but loses the reading,
// and at bar size the reading is what you actually glance for. The gaps
// between the columns are what keep a steady value reading as an even chart
// rather than a solid block — the failure mode that retired the old readout.
//
// Every mode keeps a fixed width. The value text is space-padded upstream, so
// nothing in the row shifts as 2% becomes 100%.
//
// Source of truth: bar/shared/CellReadout.qml. Copied into the plugin by
// tools/build-plugin-shared — do not edit the copy.
Item {
  id: root

  property string readoutStyle: "columns"
  property string value: ""
  // 0..1, already normalised by the host — temperature is not a percentage.
  property real fraction: 0
  // Oldest-to-newest normalised samples; only columns reads it.
  property var history: []
  // 0 ok / 1 warn / 2 crit from x1-bar-stats. The chart goes red only at 2;
  // levels 0 and 1 stay graphite — the icon already carries the warning.
  property int level: 0

  property color textColor: "white"
  property color levelColor: "white"
  property string fontFamily: "monospace"
  property real fontSize: 12

  // Chart geometry: columnCount columns of columnWidth px with columnGap px
  // of light between them, newest sample at the right edge.
  property int columnCount: 10
  readonly property real columnWidth: 2
  readonly property real columnGap: 1

  implicitWidth: loader.item ? loader.item.implicitWidth : 0
  implicitHeight: loader.item ? loader.item.implicitHeight : fontSize

  readonly property real clamped: Math.max(0, Math.min(1, fraction))

  Loader {
    id: loader
    anchors.centerIn: parent
    sourceComponent: switch (root.readoutStyle) {
      case "meter": return meterMode
      case "text": return textMode
      default: return columnsMode
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

  // The number, then the history as a row of gapped columns on an absolute
  // 0..1 scale. Slots older than the history draw nothing, so the chart
  // grows in from the right after a shell restart instead of showing
  // zero-height ghosts for samples that never happened.
  Component {
    id: columnsMode

    Row {
      spacing: 4

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
      }

      Item {
        id: chart
        anchors.verticalCenter: parent.verticalCenter
        width: root.columnCount * (root.columnWidth + root.columnGap) - root.columnGap
        height: 12

        Repeater {
          model: root.columnCount

          Rectangle {
            // Slot columnCount-1 holds the newest sample. history is
            // reassigned wholesale each tick, so these bindings re-evaluate.
            readonly property int sampleIndex: root.history.length - root.columnCount + index
            readonly property real sample: sampleIndex >= 0 && sampleIndex < root.history.length
              ? Math.max(0, Math.min(1, root.history[sampleIndex])) : -1

            x: index * (root.columnWidth + root.columnGap)
            y: chart.height - height
            width: root.columnWidth
            // A near-zero sample still shows a 1px base mark; a missing
            // sample shows nothing at all.
            height: sample < 0 ? 0 : Math.max(1, Math.round(sample * chart.height))
            visible: sample >= 0
            color: root.level >= 2 ? Qt.alpha(root.levelColor, 0.9)
                                   : Qt.alpha(root.textColor, 0.75)

            Behavior on color {
              ColorAnimation { duration: 300 }
            }
          }
        }
      }
    }
  }
}
