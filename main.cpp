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

#include "qplatformdefs.h"

#include <QtGui>
#include <QtQml>
#include <QQuickView>
#include <QDir>
#include <QString>

extern "C" {
#include <pty.h>
#include <stdlib.h>
#include <unistd.h>
#include <pwd.h>
#include <sys/types.h>
}

#include "ptyiface.h"
#include "terminal.h"
#include "textrender.h"
#include "util.h"
#include "version.h"
#include "keyloader.h"

int main(int argc, char *argv[])
{
    QString settings_path(QDir::homePath() + "/.config/FingerTerm");
    QDir dir;

    if (!dir.exists(settings_path)) {
        if (!dir.mkdir(settings_path))
            qWarning() << "Could not create fingerterm settings path" << settings_path;
    }

    QSettings *settings = new QSettings(settings_path + "/settings.ini", QSettings::IniFormat);

    QCoreApplication::setApplicationName("Fingerterm");

    // fork the child process before creating QGuiApplication
    int socketM;
    int pid = forkpty(&socketM,NULL,NULL,NULL);
    if( pid==-1 ) {
        qFatal("forkpty failed");
        exit(1);
    } else if( pid==0 ) {
        setenv("TERM", settings->value("terminal/envVarTERM", "xterm").toByteArray(), 1);

        QString execCmd;
        for(int i=0; i<argc-1; i++) {
            if( QString(argv[i]) == "-e" )
                execCmd = QString(argv[i+1]);
        }
        if(execCmd.isEmpty()) {
            execCmd = settings->value("general/execCmd").toString();
        }

        delete settings; // don't need 'em here

        passwd *pwdstruct = getpwuid(getuid());
        char *shell = pwdstruct->pw_shell;
        if (execCmd.isEmpty()) {
            // execute the user's default shell
            execl(shell, shell, "--login", (char*)NULL);
        } else {
            execl(shell, shell, "-c", qPrintable(execCmd), (char*)NULL);
        }

        exit(0);
    }

    QGuiApplication app(argc, argv);

    QScreen* sc = app.primaryScreen();
    if(sc){
        QFlags<Qt::ScreenOrientation> mask = Qt::PrimaryOrientation
                | Qt::PortraitOrientation
                | Qt::LandscapeOrientation
                | Qt::InvertedPortraitOrientation
                | Qt::InvertedLandscapeOrientation;
        if (settings->contains("ui/orientationMask")) {
            mask &= settings->value("ui/orientationMask").toInt();
        }
        sc->setOrientationUpdateMask(mask);
    }

    qmlRegisterType<TextRender>("FingerTerm", 1, 0, "TextRender");
    qmlRegisterUncreatableType<Util>("FingerTerm", 1, 0, "Util", "Util is created by app");
    QQuickView view;

    bool fullscreen = !app.arguments().contains("-nofs");
    QSize screenSize = QGuiApplication::primaryScreen()->size();

    if (fullscreen) {
        view.setWidth(screenSize.width());
        view.setHeight(screenSize.height());
    } else {
        view.setWidth(screenSize.width() / 2);
        view.setHeight(screenSize.height() / 2);
    }

    Terminal term;
    Util util(settings); // takes ownership
    term.setUtil(&util);
    TextRender::setUtil(&util);
    TextRender::setTerminal(&term);

    QString startupErrorMsg;

    KeyLoader keyLoader;
    keyLoader.setUtil(&util);
    bool ret = keyLoader.loadLayout(util.keyboardLayout());
    if(!ret) {
        // on failure, try to load the default one (english) directly from resources
        startupErrorMsg = "There was an error loading the keyboard layout.<br>\nUsing the default one instead.";
        util.setKeyboardLayout("english");
        ret = keyLoader.loadLayout(":/data/english.layout");
        if(!ret)
            qFatal("failure loading keyboard layout");
    }

    QQmlContext *context = view.rootContext();
    context->setContextProperty( "term", &term );
    context->setContextProperty( "util", &util );
    context->setContextProperty( "keyLoader", &keyLoader );
    context->setContextProperty( "startupErrorMessage", startupErrorMsg);

    term.setWindow(&view);
    util.setWindow(&view);
    util.setTerm(&term);

    QObject::connect(view.engine(),SIGNAL(quit()),&app,SLOT(quit()));

    view.setResizeMode(QQuickView::SizeRootObjectToView);
    view.engine()->addImportPath(QStringLiteral(DEPLOYMENT_PATH));
    view.setSource(QUrl::fromLocalFile(QStringLiteral(DEPLOYMENT_PATH) + QDir::separator() + QStringLiteral("Main.qml")));

    QObject *root = view.rootObject();
    if(!root)
        qFatal("no root object - qml error");

    if (fullscreen) {
        view.showFullScreen();
    } else {
        view.show();
    }

    PtyIFace ptyiface(pid, socketM, &term, util.charset());

    if( ptyiface.failed() )
        qFatal("pty failure");

    return app.exec();
}
