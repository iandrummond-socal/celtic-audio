#include <QtTest>
#include <QTemporaryDir>
#include <QFile>
#include "backend.h"
#include "theme.h"
#include "translator.h"
class PlayerTests:public QObject {
 Q_OBJECT
private slots:
 void reportsObservedPlayback(){Backend b;b.update(true,true);QCOMPARE(b.status(),QString("Playing"));b.command("pause");QCOMPARE(b.status(),QString("Playing"));b.update(true,false);QCOMPARE(b.status(),QString("Paused"));b.update(false,false);QCOMPARE(b.status(),QString("Stopped"));QVERIFY(b.metadata().isEmpty());}
 void commandsRequireMedia(){Backend b;QSignalSpy actions(&b,&Backend::actionRequested);b.command("play");QCOMPARE(actions.count(),0);b.update(true,false);b.command("toggle");QCOMPARE(actions.count(),1);b.command("invalid");QCOMPARE(actions.count(),1);}
 void volumeIsFiniteAndBounded(){Backend b;b.setVolume(-3);QCOMPARE(b.volume(),0.0);b.setVolume(7);QCOMPARE(b.volume(),1.0);b.setVolume(qQNaN());QCOMPARE(b.volume(),1.0);}
 void followsTheme(){QTemporaryDir d;QDir(d.path()).mkdir("theme");QFile f(d.path()+"/theme/colors.toml");QVERIFY(f.open(QIODevice::WriteOnly));f.write("accent = \"#abcdef\"\n");f.close();Theme t(d.path());QCOMPARE(t.accent(),QString("#abcdef"));}
 void translatesDanish(){QTemporaryDir d;QFile f(d.path()+"/language");QVERIFY(f.open(QIODevice::WriteOnly));f.write("da\n");f.close();Translator t(d.path()+"/language",QFINDTESTDATA("../src/i18n"));QCOMPARE(t.translate("Main","Volume"),QString("Lydstyrke"));}
};
QTEST_MAIN(PlayerTests)
#include "celtic-audio_tests.moc"
