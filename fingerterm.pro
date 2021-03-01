QT = core gui qml quick

CONFIG += link_pkgconfig

enable-feedback {
    QT += feedback
    DEFINES += HAVE_FEEDBACK
}

enable-nemonotifications {
    PKGCONFIG += nemonotifications-qt5
}

isEmpty(DEFAULT_FONT) {
    DEFAULT_FONT = monospace
}

isEmpty(DEPLOYMENT_PATH) {
    DEPLOYMENT_PATH = /usr/share/$$TARGET
}

DEFINES += DEPLOYMENT_PATH=\\\"$$DEPLOYMENT_PATH\\\"
DEFINES += DEFAULT_FONTFAMILY=\\\"$$DEFAULT_FONT\\\"

TEMPLATE = app
TARGET = fingerterm
DEPENDPATH += .
INCLUDEPATH += .
LIBS += -lutil

# Input
HEADERS += \
    ptyiface.h \
    terminal.h \
    textrender.h \
    version.h \
    util.h \
    keyloader.h

SOURCES += \
    main.cpp \
    terminal.cpp \
    textrender.cpp \
    ptyiface.cpp \
    util.cpp \
    keyloader.cpp

qml.files = qml/Main.qml \
    qml/Keyboard.qml \
    qml/Key.qml \
    qml/Lineview.qml \
    qml/Button.qml \
    qml/SectionHeader.qml \
    qml/MenuFingerterm.qml \
    qml/NotifyWin.qml \
    qml/UrlWindow.qml \
    qml/LayoutWindow.qml \
    qml/AboutWindow.qml \
    qml/PopupWindow.qml
qml.path = $$DEPLOYMENT_PATH
INSTALLS += qml

RESOURCES += \
    resources.qrc

icons.files = icons/backspace.png \
    icons/down.png \
    icons/enter.png \
    icons/left.png \
    icons/menu.png \
    icons/right.png \
    icons/scroll-indicator.png \
    icons/shift.png \
    icons/tab.png \
    icons/up.png
icons.path = $$DEPLOYMENT_PATH/icons
INSTALLS += icons

userdata.files = data/menu.xml \
    data/english.layout \
    data/finnish.layout \
    data/french.layout \
    data/german.layout \
    data/qwertz.layout
userdata.path = $$DEPLOYMENT_PATH/data
INSTALLS += userdata

desktopfile.path = /usr/share/applications
desktopfile.files = $${TARGET}.desktop

# translations
TS_FILE = $$OUT_PWD/fingerterm.ts
EE_QM = $$OUT_PWD/fingerterm_eng_en.qm

ts.commands += lupdate $$PWD -ts $$TS_FILE
ts.CONFIG += no_check_exist
ts.output = $$TS_FILE
ts.input = .

ts_install.files = $$TS_FILE
ts_install.path = /usr/share/translations/source
ts_install.CONFIG += no_check_exist

# should add -markuntranslated "-" when proper translations are in place (or for testing)
engineering_english.commands += lrelease -idbased $$TS_FILE -qm $$EE_QM
engineering_english.CONFIG += no_check_exist
engineering_english.depends = ts
engineering_english.input = $$TS_FILE
engineering_english.output = $$EE_QM

TRANSLATIONS_PATH = /usr/share/translations
engineering_english_install.path = $$TRANSLATIONS_PATH
engineering_english_install.files = $$EE_QM
engineering_english_install.CONFIG += no_check_exist

DEFINES += TRANSLATIONS_PATH=\"\\\"\"$${TRANSLATIONS_PATH}\"\\\"\"

QMAKE_EXTRA_TARGETS += ts engineering_english
PRE_TARGETDEPS += ts engineering_english

target.path = /usr/bin
INSTALLS += target desktopfile ts_install engineering_english_install

DISTFILES += \
    data/* \
    icons/*.png \
    qml/*.qml \
    rpm/fingerterm.spec
