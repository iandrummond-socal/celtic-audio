QT += quick quickcontrols2 webenginequick dbus
CONFIG += c++17
TARGET = celtic-audio
SOURCES += src/main.cpp src/backend.cpp src/theme.cpp src/translator.cpp
HEADERS += src/backend.h src/theme.h src/translator.h
RESOURCES += src/resources.qrc
