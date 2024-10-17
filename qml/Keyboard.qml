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

Item {
    id: keyboard

    property int keyModifiers
    property Key resetSticky
    property Key currentStickyPressed
    property Key currentKeyPressed

    property string keyFgColor: "#ffffff"
    property string keyBgColor: "#202020"
    property string keyHilightBgColor: "#ffffff"
    property string keyBorderColor: "#303030"

    property int feedbackDuration: 150

    property bool active

    property int horizontalMargin: util.keyboardMargins
    property int bottomMargin: util.keyboardMargins
    property int keyspacing: 6
    property int keysPerRow: keyLoader.vkbColumns
    property real keywidth: (keyboard.width - keyspacing*keysPerRow - horizontalMargin*2) / keysPerRow

    width: parent.width
    height: keyboardLoader.height + bottomMargin

    Component {
        id: keyboardContents

        Column {
            spacing: keyboard.keyspacing
            width: parent.width

            Repeater {
                id: rowRepeater

                model: keyLoader.vkbRows
                width: parent.width

                delegate: Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: keyboard.keyspacing

                    Repeater {
                        id: colRepeater

                        property int rowIndex: index
                        model: keyLoader.vkbColumns
                        delegate: Key {
                            property var keydata: keyLoader.keyAt(colRepeater.rowIndex, index)
                            label: keydata[0]
                            code: keydata[1]
                            label_alt: keydata[2]
                            code_alt: keydata[3]
                            width: keyboard.keywidth * keydata[4] + ((keydata[4] - 1) * keyboard.keyspacing) + 1
                            sticky: keydata[5]
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: keyboardLoader

        width: parent.width
    }

    Component.onCompleted: {
        keyboardLoader.sourceComponent = keyboardContents
    }

    Rectangle {
        // visual key press feedback...
        id: visualKeyFeedbackRect

        property alias label: label.text
        property var _key: (currentKeyPressed
                            && currentKeyPressed.currentLabel.length === 1
                            && currentKeyPressed.currentLabel !== " ")
                           ? currentKeyPressed : null

        visible: _key || visualFeedbackDelay.running
        radius: window.radiusSmall
        color: keyFgColor

        Text {
            id: label

            color: keyBgColor
            font.pointSize: 34*window.pixelRatio
            anchors.centerIn: parent
        }
        Timer {
            id: visualFeedbackDelay
            interval: feedbackDuration
        }
        on_KeyChanged: {
            if (_key) {
                visualKeyFeedbackRect.label = _key.currentLabel
                visualKeyFeedbackRect.width = _key.width * 1.5
                visualKeyFeedbackRect.height = _key.height * 1.5
                var mappedCoord = keyboard.mapFromItem(_key, 0, 0)
                visualKeyFeedbackRect.x = mappedCoord.x - (visualKeyFeedbackRect.width - _key.width) / 2
                visualKeyFeedbackRect.y = mappedCoord.y - _key.height*1.5
                visualFeedbackDelay.restart()
            }
        }
    }

    Connections {
        target: util
        onKeyboardLayoutChanged: {
            var ret = keyLoader.loadLayout(util.keyboardLayout)
            if (!ret) {
                //% "There was an error loading the keyboard layout. Using the default one instead."
                showErrorMessage(qsTrId("fingerterm-keyboard_la_erro-loading"))
                util.keyboardLayout = "english"
                //try the default as a fallback (load from resources to ensure it will succeed)
                ret = keyLoader.loadLayout(":/data/english.layout")
                if (!ret) {
                    console.log("keyboard layout fail")
                    Qt.quit()
                }
            }
            keyboard.keyModifiers = 0
            // makes the keyboard component reload itself with new data
            keyboardLoader.sourceComponent = undefined
            keyboardLoader.sourceComponent = keyboardContents
        }
    }

    //borrowed from nemo-keyboard
    //Parameters: (x, y) in view coordinates
    function keyAt(x, y) {
        var item = keyboard
        x -= keyboard.x
        y -= keyboard.y

        while ((item = item.childAt(x, y)) != null) {
            //return the first "Key" element we find
            if (typeof item.currentCode !== 'undefined') {
                return item
            }

            // Cheaper mapToItem, assuming we're not using anything fancy.
            x -= item.x
            y -= item.y
        }

        return null
    }
}
