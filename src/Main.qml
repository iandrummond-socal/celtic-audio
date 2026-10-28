import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtWebEngine

ApplicationWindow {
 id: win
 width: 1040; height: 800
 minimumWidth: 600; minimumHeight: pageVisible ? 500 : 310
 visible: true; title: "Celtic Audio"; color: "#101513"
 Material.theme: Material.Dark
 Material.accent: theme.accent
 Material.roundedScale: theme.radius
 onClosing: function(close) { close.accepted = false; win.hide() }
 property bool pageVisible: true
 property string loadError: ""
 property bool helpVisible: false
 property var selectedFrame: null
 property int generation: 0
 property bool polling: false
 function frames(frame) {
  let result = [frame]
  for (const child of frame.children) result = result.concat(frames(child))
  return result
 }
 function poll() {
  if(polling || web.loading) return
  polling = true
  const serial = generation
  const all = frames(web.mainFrame)
  let pending = all.length, best = null, playing = false
  if(!pending) {polling=false;return}
  for(const frame of all) frame.runJavaScript(`(() => {
   const media = Array.from(document.querySelectorAll('audio,video')).filter(m => m.currentSrc || m.srcObject);
   return {available:media.length>0, playing:media.some(m=>!m.paused&&!m.ended)};
  })()`, 1, function(state) {
   if(serial!==generation) return
   if(state && state.available && (!best || state.playing)) best=frame
   if(state && state.playing) playing=true
   if(--pending===0){ selectedFrame=best;backend.update(best!==null,playing);polling=false }
  })
 }
 function action(name) {
  if(!selectedFrame || !selectedFrame.isValid) return
  applyVolume(backend.volume)
  const verb = name === "toggle" ? (backend.status === "Playing" ? "pause" : "play") : name
  selectedFrame.runJavaScript(`(() => {
   const media=Array.from(document.querySelectorAll('audio,video')).filter(m=>m.currentSrc||m.srcObject);
   const m=media.find(m=>!m.paused&&!m.ended)||media[0]; if(!m)return;
   if(${JSON.stringify(verb)}==='play') m.play().catch(()=>{}); else m.pause();
  })()`,1,function(){poll()})
 }
 function applyVolume(v) {
  for(const frame of frames(web.mainFrame)) frame.runJavaScript(
   "document.querySelectorAll('audio,video').forEach(m=>{m.volume="+v+";m.muted=false})",1,function(){})
 }
 Connections {
  target: backend
  function onActionRequested(name){win.action(name)}
  function onVolumeRequested(v){win.applyVolume(v)}
  function onRaiseRequested(){win.showNormal();win.raise();win.requestActivate()}
 }
 Shortcut {sequence:"Space";enabled:!win.pageVisible;context:Qt.ApplicationShortcut;onActivated:backend.command("toggle")}
 Shortcut {sequence:"Q";enabled:!win.pageVisible;context:Qt.ApplicationShortcut;onActivated:Qt.quit()}
 Shortcut {sequence:"?";enabled:!win.pageVisible;context:Qt.ApplicationShortcut;onActivated:win.helpVisible=!win.helpVisible}
 Shortcut {sequence:"Ctrl+Q";context:Qt.ApplicationShortcut;onActivated:Qt.quit()}
 Shortcut {sequence:"Ctrl+L";context:Qt.ApplicationShortcut;onActivated:win.pageVisible=!win.pageVisible}
 WebEngineProfile {
  id: profile
  storageName:"celtic-player"
  offTheRecord:false
  persistentCookiesPolicy:WebEngineProfile.AllowPersistentCookies
 }
 Item {
  anchors.fill:parent
  LayoutMirroring.enabled:Qt.application.layoutDirection===Qt.RightToLeft
  LayoutMirroring.childrenInherit:true
  ColumnLayout {
   anchors.fill:parent;anchors.margins:20;spacing:12
   RowLayout {
    Layout.fillWidth:true
    ColumnLayout {
     Label {text:"CELTIC AUDIO";font.pixelSize:22;font.bold:true;color:theme.accent}
     Label {text: backend.status==="Playing" ? qsTr("Playing CelticPlayer") : backend.available ? qsTr("Paused") : qsTr("Choose a stream on CelticPlayer");color:"#b6c3ba"}
    }
    Item {Layout.fillWidth:true}
    Button {text:win.pageVisible?qsTr("Compact player"):qsTr("CelticPlayer");onClicked:{win.pageVisible=!win.pageVisible;win.height=win.pageVisible?800:330}}
    Button {text:qsTr("Help");onClicked:win.helpVisible=true}
   }
   RowLayout {
    Button {text:backend.status==="Playing"?qsTr("Pause"):qsTr("Play");enabled:backend.available;highlighted:true;onClicked:backend.command("toggle")}
    Button {text:qsTr("Stop");enabled:backend.available;onClicked:backend.command("stop")}
    Label {text:qsTr("Volume")}
    Slider {Layout.fillWidth:true;from:0;to:1;value:backend.volume;onMoved:backend.volume=value;Accessible.name:qsTr("Volume")}
    Label {text:(backend.volume*100).toLocaleString(Qt.locale(), 'f', 0)+"%"}
   }
   Label {Layout.fillWidth:true;visible:backend.error!=="";text:backend.error;color:"#ffb4ab";wrapMode:Text.Wrap}
   Label {Layout.fillWidth:true;visible:win.loadError!=="";text:win.loadError;color:"#ffb4ab";wrapMode:Text.Wrap}
   RowLayout {
    visible:win.pageVisible
    Button {text:qsTr("Back");enabled:web.canGoBack;onClicked:web.goBack()}
    Button {text:qsTr("Reload");onClicked:web.reload()}
    Button {text:qsTr("Home");onClicked:web.url="https://player.celticfc.com/"}
    Label {text:web.loading?qsTr("Loading…"):web.recentlyAudible?qsTr("Audio detected"):qsTr("CelticPlayer");Layout.fillWidth:true}
   }
   Item {
    Layout.fillWidth:true;Layout.fillHeight:true
    WebEngineView {
     id:web;anchors.fill:parent
     // Keep the page active in compact mode so background playback continues.
     opacity:win.pageVisible?1:0
     enabled:win.pageVisible
     profile:profile
     lifecycleState:WebEngineView.Active
     url:testMedia?"qrc:/test.html":"https://player.celticfc.com/"
     settings.playbackRequiresUserGesture:!testMedia
     onNewWindowRequested:function(request){request.openIn(web)}
     onJavaScriptConsoleMessage:function(level,message,line,source){}
     onLoadingChanged:function(info){
      if(info.status===WebEngineView.LoadStartedStatus){win.generation++;win.polling=false;win.selectedFrame=null;backend.update(false,false);win.loadError=""}
      if(info.status===WebEngineView.LoadFailedStatus) win.loadError=qsTr("CelticPlayer could not load. Check your connection and reload.")
      if(info.status===WebEngineView.LoadSucceededStatus){win.applyVolume(backend.volume);win.poll()}
     }
    }
    Label {anchors.centerIn:parent;visible:!win.pageVisible;text:qsTr("Desktop media keys control playback.\nClosing the window keeps audio in the top bar.");horizontalAlignment:Text.AlignHCenter;color:"#b6c3ba"}
   }
  }
 }
 Timer {interval:750;running:true;repeat:true;onTriggered:win.poll()}
 Popup {
  anchors.centerIn:parent;width:Math.min(520,win.width-40);modal:true
  visible:win.helpVisible;onClosed:win.helpVisible=false
  contentItem:Label {text:qsTr("Select and start commentary on CelticPlayer, then switch to the compact player.\n\nSpace — Play / pause (compact view)\nCtrl+L — Toggle CelticPlayer\n? — Help (compact view)\nQ — Quit (compact view)\nCtrl+Q — Quit\n\nDesktop media controls work in either view. Stop pauses the live stream; Play resumes using the website’s live-stream behavior.");wrapMode:Text.Wrap;padding:16}
 }
}
