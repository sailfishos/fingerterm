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
import FingerTerm 1.0
import QtQuick.Window 2.0

Item {
    id: root

    width: 540
    height: 960

    Binding {
        target: util
        property: "windowOrientation"
        value: page.orientation
    }

    Item {
        id: page

        property int orientation: forceOrientation ? forcedOrientation : Screen.orientation
        property bool forceOrientation: util.orientationMode != Util.OrientationAuto
        property int forcedOrientation: util.orientationMode == Util.OrientationLandscape ? Qt.LandscapeOrientation
                                                                                          : Qt.PortraitOrientation
        property bool portrait: rotation % 180 == 0

        property QtObject _cornerConfig
        Component.onCompleted: {
            // avoid hard dependency to nemo configuration and silica
            _cornerConfig = Qt.createQmlObject("import Nemo.Configuration 1.0; ConfigurationValue { key: '/desktop/sailfish/silica/rounded_corners' } ",
                                               page, 'ConfigurationValue')
        }
        property int cornerRounding: {
            var biggest = 0
            if (_cornerConfig) {
                // simple reading of just the biggest corner, assumed detached by full length from edges
                for (var i = 0; i < _cornerConfig.value.length; i++) {
                    var configItem = _cornerConfig.value[i]
                    if (configItem.length == 3) {
                        biggest = Math.max(biggest, configItem[2])
                    }
                }
            }

            return biggest
        }

        width: portrait ? root.width : root.height
        height: portrait ? root.height : root.width
        anchors.centerIn: parent
        rotation: Screen.angleBetween(orientation, Screen.primaryOrientation)
        focus: true
        Keys.onPressed: {
            term.keyPress(event.key,event.modifiers,event.text);
        }

        Rectangle {
            id: window

            property string fgcolor: "black"
            property string bgcolor: "#000000"
            property int fontSize: 14*pixelRatio

            property int fadeOutTime: 80
            property int fadeInTime: 350
            property real pixelRatio: root.width / 540

            // layout constants
            property int buttonWidthSmall: 60*pixelRatio
            property int buttonWidthLarge: 180*pixelRatio
            property int buttonWidthHalf: 90*pixelRatio

            property int buttonHeightSmall: 48*pixelRatio
            property int buttonHeightLarge: 68*pixelRatio

            property int headerHeight: 20*pixelRatio

            property int radiusSmall: 5*pixelRatio
            property int radiusMedium: 10*pixelRatio
            property int radiusLarge: 15*pixelRatio

            property int paddingSmall: 5*pixelRatio
            property int paddingMedium: 10*pixelRatio
            property int paddingLarge: 20*pixelRatio

            property int fontSizeSmall: 14*pixelRatio
            property int fontSizeLarge: 24*pixelRatio

            property int uiFontSize: util.uiFontSize*pixelRatio

            property int scrollBarWidth: 6*pixelRatio

            anchors.fill: parent
            color: bgcolor

            Connections {
                target: util
                onKeyboardModeChanged: {
                    window.setTextRenderAttributes();
                    window.updateVKB();
                }
            }

            Rectangle {
                id: bellTimerRect
                visible: opacity > 0
                opacity: bellTimer.running ? 0.5 : 0.0
                anchors.fill: parent
                color: "#ffffff"
                Behavior on opacity {
                    NumberAnimation {
                        duration: bellTimer.interval
                    }
                }
            }

            Lineview {
                id: lineView

                topMargin: page.portrait ? page.cornerRounding : 0
                horizontalMargin: page.portrait ? 0 : page.cornerRounding
                show: (util.keyboardMode == Util.KeyboardFade) && vkb.active
            }

            Keyboard {
                id: vkb

                y: parent.height - vkb.height
                horizontalMargin: Math.max(util.keyboardMargins, !page.portrait ? page.cornerRounding : 0)
                bottomMargin: Math.max(util.keyboardMargins, page.portrait ? page.cornerRounding : 0)
                visible: page.activeFocus && util.keyboardMode !== Util.KeyboardOff
            }

            // area that handles gestures/select/scroll modes and vkb-keypresses
            MultiPointTouchArea {
                id: multiTouchArea
                anchors.fill: parent

                property int firstTouchId: -1
                property var pressedKeys: ({})

                onPressed: {
                    touchPoints.forEach(function (touchPoint) {
                        var key = vkb.keyAt(touchPoint.x, touchPoint.y);
                        if ((key == null) || (!vkb.active)) {
                            if (multiTouchArea.firstTouchId == -1) {
                                multiTouchArea.firstTouchId = touchPoint.pointId;

                                //gestures c++ handler
                                textrender.mousePress(touchPoint.x, touchPoint.y - textrender.y);
                            }
                        }

                        if (key != null) {
                            key.handlePress(multiTouchArea, touchPoint.x, touchPoint.y);
                        }
                        multiTouchArea.pressedKeys[touchPoint.pointId] = key;
                    });
                }
                onUpdated: {
                    touchPoints.forEach(function (touchPoint) {
                        if (multiTouchArea.firstTouchId == touchPoint.pointId) {
                            //gestures c++ handler
                            textrender.mouseMove(touchPoint.x, touchPoint.y - textrender.y);
                        }

                        var key = multiTouchArea.pressedKeys[touchPoint.pointId];
                        if (key != null) {
                            if (!key.handleMove(multiTouchArea, touchPoint.x, touchPoint.y)) {
                                delete multiTouchArea.pressedKeys[touchPoint.pointId];
                            }
                        }
                    });
                }
                onReleased: {
                    touchPoints.forEach(function (touchPoint) {
                        if (multiTouchArea.firstTouchId == touchPoint.pointId) {
                            // Toggle keyboard wake-up when tapping outside the keyboard, but:
                            //   - only when not scrolling (y-diff < 20 pixels)
                            //   - not in select mode, as it would be hard to select text
                            if (touchPoint.y < vkb.y && touchPoint.startY < vkb.y &&
                                    Math.abs(touchPoint.y - touchPoint.startY) < 20 &&
                                    util.dragMode !== Util.DragSelect &&
                                    util.keyboardMode != Util.KeyboardFixed) {
                                if (vkb.active) {
                                    window.sleepVKB();
                                } else {
                                    window.wakeVKB();
                                }
                            }

                            //gestures c++ handler
                            textrender.mouseRelease(touchPoint.x, touchPoint.y - textrender.y);
                            multiTouchArea.firstTouchId = -1;
                        }

                        var key = multiTouchArea.pressedKeys[touchPoint.pointId];
                        if (key != null) {
                            key.handleRelease(multiTouchArea, touchPoint.x, touchPoint.y);
                        }
                        delete multiTouchArea.pressedKeys[touchPoint.pointId];
                    });
                }
            }

            MouseArea {
                //top right corner menu button
                x: window.width - width
                width: menuImg.width + 60*window.pixelRatio
                height: menuImg.height + 30*window.pixelRatio
                opacity: 0.5
                onClicked: menu.showing = true

                Image {
                    id: menuImg

                    anchors.centerIn: parent
                    source: "icons/menu.png"
                    scale: window.pixelRatio
                }
            }


            MouseArea {
                // terminal buffer scroll button
                x: window.width - width
                width: scrollImg.width + 60*window.pixelRatio
                height: scrollImg.height + 30*window.pixelRatio
                anchors.bottom: textrender.bottom
                visible: textrender.showBufferScrollIndicator
                onClicked: textrender.scrollToEnd()

                Image {
                    id: scrollImg

                    anchors.centerIn: parent
                    source: "icons/scroll-indicator.png"
                    scale: window.pixelRatio
                }
            }

            TextRender {
                id: textrender

                property int duration
                property int cutAfter: height
                property int baseY: page.portrait ? page.cornerRounding : 0

                y: baseY
                x: !page.portrait ? page.cornerRounding : 0
                height: parent.height - (util.keyboardMode == Util.KeyboardFixed ? vkb.height : 0) - 2*baseY
                width: parent.width - 2*x
                fontPointSize: util.fontSize
                opacity: (util.keyboardMode == Util.KeyboardFade && vkb.active) ? 0.3
                                                                                : 1.0
                allowGestures: (!vkb.active || util.keyboardMode !== Util.KeyboardFade)
                               && !menu.showing && !urlWindow.show
                               && !aboutDialog.show && !layoutWindow.show

                Behavior on opacity {
                    NumberAnimation { duration: textrender.duration; easing.type: Easing.InOutQuad }
                }
                Behavior on y {
                    NumberAnimation { duration: textrender.duration; easing.type: Easing.InOutQuad }
                }

                onCutAfterChanged: {
                    // this property is used in the paint function, to make sure that the element gets
                    // painted with the updated value (might not otherwise happen because of caching)
                    textrender.redraw();
                }
            }

            Timer {
                id: fadeTimer

                interval: util.keyboardFadeOutDelay
                onTriggered: {
                    if (util.keyboardMode != Util.KeyboardFixed) {
                        window.sleepVKB();
                    }
                }
            }

            Timer {
                id: bellTimer
                interval: 120
            }

            Connections {
                target: util
                onVisualBell: bellTimer.start()
                onNotify: {
                    textNotify.text = msg;
                    textNotifyAnim.enabled = false;
                    textNotify.opacity = 1.0;
                    textNotifyAnim.enabled = true;
                    textNotify.opacity = 0;
                }
            }

            MenuFingerterm {
                id: menu
                anchors.fill: parent
            }

            Text {
                // shows large text notification in the middle of the screen (for gestures)
                id: textNotify

                anchors.fill: parent
                anchors.margins: window.paddingSmall
                color: "#ffffff"
                opacity: 0
                font.pointSize: 40*window.pixelRatio
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap

                Behavior on opacity {
                    id: textNotifyAnim
                    NumberAnimation { duration: 500; }
                }
            }

            AboutWindow {
                id: aboutDialog
            }

            NotifyWin {
                id: errorDialog
            }

            UrlWindow {
                id: urlWindow
            }

            LayoutWindow {
                id: layoutWindow
            }

            Connections {
                target: term
                onDisplayBufferChanged: window.displayBufferChanged()
            }

            function vkbKeypress(key,modifiers) {
                wakeVKB();
                term.keyPress(key,modifiers);
            }

            function wakeVKB()
            {
                if (util.keyboardMode == Util.KeyboardOff)
                    return;

                textrender.duration = window.fadeOutTime;
                fadeTimer.restart();
                vkb.active = true;
                setTextRenderAttributes();
                // FIXME: This "duration = 0" hack prevents the animations running at
                // other times (e.g. on screen rotation). It should be using States.
                textrender.duration = 0;
            }

            function sleepVKB()
            {
                textrender.duration = window.fadeInTime;
                vkb.active = false;
                setTextRenderAttributes();
                // FIXME: This "duration = 0" hack prevents the animations running at
                // other times (e.g. on screen rotation). It should be using States.
                textrender.duration = 0;
            }

            function updateVKB()
            {
                if (util.keyboardMode == Util.KeyboardOff)
                    return;

                textrender.duration = 0;
                fadeTimer.restart();
                setTextRenderAttributes();
            }

            function _applyKeyboardOffset()
            {
                if(vkb.active) {
                    var move = textrender.cursorPixelPos().y + textrender.fontHeight/2
                            + textrender.fontHeight*util.extraLinesFromCursor
                    if (move < vkb.y) {
                        textrender.y = textrender.baseY
                        textrender.cutAfter = vkb.y
                    } else {
                        textrender.y = textrender.baseY - move + vkb.y
                        textrender.cutAfter = move;
                    }
                } else {
                    textrender.y = textrender.baseY
                    textrender.cutAfter = textrender.height
                }
            }

            function setTextRenderAttributes()
            {
                vkb.active |= (util.keyboardMode === Util.KeyboardFixed)

                if (util.keyboardMode === Util.KeyboardMove) {
                    _applyKeyboardOffset()
                } else {
                    textrender.y = textrender.baseY
                    textrender.cutAfter = textrender.height
                }
            }

            function displayBufferChanged()
            {
                lineView.lines = term.printableLinesFromCursor(util.extraLinesFromCursor);
                lineView.cursorX = textrender.cursorPixelPos().x;
                lineView.cursorWidth = textrender.cursorPixelSize().width;
                lineView.cursorHeight = textrender.cursorPixelSize().height;
                setTextRenderAttributes();
            }

            Component.onCompleted: {
                if (util.showWelcomeScreen)
                    aboutDialog.show = true
                if (startupErrorMessage != "") {
                    showErrorMessage(startupErrorMessage)
                }
            }

            function showErrorMessage(string)
            {
                errorDialog.text = "<font size=\"+2\">" + string + "</font>";
                errorDialog.show = true
            }
        }
    }
}
