QT += core gui testlib dbus
CONFIG += c++17 testcase
TARGET = celtic-audio_tests
INCLUDEPATH += ../src
HEADERS += ../src/backend.h ../src/theme.h ../src/translator.h
SOURCES += celtic-audio_tests.cpp ../src/backend.cpp ../src/theme.cpp ../src/translator.cpp
