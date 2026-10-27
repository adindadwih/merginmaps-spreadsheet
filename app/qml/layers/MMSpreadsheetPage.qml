import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mm 1.0

Item {
    id: root

    property var layer: null

    SpreadsheetModel {
        id: spreadsheetModel
        layer: root.layer
    }

    readonly property int rowNumberWidth: 48
    readonly property int cellWidth: 150
    readonly property int cellHeight: 44

    Rectangle {
        anchors.fill: parent
        color: "#ffffff"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "#e8edf2"

            Row {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    width: root.rowNumberWidth
                    height: root.cellHeight
                    color: "#dce3e9"
                    border.color: "#c5cdd5"

                    Text {
                        anchors.centerIn: parent
                        text: "#"
                        font.bold: true
                        color: "#344054"
                    }
                }

                Flickable {
                    id: headerFlick
                    width: parent.width - root.rowNumberWidth
                    height: parent.height
                    contentWidth: headerRow.width
                    contentHeight: height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: headerRow
                        height: root.cellHeight
                        spacing: 0

                        Repeater {
                            model: spreadsheetModel.columnCount()

                            Rectangle {
                                required property int index

                                width: root.cellWidth
                                height: root.cellHeight
                                color: "#e8edf2"
                                border.color: "#c5cdd5"

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: Text.AlignVCenter
                                    text: spreadsheetModel.columnName(index)
                                    font.bold: true
                                    color: "#344054"
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }

        Flickable {
            id: bodyFlick
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentWidth: bodyContent.width
            contentHeight: bodyContent.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            onContentXChanged: {
                if (headerFlick.contentX !== contentX)
                    headerFlick.contentX = contentX
            }

            Item {
                id: bodyContent

                width: root.rowNumberWidth
                       + spreadsheetModel.columnCount() * root.cellWidth
                height: spreadsheetModel.rowCount() * root.cellHeight

                Column {
                    id: rowsColumn
                    width: bodyContent.width
                    spacing: 0

                    Repeater {
                        model: spreadsheetModel.rowCount()

                        Row {
    			    id: spreadsheetRow
    			    required property int index
    			    property int rowNumber: index
    			    spacing: 0

                            Rectangle {
                                width: root.rowNumberWidth
                                height: root.cellHeight
                                color: "#f2f4f7"
                                border.color: "#d0d5dd"

                                Text {
                                    anchors.centerIn: parent
                                    text: index + 1
                                    color: "#475467"
                                }
                            }

                            Repeater {
                                model: spreadsheetModel.columnCount()

                                Rectangle {
                                    required property int index

                                    width: root.cellWidth
                                    height: root.cellHeight
                                    color: "#ffffff"
                                    border.color: "#eaecf0"

                                    TextInput {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        verticalAlignment: TextInput.AlignVCenter
                                        text: {
                                            const value = spreadsheetModel.cellValue(
                                                spreadsheetRow.rowNumber, index)
                                            return value === undefined ||
                                                   value === null ? "" : String(value)
                                        }
                                        selectByMouse: true
                                        clip: true
                                        color: "#101828"
                                        font.pixelSize: 14
                                        readOnly: root.layer === null ||
                                                  root.layer.readOnly

                                        onEditingFinished: {
                                            const cellIndex = spreadsheetModel.index(
                                                spreadsheetRow.rowNumber, index)
                                            spreadsheetModel.setData(
                                                cellIndex, text, Qt.EditRole)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}