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

#ifndef PTYIFACE_H
#define PTYIFACE_H

#include <QObject>
#include <QSocketNotifier>
#include <QByteArray>
#include <QSize>
#include <QScopedPointer>
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
#include <QStringDecoder>
#include <QStringEncoder>
#else
#include <QTextCodec>
#endif

class Terminal;

class PtyIFace : public QObject
{
    Q_OBJECT
public:
    explicit PtyIFace(int pid, int masterFd, Terminal *term, QString charset, QObject *parent = 0);
    virtual ~PtyIFace();

    void writeTerm(const QString &chars);
    bool failed() const { return iFailed; }

private slots:
    void resize(int rows, int columns);
    void readActivated();
    void flushWriteBuffer();
    void childStateChanged();

private:
    Q_DISABLE_COPY(PtyIFace)

    void writeTerm(const QByteArray &chars);
    void readTerm(QByteArray &chars);

    Terminal *iTerm;
    int iPid;
    int iMasterFd;
    bool iFailed;
    bool iChildExited;

    QSocketNotifier *iReadNotifier;
    QSocketNotifier *iWriteNotifier;
    QSocketNotifier *iChildNotifier;
    QByteArray iWriteBuffer;

#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    QStringDecoder iDecoder;
    QStringEncoder iEncoder;
#else
    QTextCodec *iTextCodec;
    QScopedPointer<QTextDecoder> iDecoder;
#endif
};

#endif // PTYIFACE_H
