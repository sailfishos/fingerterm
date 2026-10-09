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

#include <QCoreApplication>
#include <QDebug>

extern "C" {
#include <pty.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <sys/types.h>
#include <signal.h>
#include <sys/wait.h>
}

#include "terminal.h"
#include "ptyiface.h"

// SIGCHLD is turned into a notification on this pipe ("self-pipe trick"),
// so that all real work happens in the event loop and not in the handler
static int sigchldPipe[2] = { -1, -1 };

static void sigchldHandler(int)
{
    const int savedErrno = errno;
    const char c = 0;
    ssize_t ret = write(sigchldPipe[1], &c, 1); // async-signal-safe
    Q_UNUSED(ret)
    errno = savedErrno;
}

PtyIFace::PtyIFace(int pid, int masterFd, Terminal *term, QString charset, QObject *parent)
    : QObject(parent)
    , iTerm(term)
    , iPid(pid)
    , iMasterFd(masterFd)
    , iFailed(false)
    , iChildExited(false)
    , iReadNotifier(nullptr)
    , iWriteNotifier(nullptr)
    , iChildNotifier(nullptr)
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    , iTextCodec(nullptr)
#endif
{
    if (!iTerm)
        qFatal("PtyIFace: null Terminal pointer");

    if (sigchldPipe[0] == -1 && pipe2(sigchldPipe, O_CLOEXEC | O_NONBLOCK) != 0) {
        qWarning() << "PtyIFace: could not create pipe:" << qt_error_string(errno);
        iFailed = true;
        return;
    }

    // reads and writes must not block the UI, and the descriptor must not
    // leak into processes started from here (e.g. a new window)
    const int flags = fcntl(iMasterFd, F_GETFL);
    if (flags == -1 || fcntl(iMasterFd, F_SETFL, flags | O_NONBLOCK) == -1
            || fcntl(iMasterFd, F_SETFD, FD_CLOEXEC) == -1) {
        qWarning() << "PtyIFace: could not set up the pty:" << qt_error_string(errno);
        iFailed = true;
        return;
    }

    iTerm->setPtyIFace(this);

    resize(iTerm->rows(), iTerm->columns());
    connect(iTerm, &Terminal::termSizeChanged, this, &PtyIFace::resize);

    iReadNotifier = new QSocketNotifier(iMasterFd, QSocketNotifier::Read, this);
    connect(iReadNotifier, &QSocketNotifier::activated, this, &PtyIFace::readActivated);

    iWriteNotifier = new QSocketNotifier(iMasterFd, QSocketNotifier::Write, this);
    iWriteNotifier->setEnabled(false);
    connect(iWriteNotifier, &QSocketNotifier::activated, this, &PtyIFace::flushWriteBuffer);

    iChildNotifier = new QSocketNotifier(sigchldPipe[0], QSocketNotifier::Read, this);
    connect(iChildNotifier, &QSocketNotifier::activated, this, &PtyIFace::childStateChanged);

    struct sigaction action = {};
    action.sa_handler = sigchldHandler;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_RESTART | SA_NOCLDSTOP;
    sigaction(SIGCHLD, &action, nullptr);

    // the child may have exited before the handler was installed
    childStateChanged();
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    if (!charset.isEmpty()) {
        iDecoder = QStringDecoder(charset.toLatin1().constData());
        iEncoder = QStringEncoder(charset.toLatin1().constData());
    }
    if (!iDecoder.isValid() || !iEncoder.isValid()) {
        if (!charset.isEmpty())
            qWarning() << "Unsupported charset" << charset << "- using UTF-8";
        iDecoder = QStringDecoder(QStringConverter::Utf8);
        iEncoder = QStringEncoder(QStringConverter::Utf8);
    }
#else
    if (!charset.isEmpty())
        iTextCodec = QTextCodec::codecForName(charset.toLatin1());
    if (!iTextCodec)
        iTextCodec = QTextCodec::codecForName("UTF-8");
    if (!iTextCodec)
        qFatal("No valid text codec");
    // a stateful decoder keeps multibyte sequences split across reads intact
    iDecoder.reset(iTextCodec->makeDecoder());
#endif
}

PtyIFace::~PtyIFace()
{
    if (!iChildExited && iPid > 0) {
        // make the process quit
        kill(iPid, SIGHUP);
        kill(iPid, SIGTERM);
        int status = 0;
        while (waitpid(iPid, &status, 0) == -1 && errno == EINTR) { }
    }
}

void PtyIFace::childStateChanged()
{
    char buf[16];
    while (read(sigchldPipe[0], buf, sizeof(buf)) > 0) { }

    if (iChildExited)
        return;

    int status = 0;
    const pid_t ret = waitpid(iPid, &status, WNOHANG);
    if (ret == iPid || (ret == -1 && errno == ECHILD)) {
        iChildExited = true;
        // queued, so that this also works before the event loop is running
        QMetaObject::invokeMethod(QCoreApplication::instance(), "quit", Qt::QueuedConnection);
    }
}

void PtyIFace::readActivated()
{
    QByteArray data;
    readTerm(data);
    if (iTerm && !data.isEmpty())
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
        iTerm->insertInBuffer(iDecoder.decode(data));
#else
        iTerm->insertInBuffer(iDecoder->toUnicode(data));
#endif
}

void PtyIFace::resize(int rows, int columns)
{
    if (iChildExited)
        return;

    winsize winp = {};
    winp.ws_col = columns;
    winp.ws_row = rows;

    ioctl(iMasterFd, TIOCSWINSZ, &winp);
}

void PtyIFace::writeTerm(const QString &chars)
{
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    writeTerm(QByteArray(iEncoder.encode(chars)));
#else
    writeTerm(iTextCodec->fromUnicode(chars));
#endif
}

void PtyIFace::writeTerm(const QByteArray &chars)
{
    if (iChildExited)
        return;

    iWriteBuffer.append(chars);
    flushWriteBuffer();
}

void PtyIFace::flushWriteBuffer()
{
    while (!iWriteBuffer.isEmpty()) {
        const ssize_t ret = write(iMasterFd, iWriteBuffer.constData(), iWriteBuffer.size());
        if (ret > 0) {
            iWriteBuffer.remove(0, ret);
        } else if (ret == -1 && errno == EINTR) {
            continue;
        } else if (ret == -1 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            // the pty is full (e.g. a large paste), continue when it drains
            iWriteNotifier->setEnabled(true);
            return;
        } else {
            qWarning() << "PtyIFace: write failed:" << qt_error_string(errno);
            iWriteBuffer.clear();
        }
    }
    iWriteNotifier->setEnabled(false);
}

void PtyIFace::readTerm(QByteArray &chars)
{
    // read at most this much at a time, so that output floods do not starve the UI
    const int maxRead = 64 * 1024;
    char buf[4096];

    while (chars.size() < maxRead) {
        const ssize_t ret = read(iMasterFd, buf, sizeof(buf));
        if (ret > 0) {
            chars.append(buf, ret);
        } else if (ret == -1 && errno == EINTR) {
            continue;
        } else if (ret == -1 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            break;
        } else {
            // EOF, or EIO once the child has closed its end: nothing more will come
            iReadNotifier->setEnabled(false);
            break;
        }
    }
}
