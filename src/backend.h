#pragma once
#include <QObject>
#include <QVariantMap>
#include <QDBusAbstractAdaptor>
#include <QDBusObjectPath>
class Backend : public QObject {
 Q_OBJECT
 Q_PROPERTY(QString status READ status NOTIFY changed)
 Q_PROPERTY(bool available READ available NOTIFY changed)
 Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY changed)
 Q_PROPERTY(QString error READ error NOTIFY changed)
public:
 Backend();
 QString status() const { return m_status; }
 bool available() const { return m_available; }
 double volume() const { return m_volume; }
 QString error() const { return m_error; }
 void setVolume(double v);
 Q_INVOKABLE void update(bool available, bool playing);
 Q_INVOKABLE void command(const QString &action);
 QVariantMap metadata() const;
signals:
 void changed();
 void actionRequested(QString action);
 void volumeRequested(double volume);
 void raiseRequested();
private:
 QString m_status="Stopped", m_error;
 bool m_available=false;
 double m_volume=1;
 void publish();
};
class RootAdaptor : public QDBusAbstractAdaptor {
 Q_OBJECT
 Q_CLASSINFO("D-Bus Interface", "org.mpris.MediaPlayer2")
 Q_PROPERTY(bool CanQuit READ yes CONSTANT)
 Q_PROPERTY(bool CanRaise READ yes CONSTANT)
 Q_PROPERTY(bool HasTrackList READ no CONSTANT)
 Q_PROPERTY(QString Identity READ identity CONSTANT)
 Q_PROPERTY(QString DesktopEntry READ desktop CONSTANT)
 Q_PROPERTY(QStringList SupportedUriSchemes READ empty CONSTANT)
 Q_PROPERTY(QStringList SupportedMimeTypes READ empty CONSTANT)
public:
 RootAdaptor(Backend *b):QDBusAbstractAdaptor(b),b(b){}
 bool yes() const{return true;} bool no() const{return false;}
 QString identity() const{return "Celtic Audio";} QString desktop() const{return "celtic-audio";}
 QStringList empty() const{return {};}
public slots:
 void Raise(){emit b->raiseRequested();}
 void Quit();
private: Backend *b;
};
class PlayerAdaptor : public QDBusAbstractAdaptor {
 Q_OBJECT
 Q_CLASSINFO("D-Bus Interface", "org.mpris.MediaPlayer2.Player")
 Q_PROPERTY(QString PlaybackStatus READ status)
 Q_PROPERTY(double Rate READ rate WRITE setRate)
 Q_PROPERTY(QVariantMap Metadata READ metadata)
 Q_PROPERTY(double Volume READ volume WRITE setVolume)
 Q_PROPERTY(qlonglong Position READ position)
 Q_PROPERTY(double MinimumRate READ rate CONSTANT)
 Q_PROPERTY(double MaximumRate READ rate CONSTANT)
 Q_PROPERTY(bool CanGoNext READ no CONSTANT)
 Q_PROPERTY(bool CanGoPrevious READ no CONSTANT)
 Q_PROPERTY(bool CanPlay READ available)
 Q_PROPERTY(bool CanPause READ available)
 Q_PROPERTY(bool CanSeek READ no CONSTANT)
 Q_PROPERTY(bool CanControl READ yes CONSTANT)
public:
 PlayerAdaptor(Backend *b):QDBusAbstractAdaptor(b),b(b){}
 QString status()const{return b->status();} double rate()const{return 1;}
 void setRate(double){} QVariantMap metadata()const{return b->metadata();}
 double volume()const{return b->volume();} void setVolume(double v){b->setVolume(v);}
 qlonglong position()const{return 0;} bool no()const{return false;} bool yes()const{return true;}
 bool available()const{return b->available();}
public slots:
 void Play(){b->command("play");} void Pause(){b->command("pause");}
 void PlayPause(){b->command("toggle");} void Stop(){b->command("stop");}
 void Next(){} void Previous(){} void Seek(qlonglong){}
 void SetPosition(const QDBusObjectPath &, qlonglong){} void OpenUri(const QString &){}
private: Backend *b;
};
