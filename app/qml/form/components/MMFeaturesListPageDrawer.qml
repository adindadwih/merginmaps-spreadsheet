/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../inputs" as MMInputs
import "../../components" as MMComponents
import "../../filters/components" as MMFilters

//
// Special type of drawer/page -> looks like page, but it is actually Drawer
//  - the reason for such a madness is that we need to open fullscreen page from within form editors.
//    Popups (like Drawer) can be easily opened on full screen even from components that are not
//    fullscreen. For page we would need to inject some StackView.
//

Drawer {
  id: root

  property alias pageHeader: page.pageHeader
  property alias button: primarybtn
  property alias list: listView

  signal searchTextChanged( string searchText )
  signal featureClicked( var featurePair )
  signal buttonClicked()

  width: ApplicationWindow.window.width
  height: ApplicationWindow.window.height

  edge: Qt.BottomEdge

  // Qt 6.9+ Popup/Drawer automatically applies safe area margins as padding.
  topPadding: 0
  bottomPadding: 0
  leftPadding: 0
  rightPadding: 0

  contentItem: MMComponents.MMPage {
    id: page

    width: parent.width
    height: parent.height

    pageBottomMarginPolicy: MMComponents.MMPage.PaintBehindSystemBar

    onBackClicked: root.close()

    pageContent: Item {
      width: parent.width
      height: parent.height

      ColumnLayout {
        id: contentColumn

        width: parent.width
        height: parent.height

        spacing: 0

        MMComponents.MMListSpacer { Layout.preferredHeight: __style.spacing20 }

        MMInputs.MMSearchInput {
          id: searchBar

          delayedSearch: true

          Layout.fillWidth: true

          placeholderText: qsTr("Search for features...")

          onSearchTextChanged: root.searchTextChanged( searchBar.searchText )
        }

        MMComponents.MMListSpacer { Layout.preferredHeight: __style.spacing20 }

        MMFilters.MMFilterBanner {
          id: filterBanner

          visible: __activeProject.filterController?.hasActiveFilterOnLayer( listView.model?.layer?.id )

          Layout.fillWidth: true
          text: qsTr( "Some features may be hidden by active filters" )
        }

        MMComponents.MMListSpacer {
          visible: filterBanner.visible
          Layout.preferredHeight: __style.spacing20
        }

        Item {
          id: gridContainer
          Layout.fillWidth: true
          Layout.fillHeight: true

          // Properti untuk menyimpan status saat proses drag-and-fill
          property int dragSourceIndex: -1
          property string dragSourceValue: ""
          property int currentHoverIndex: -1

          ListView {
            id: listView
            anchors.fill: parent
            clip: true
            model: root.list.model

            delegate: Rectangle {
              id: rowDelegate
              width: listView.width
              height: 44
              color: (gridContainer.dragSourceIndex !== -1 && 
                      index >= Math.min(gridContainer.dragSourceIndex, gridContainer.currentHoverIndex) && 
                      index <= Math.max(gridContainer.dragSourceIndex, gridContainer.currentHoverIndex)) 
                      ? "#e8f0fe" : (index % 2 === 0 ? "#ffffff" : "#f9fafb")
              border.color: "#d0d5dd"
              border.width: 1

              RowLayout {
                anchors.fill: parent
                spacing: 0

                // Kolom Judul Baris
                Rectangle {
                  Layout.preferredWidth: 120
                  Layout.fillHeight: true
                  color: "transparent"
                  border.color: "#e5e7eb"
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: model.FeatureTitle ? model.FeatureTitle : "-"
                    font.bold: true
                    font.pixelSize: 12
                    elide: Text.ElideRight
                  }
                }

                // Kolom Sel Data
                Rectangle {
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  color: "transparent"
                  border.color: "#e5e7eb"
                  border.width: 1

                  Text {
                    id: cellText
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: fillHandle.left
                    anchors.margins: 6
                    text: model.SearchResult ? model.SearchResult.replace(/\n/g, ' ') : "-"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                  }

                  // Handle Drag-and-Fill di sudut kanan bawah sel (kotak biru kecil ala Excel)
                  Rectangle {
                    id: fillHandle
                    width: 10
                    height: 10
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    color: "#1a73e8"
                    visible: true

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.CrossCursor

                      onPressed: {
                        gridContainer.dragSourceIndex = index
                        gridContainer.dragSourceValue = cellText.text
                        gridContainer.currentHoverIndex = index
                      }

                      onPositionChanged: function(mouse) {
                        if (gridContainer.dragSourceIndex !== -1) {
                          var globalY = mapToItem(listView, mouse.x, mouse.y).y
                          var targetIdx = listView.indexAt(10, globalY + listView.contentY)
                          if (targetIdx !== -1) {
                            gridContainer.currentHoverIndex = targetIdx
                          }
                        }
                      }

                      onReleased: {
                        if (gridContainer.dragSourceIndex !== -1 && gridContainer.currentHoverIndex !== -1) {
                          var start = Math.min(gridContainer.dragSourceIndex, gridContainer.currentHoverIndex)
                          var end = Math.max(gridContainer.dragSourceIndex, gridContainer.currentHoverIndex)

                          // Terapkan nilai sel awal ke semua baris dalam rentang tarikan
                          for (var i = start; i <= end; i++) {
                            var item = listView.model.get ? listView.model.get(i) : null
                            if (item && item.FeaturePair) {
                              // Update nilai atribut fitur
                              item.SearchResult = gridContainer.dragSourceValue
                            }
                          }
                        }
                        // Reset status drag
                        gridContainer.dragSourceIndex = -1
                        gridContainer.dragSourceValue = ""
                        gridContainer.currentHoverIndex = -1
                      }
                    }
                  }
                }
              }

              // Klik biasa untuk membuka form fitur lengkap
              MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 16
                onClicked: root.featureClicked( model.FeaturePair )
              }
            }

            footer: MMComponents.MMListSpacer { 
              height: __style.safeAreaBottom + __style.margin8 + ( primarybtn.visible ? primarybtn.height : 0 ) 
            }
          }
        }
      }

      MMComponents.MMButton {
        id: primarybtn

        width: parent.width
        anchors {
          bottom: parent.bottom
          bottomMargin: __style.margin8 + __style.safeAreaBottom
        }

        text: qsTr( "Add feature" )
        visible: __activeProject.projectRole !== "reader" && !listView.model?.layer?.readOnly

        onClicked: {
          root.close()
          root.buttonClicked()
        }
      }
    }
  }
}
