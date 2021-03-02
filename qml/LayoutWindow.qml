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

PopupWindow {
    id: layoutWindow

    property var layouts: [""]

    function translateLayoutName(layout) {
        switch (layout) {
        case "":
            //: Keyboard layout without any name given
            //% "Unknown"
            return qsTrId("fingerterm-keyboard-layout_la_keyboard-layout-unknown")
        case "english":
            return "English"
        case "finnish":
            return "Suomi"
        case "french":
            return "Français"
        case "german":
            return "Deutsch"
        case "qwertz":
            return "QWERTZ"
        default:
            return layout.charAt(0).toUpperCase() + layout.substr(1)
        }
    }

    Component {
        id: listDelegate

        Button {
            text: translateLayoutName(modelData)
            highlighted: util.keyboardLayout === modelData
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 2*window.paddingSmall
            font.pointSize: window.uiFontSize
            onClicked: {
                util.keyboardLayout = modelData
                layoutWindow.show = false
                util.notifyText(translateLayoutName(modelData))
            }
        }
    }

    SectionHeader {
        id: titleText
        width: parent.width
        //% "Keyboard layout"
        text: qsTrId("fingerterm-keyboard-layout_sh_keyboard-layout")
        font.pointSize: window.uiFontSize + 4*window.pixelRatio
    }

    ListView {
        anchors.fill: parent
        anchors.topMargin: titleText.height + window.paddingSmall
        delegate: listDelegate
        model: layoutWindow.layouts
        spacing: window.paddingSmall
        anchors.margins: window.paddingSmall
        boundsBehavior: Flickable.StopAtBounds
        clip: true
    }

    Button {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: window.paddingMedium
        //: Return to the previous page
        //% "Back"
        text: qsTrId("fingerterm-keyboard-layout_la_back")
        onClicked: layoutWindow.show = false
    }
}
