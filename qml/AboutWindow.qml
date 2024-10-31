/*
    Copyright (c) 2021 Jolla Ltd.

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

NotifyWin {
    text: {
        //% "Fingerterm"
        var title = qsTrId("fingerterm-about_la_fingerterm")
        //% "Author:"
        var author = qsTrId("fingerterm-about_la_author")
        //% "Config files for adjusting settings are at:"
        var configFiles = qsTrId("fingerterm-about_la_config-files-location")
        //% "Source code:"
        var sourceCode = qsTrId("fingerterm-about_la_source-code")
        //% "Current window title:"
        var windowTitle = qsTrId("fingerterm-about_la_window-title")
        //% "Current terminal size:"
        var terminalSize = qsTrId("fingerterm-about_la_terminal-size")
        //% "Charset:"
        var charSet = qsTrId("fingerterm-about_la_charset")

        var str = "<font size=\"+3\">" + title + " " + util.versionString() + "</font><br>\n" +
                "<font size=\"+1\">" +
                author + " Heikki Holstila &lt;<a href=\"mailto:heikki.holstila@gmail.com?subject=FingerTerm\">heikki.holstila@gmail.com</a>&gt;<br><br>\n\n" +
                configFiles + "<br>\n" +
                util.configPath() + "/<br><br>\n" +
                sourceCode + "<br>\n<a href=\"https://github.com/sailfishos/fingerterm/\">https://github.com/sailfishos/fingerterm/</a>"
        if (term.rows != 0 && term.columns != 0) {
            str += "<br><br>" + windowTitle + " <font color=\"gray\">" + util.windowTitle.substring(0, 40)
                    + "</font>" //cut long window title
            if (util.windowTitle.length > 40)
                str += "..."
            str += "<br>" + terminalSize + " <font color=\"gray\">" + term.columns + "×" + term.rows + "</font>"
            str += "<br>" + charSet + " <font color=\"gray\">" + util.charset + "</font>"
        }
        str += "</font>"
        return str
    }
    onDismissed: util.showWelcomeScreen = false
}
