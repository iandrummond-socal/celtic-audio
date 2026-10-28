#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>
#include <QIcon>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusInterface>
#include <QtWebEngineQuick/qtwebenginequickglobal.h>
#include "backend.h"
#include "theme.h"
#include "translator.h"
int main(int argc,char **argv){
 QtWebEngineQuick::initialize();
 QGuiApplication app(argc,argv);
 app.setApplicationName("celtic-audio");app.setOrganizationName("LocalTools");
 app.setQuitOnLastWindowClosed(false);
 app.setApplicationVersion("0.2.0");app.setDesktopFileName("celtic-audio");
 app.setWindowIcon(QIcon(":/icon.svg"));QQuickStyle::setStyle("Material");
 // Reopening from the launcher restores the existing player and its session.
 if(QDBusConnection::sessionBus().interface()->isServiceRegistered("org.mpris.MediaPlayer2.celtic_audio")){
  QDBusInterface existing("org.mpris.MediaPlayer2.celtic_audio","/org/mpris/MediaPlayer2","org.mpris.MediaPlayer2");
  existing.call("Raise");return 0;
 }
 Translator translator;app.installTranslator(&translator);Theme theme;Backend backend;
 QQmlApplicationEngine engine;
 QObject::connect(&translator,&Translator::changed,&engine,&QQmlEngine::retranslate);
 engine.rootContext()->setContextProperty("theme",&theme);
 engine.rootContext()->setContextProperty("translator",&translator);
 engine.rootContext()->setContextProperty("backend",&backend);
 const bool test=app.arguments().contains("--test-media");
 engine.rootContext()->setContextProperty("testMedia",test);
 engine.load(QUrl("qrc:/Main.qml"));if(engine.rootObjects().isEmpty())return 1;
 if(test) QTimer::singleShot(4000,&app,[&]{auto w=qobject_cast<QQuickWindow*>(engine.rootObjects().first());if(w)w->grabWindow().save("test-preview.png");});
 return app.exec();
}
