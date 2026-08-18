import QtQuick

// Cell dividers for the resources readout.
//
// With frameStyle "none" there is no container at all, so these marks are
// the only thing giving the cluster structure. In the mono system they stay
// quiet: graphite only, no accent — the chart columns are the loudest thing
// in the cluster and these must not compete.
//
//   hairline the 1px rule (default)
//   tick     instrument I-beam: capped stem with a centre node
//
// Source of truth: bar/shared/CellDivider.qml. Copied into the plugin by
// tools/build-plugin-shared — do not edit the copy.
Item {
  id: root

  property string dividerStyle: "hairline"
  property color lineColor: "white"
  // Nominal height of the mark; the old hairline rule was 14.
  property real markHeight: 14

  implicitWidth: loader.item ? loader.item.implicitWidth : 1
  implicitHeight: markHeight
  anchors.verticalCenter: parent ? parent.verticalCenter : undefined

  Loader {
    id: loader
    anchors.centerIn: parent
    sourceComponent: root.dividerStyle === "tick" ? tickMark : hairlineMark
  }

  // An instrument tick: capped stem with a node on the axis — all graphite.
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
        color: Qt.alpha(root.lineColor, 0.9)
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
