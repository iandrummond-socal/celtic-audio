import QtQuick
import Quickshell.Services.Mpris
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
 id: root
 moduleName: "icd.celtic-audio"
 readonly property var player: {
  var players = Mpris.players ? Mpris.players.values : []
  for (var i=0;i<players.length;i++)
   if(players[i].dbusName === "org.mpris.MediaPlayer2.celtic_audio") return players[i]
  return null
 }
 property bool opened: false
 function open(){opened=true}
 function close(){opened=false}
 function showPlayer(){
  if(player) player.raise()
  else if(bar) bar.run("celtic-audio --show")
  close()
 }
 implicitWidth: button.implicitWidth
 implicitHeight: button.implicitHeight
 Commons.Translations {id: strings;directory:Qt.resolvedUrl("i18n")}
 BarIconButton {
  id: button
  anchors.fill:parent
  bar:root.bar
  text:"󰋋"
  active:!!root.player && root.player.isPlaying
  tooltipText:strings.t("tooltip")
  onPressed:function(b){
   if(b===Qt.MiddleButton){if(root.player && root.player.canTogglePlaying)root.player.togglePlaying()}
   else root.opened=!root.opened
  }
 }
 PopupCard {
  anchorItem:button
  bar:root.bar
  owner:root
  open:root.opened
  contentWidth:fittedContentWidth(Style.space(280))
  contentHeight:fittedContentHeight(column.implicitHeight)
  Column {
   id:column
   width:parent.width
   spacing:Style.space(12)
   Text {text:"Celtic Audio";textFormat:Text.PlainText;color:root.bar.foreground;font.family:root.bar.fontFamily;font.pixelSize:Style.font.subtitle;font.bold:true}
   Text {
    width:parent.width;wrapMode:Text.Wrap;textFormat:Text.PlainText
    text:!root.player?strings.t("closed"):root.player.isPlaying?strings.t("playing"):strings.t("ready")
    color:root.bar.foreground;font.family:root.bar.fontFamily;font.pixelSize:Style.font.body
   }
   Button {text:strings.t("open");foreground:root.bar.foreground;onClicked:root.showPlayer()}
   Button {
    text:root.player && root.player.isPlaying?strings.t("pause"):strings.t("play")
    foreground:root.bar.foreground
    enabled:!!root.player && root.player.canTogglePlaying
    opacity:enabled?1:0.4
    onClicked:if(root.player)root.player.togglePlaying()
   }
   Button {
    text:strings.t("quit");foreground:root.bar.foreground
    enabled:!!root.player;opacity:enabled?1:0.4
    onClicked:{if(root.player)root.player.quit();root.close()}
   }
  }
 }
}
