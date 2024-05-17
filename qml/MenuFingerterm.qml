/*
    Copyright 2011-2012 Heikki Holstila <heikki.holstila@gmail.com>

    This file is part of FingerTerm.

    FingerTerm is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.

    FingerTerm is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with FingerTerm.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import QtQuick.XmlListModel 2.0
import FingerTerm 1.0

Item {
    id: menuWin

    property bool showing

    visible: rect.x < menuWin.width

    Rectangle {
        id: fader

        color: "#000000"
        opacity: menuWin.showing ? 0.5 : 0.0
        anchors.fill: parent

        Behavior on opacity { NumberAnimation { duration: 100; } }

        MouseArea {
            anchors.fill: parent
            onClicked: menuWin.showing = false
        }
    }
    Rectangle {
        id: rect

        color: "#e0e0e0"
        anchors.left: parent.right
        anchors.leftMargin: menuWin.showing ? -width : 1
        width: flickableContent.width + 22*window.pixelRatio;
        height: menuWin.height

        MouseArea {
            // event eater
            anchors.fill: parent
        }

        Behavior on anchors.leftMargin {
            NumberAnimation { duration: 100; easing.type: Easing.InOutQuad; }
        }

        XmlListModel {
            id: xmlModel
            xml: term.getUserMenuXml()
            query: "/userMenu/item"

            XmlRole { name: "title"; query: "title/string()" }
            XmlRole { name: "command"; query: "command/string()" }
            XmlRole { name: "disableOn"; query: "disableOn/string()" }
        }

        Component {
            id: xmlDelegate
            Button {
                text: title.trim()
                isShellCommand: true
                enabled: disableOn.length === 0 || util.windowTitle.search(disableOn) === -1
                onClicked: {
                    menuWin.showing = false;
                    term.putString(command, true);
                }
            }
        }

        Rectangle {
            y: page.cornerRounding + menuFlickArea.visibleArea.yPosition * menuFlickArea.height + window.scrollBarWidth
            x: parent.width - window.paddingMedium
            width: window.scrollBarWidth
            height: menuFlickArea.visibleArea.heightRatio*menuFlickArea.height
            radius: 3*window.pixelRatio
            color: "#202020"
        }

        Flickable {
            id: menuFlickArea

            anchors.fill: parent
            anchors.topMargin: window.scrollBarWidth + page.cornerRounding
            anchors.bottomMargin: window.scrollBarWidth + page.cornerRounding
            anchors.leftMargin: window.scrollBarWidth
            anchors.rightMargin: 16*window.pixelRatio
            contentHeight: flickableContent.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: flickableContent

                spacing: 12*window.pixelRatio

                Row {
                    id: menuBlocksRow
                    spacing: 8*window.pixelRatio

                    Column {
                        spacing: 12*window.pixelRatio
                        Repeater {
                            model: xmlModel
                            delegate: xmlDelegate
                        }
                    }

                    Column {
                        spacing: 12*window.pixelRatio

                        Row {
                            Button {
                                //% "Copy"
                                text: qsTrId("fingerterm-menu_bt_copy")
                                onClicked: {
                                    menuWin.showing = false;
                                    term.copySelectionToClipboard();
                                }
                                width: window.buttonWidthHalf
                                minHeight: window.buttonHeightLarge
                                enabled: util.terminalHasSelection
                            }
                            Button {
                                //% "Paste"
                                text: qsTrId("fingerterm-menu_bt_paste")
                                onClicked: {
                                    menuWin.showing = false;
                                    term.pasteFromClipboard();
                                }
                                width: window.buttonWidthHalf
                                minHeight: window.buttonHeightLarge
                                enabled: util.canPaste
                            }
                        }
                        Button {
                            //% "URL grabber"
                            text: qsTrId("fingerterm-menu_bt_url-grabber")
                            width: window.buttonWidthLarge
                            minHeight: window.buttonHeightLarge
                            onClicked: {
                                menuWin.showing = false;
                                urlWindow.urls = term.grabURLsFromBuffer();
                                urlWindow.show = true
                            }
                        }
                        Rectangle {
                            width: window.buttonWidthLarge
                            height: fontColumn.height
                            radius: window.radiusSmall
                            color: "#606060"
                            border.color: "#000000"
                            border.width: 1

                            Column {
                                id: fontColumn
                                SectionHeader {
                                    //% "Font size"
                                    text: qsTrId("fingerterm-menu_la_font-size")
                                }
                                Row {
                                    Button {
                                        text: "<font size=\"+3\">+</font>"
                                        onClicked: {
                                            util.fontSize = util.fontSize + window.pixelRatio
                                            util.notifyText(term.columns + "×" + term.rows);
                                        }
                                        width: window.buttonWidthHalf
                                        minHeight: window.buttonHeightSmall
                                    }
                                    Button {
                                        text: "<font size=\"+3\">-</font>"
                                        onClicked: {
                                            util.fontSize = util.fontSize - window.pixelRatio
                                            util.notifyText(term.columns + "×" + term.rows);
                                        }
                                        width: window.buttonWidthHalf
                                        minHeight: window.buttonHeightSmall
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: window.buttonWidthLarge
                            height: orientationColumn.height
                            radius: window.radiusSmall
                            color: "#606060"
                            border.color: "#000000"
                            border.width: 1

                            Column {
                                id: orientationColumn
                                SectionHeader {
                                    //% "UI Orientation"
                                    text: qsTrId("fingerterm-menu_la_ui-orientation")
                                }
                                Row {
                                    Button {
                                        text: "<font size=\"-1\">"
                                                //: Automatic font size
                                                //% "Auto"
                                              + qsTrId("fingerterm-menu_bt_orientation-auto")
                                              + "</font>"
                                        highlighted: util.orientationMode == Util.OrientationAuto
                                        onClicked: util.orientationMode = Util.OrientationAuto
                                        width: window.buttonWidthSmall
                                        minHeight: window.buttonHeightSmall
                                    }
                                    Button {
                                        text: "<font size=\"-1\">"
                                                //: Short for "Landscape" orientation
                                                //% "L"
                                              + qsTrId("fingerterm-menu_bt_orientation-landscape")
                                              + "<font>"
                                        highlighted: util.orientationMode == Util.OrientationLandscape
                                        onClicked: util.orientationMode = Util.OrientationLandscape
                                        width: window.buttonWidthSmall
                                        minHeight: window.buttonHeightSmall
                                    }
                                    Button {
                                        text: "<font size=\"-1\">"
                                                //: Short for "Portrait" orientation
                                                //% "P"
                                              + qsTrId("fingerterm-menu_bt_orientation-portrait")
                                              + "</font>"
                                        highlighted: util.orientationMode == Util.OrientationPortrait
                                        onClicked: util.orientationMode = Util.OrientationPortrait
                                        width: window.buttonWidthSmall
                                        minHeight: window.buttonHeightSmall
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: window.buttonWidthLarge
                            height: dragColumn.height
                            radius: window.radiusSmall
                            color: "#606060"
                            border.color: "#000000"
                            border.width: 1

                            Column {
                                id: dragColumn
                                SectionHeader {
                                    //% "Drag mode"
                                    text: qsTrId("fingerterm-menu_la_drag-mode")
                                }
                                Row {
                                    Button {
                                        text: "<font size=\"-1\">"
                                                //% "Gesture"
                                              + qsTrId("fingerterm-menu_bt_drag-mode-gesture")
                                              + "</font>"
                                        highlighted: util.dragMode == Util.DragGestures
                                        onClicked: {
                                            util.dragMode = Util.DragGestures
                                            term.clearSelection();
                                            menuWin.showing = false;
                                        }
                                        width: window.buttonWidthSmall
                                        minHeight: window.buttonHeightSmall
                                    }
                                    Button {
                                        text: "<font size=\"-1\">"
                                                //% "Scroll"
                                              + qsTrId("fingerterm-menu_bt_drag-mode-scroll")
                                              + "</font>"
                                        highlighted: util.dragMode == Util.DragScroll
                                        onClicked: {
                                            util.dragMode = Util.DragScroll
                                            term.clearSelection();
                                            menuWin.showing = false;
                                        }
                                        width: window.buttonWidthSmall
                                        minHeight: window.buttonHeightSmall
                                    }
                                    Button {
                                        text: "<font size=\"-1\">"
                                                //% "Select"
                                              + qsTrId("fingerterm-menu_bt_drag-mode-select")
                                              + "</font>"
                                        highlighted: util.dragMode == Util.DragSelect
                                        onClicked: {
                                            util.dragMode = Util.DragSelect
                                            menuWin.showing = false;
                                        }
                                        width: window.buttonWidthSmall
                                        minHeight: window.buttonHeightSmall
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: window.buttonWidthLarge
                            height: vkbColumn.height
                            radius: window.radiusSmall
                            color: "#606060"
                            border.color: "#000000"
                            border.width: 1

                            Column {
                                id: vkbColumn
                                SectionHeader {
                                    //: Virtual keyboard behavior
                                    //% "VKB behavior"
                                    text: qsTrId("fingerterm-menu_la_virtual-keyboard-behavior")
                                }
                                Row {
                                    Button {
                                        //: Virtual keyboard behaviour
                                        //% "Fixed"
                                        text: qsTrId("fingerterm-menu_bt_virtual-keyboard-behavior-fixed")
                                        highlighted: util.keyboardMode == Util.KeyboardFixed
                                        onClicked: {
                                            util.keyboardMode = Util.KeyboardFixed
                                            menuWin.showing = false;
                                        }
                                        width: window.buttonWidthHalf
                                        minHeight: window.buttonHeightSmall
                                    }
                                    Button {
                                        //: Virtual keyboard behaviour
                                        //% "Off"
                                        text: qsTrId("fingerterm-menu_bt_virtual-keyboard-behavior-offf")
                                        highlighted: util.keyboardMode == Util.KeyboardOff
                                        onClicked: {
                                            util.keyboardMode = Util.KeyboardOff
                                            menuWin.showing = false;
                                        }
                                        width: window.buttonWidthHalf
                                        minHeight: window.buttonHeightSmall
                                    }
                                }
                                Row {
                                    Button {
                                        //: Virtual keyboard behaviour
                                        //% "Fade"
                                        text: qsTrId("fingerterm-menu_bt_virtual-keyboard-behavior-fade")
                                        highlighted: util.keyboardMode == Util.KeyboardFade
                                        onClicked: {
                                            util.keyboardMode = Util.KeyboardFade
                                            menuWin.showing = false;
                                        }
                                        width: window.buttonWidthHalf
                                        minHeight: window.buttonHeightSmall
                                    }
                                    Button {
                                        //: Virtual keyboard behaviour
                                        //% "Move"
                                        text: qsTrId("fingerterm-menu_bt_virtual-keyboard-behavior-move")
                                        highlighted: util.keyboardMode == Util.KeyboardMove
                                        onClicked: {
                                            util.keyboardMode = Util.KeyboardMove
                                            menuWin.showing = false;
                                        }
                                        width: window.buttonWidthHalf
                                        minHeight: window.buttonHeightSmall
                                    }
                                }
                            }
                        }
                        Button {
                            //% "New window"
                            text: qsTrId("fingerterm-menu_bt_new-window")
                            onClicked: {
                                menuWin.showing = false;
                                util.openNewWindow();
                            }
                        }
                        Button {
                            //: Virtual keyboard layout
                            //% "VKB layout"
                            text: qsTrId("fingerterm-menu_bt_virtual-keyboard-layout")
                            onClicked: {
                                menuWin.showing = false;
                                layoutWindow.layouts = keyLoader.availableLayouts();
                                layoutWindow.show = true
                            }
                        }
                        Button {
                            //% "About"
                            text: qsTrId("fingerterm-menu_bt_about")
                            onClicked: {
                                menuWin.showing = false;
                                aboutDialog.show = true
                            }
                        }

                        // VKB delay slider
                        Rectangle {
                            id: vkbDelaySliderArea

                            width: window.buttonWidthLarge
                            height: vkbDelayColumn.height
                            radius: window.radiusSmall
                            color: "#606060"
                            border.color: "#000000"
                            border.width: 1

                            Column {
                                id: vkbDelayColumn
                                SectionHeader {
                                    //: Virtual keyboard delay for hiding the keyboard in milliseconds
                                    //% "VKB delay"
                                    text: qsTrId("fingerterm-menu_la_virtual-keyboard-delay-header")
                                          + "\n%1 ms".arg(vkbDelaySlider.keyboardFadeOutDelay)
                                }
                                Item {
                                    width: window.buttonWidthLarge
                                    height: window.buttonHeightSmall

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width - window.paddingMedium
                                        height: window.paddingMedium
                                        radius: window.radiusSmall
                                        color: "#909090"
                                    }

                                    Rectangle {
                                        id: vkbDelaySlider

                                        property int keyboardFadeOutDelay: util.keyboardFadeOutDelay

                                        anchors.verticalCenter: parent.verticalCenter
                                        width: height
                                        radius: height/2.0
                                        height: parent.height - window.paddingSmall
                                        color: "#202020"
                                        onXChanged: {
                                            if (vkbDelaySliderMA.drag.active)
                                                vkbDelaySlider.keyboardFadeOutDelay =
                                                        Math.floor((1000+vkbDelaySlider.x/vkbDelaySliderMA.drag.maximumX*9000)/250)*250;
                                        }
                                        Component.onCompleted: {
                                            x = (keyboardFadeOutDelay-1000)/9000 * (vkbDelaySliderArea.width - vkbDelaySlider.width)
                                        }

                                        MouseArea {
                                            id: vkbDelaySliderMA
                                            anchors.fill: parent
                                            drag.target: vkbDelaySlider
                                            drag.axis: Drag.XAxis
                                            drag.minimumX: 0
                                            drag.maximumX: vkbDelaySliderArea.width - vkbDelaySlider.width
                                            drag.onActiveChanged: {
                                                if (!drag.active) {
                                                    util.keyboardFadeOutDelay = vkbDelaySlider.keyboardFadeOutDelay
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
    }
}
