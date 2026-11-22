QT += core gui testlib
CONFIG += console c++17
CONFIG -= app_bundle
TEMPLATE = app
TARGET = artemis_tests

include(../globaldefs.pri)

INCLUDEPATH += $$PWD/../app

SOURCES += \
    theme_test.cpp \
    ../app/backend/theme.cpp

HEADERS += \
    ../app/backend/theme.h

RESOURCES += \
    test.qrc
