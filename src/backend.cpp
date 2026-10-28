#include "backend.h"
#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <cmath>
Backend::Backend(){
 new RootAdaptor(this); new PlayerAdaptor(this);
 auto bus=QDBusConnection::sessionBus();
 if(!bus.registerService("org.mpris.MediaPlayer2.celtic_audio") || !bus.registerObject("/org/mpris/MediaPlayer2",this,QDBusConnection::ExportAdaptors))
  m_error=tr("Desktop media controls are unavailable. Another Celtic Audio instance may be running.");
}
void RootAdaptor::Quit(){QCoreApplication::quit();}
QVariantMap Backend::metadata()const{
 if(!m_available)return {};
 return {{"mpris:trackid",QVariant::fromValue(QDBusObjectPath("/org/mpris/MediaPlayer2/track/current"))},{"xesam:title",QString("CelticPlayer audio")},{"xesam:artist",QStringList{"Celtic FC"}}};
}
void Backend::publish(){
 emit changed();
 auto msg=QDBusMessage::createSignal("/org/mpris/MediaPlayer2","org.freedesktop.DBus.Properties","PropertiesChanged");
 msg << QString("org.mpris.MediaPlayer2.Player") << QVariantMap{{"PlaybackStatus",m_status},{"Volume",m_volume},{"Metadata",metadata()},{"CanPlay",m_available},{"CanPause",m_available}} << QStringList{};
 QDBusConnection::sessionBus().send(msg);
}
void Backend::update(bool available,bool playing){
 const QString next=!available?"Stopped":playing?"Playing":"Paused";
 if(next==m_status && available==m_available)return;
 m_available=available; m_status=next;publish();
}
void Backend::setVolume(double v){
 if(!std::isfinite(v))return;
 v=qBound(0.0,v,1.0);if(qFuzzyCompare(v+1,m_volume+1))return;
 m_volume=v;emit volumeRequested(v);publish();
}
void Backend::command(const QString &action){
 if(!m_available)return;
 if(action=="play"||action=="pause"||action=="toggle"||action=="stop")emit actionRequested(action);
}
