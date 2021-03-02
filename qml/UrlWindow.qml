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
    id: urlWindow

    property var urls: [""]

    Component {
        id: listDelegate
        Item {
            x: window.paddingSmall
            width: parent.width - 2*window.paddingSmall
            height: Math.max(openButton.height, copyButton.height)

            Button {
                id: openButton
                text: modelData
                width: parent.width - copyButton.width - window.paddingSmall
                font.pointSize: window.uiFontSize
                onClicked: Qt.openUrlExternally(modelData)
                horizontalAlignment: Text.AlignLeft
            }

            Button {
                id: copyButton
                anchors.right: parent.right
                //: Button for copying a URL
                //% "Copy"
                text: qsTrId("fingerterm-url-window_bt_copy")
                width: window.buttonWidthHalf
                onClicked: util.copyTextToClipboard(modelData)
                minHeight: openButton.height
            }
        }
    }

    SectionHeader {
        id: titleText
        width: parent.width
        //% "URL grabber"
        text: qsTrId("fingerterm-keyboard-layout_sh_urk-grabber")
        font.pointSize: window.uiFontSize + 4*window.pixelRatio
    }

    Text {
        visible: urlWindow.urls.length == 0
        anchors.centerIn: parent
        color: "#ffffff"
        //: Shown when no URLs are available
        //% "No URLs"
        text: qsTrId("fingerterm-url-window_la_no-urls")
        font.pointSize: window.uiFontSize + 4*window.pixelRatio
    }

    ListView {
        anchors.fill: parent
        anchors.topMargin: titleText.height + window.paddingSmall
        delegate: listDelegate
        model: urlWindow.urls
        spacing: window.paddingSmall
        anchors.margins: window.paddingSmall
        boundsBehavior: Flickable.StopAtBounds
        clip: true
    }

    Button {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: window.paddingMedium
        //: Button for closing the URL window
        //% "Back"
        text: qsTrId("fingerterm-url-window_bt_back")
        onClicked: urlWindow.show = false
    }
}
