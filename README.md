# Celtic Audio

![Celtic Audio playback test](test-preview.png)

A native Qt Quick app for listening to CelticPlayer on Omarchy, with MPRIS
play/pause, stop, volume and raise-window controls. Unofficial personal utility;
requires your own CelticPlayer account and access to the selected stream.

## Use

Launch **Celtic Audio** from Super+Space, or run `celtic-audio`.
Sign in on the official CelticPlayer page and start a stream. Switch to
**Compact player** for the native listening view. Playback continues while the
window is minimized or closed. Closing hides the window; Quit ends playback.

A headphone button sits immediately beside the Elsewhen world clock. Click it
for Open player, Play/Pause and Quit Celtic Audio. Middle-click toggles playback.
The button remains available when the app is not running and can launch it.
Reopening from the launcher raises the existing player rather than starting
a second instance. The installed user widget is backed by the source in
`omarchy/icd.celtic-audio/`; its layout entry is in Omarchy shell.json.

The app uses a separate persistent WebEngine profile, so sign in once even if
you already signed in to the earlier probe. Website cookies control session
expiry. The app does not save your password separately or log page console data.
The site remains responsible for subscription access, authentication and DRM.

| Shortcut | Action |
| --- | --- |
| Space | Play/pause in compact view |
| Ctrl+L | Toggle website/compact view |
| ? | Show help in compact view |
| Q | Quit in compact view |
| Ctrl+Q | Quit in either view |

MPRIS service: `org.mpris.MediaPlayer2.celtic_audio`.
For an explicitly targeted command, if playerctl is installed:
`playerctl --player=celtic_audio play-pause`.

Stop pauses the media element without seeking; live-stream resume behavior is
controlled by CelticPlayer. Seek, skip, and playback speed are unavailable.
The desktop metadata uses a generic CelticPlayer title. Stream selection stays
on the official page; compact mode does not convert video streams to audio-only.
Start playback on the site once so the browser's user-gesture requirement is met.

The shell follows Omarchy's accent, window rounding and language selection live.
English and a partial Danish catalog are included; missing translations fall
back to English. CelticPlayer's own interface is controlled by the site.
The widget installer updates only its own entry in your Omarchy bar layout;
existing widgets and settings are preserved, with backups made before changes.

## Install on Omarchy

Requires **Arch-based Omarchy with the Quickshell bar**, an internet connection,
and sudo access for package installation. The older Waybar-based Omarchy bar
is not supported. You also need a CelticPlayer subscription with access to the
stream you select.

Open a terminal and run:

```sh
sudo pacman -S --needed git
git clone https://github.com/iandrummond-socal/celtic-audio.git
cd celtic-audio
./bin/install
```

Run the installer as your normal desktop user, **without sudo**. It asks for
sudo when installing packages. Review and accept the pacman prompts.

The installer:

1. Installs the build tools and Python, then lets `makepkg` install the required
   Qt dependencies and build/install the `celtic-audio` Arch package.
2. Copies the included menu bar widget into your user Omarchy plugin directory.
3. Places its headphone button immediately after **Elsewhen**, the world clock.
   If Elsewhen is absent, the button goes at the start of `centerEnd`, beside
   the center clock. Existing widgets keep their settings and relative order.
4. Backs up your bar configuration and any previous copy of this widget under
   `~/.config/omarchy/celtic-audio-backups/` before making changes. Custom
   `XDG_CONFIG_HOME` locations are supported.

The bar reloads automatically. Click the **headphone icon → Open player**, sign
in on CelticPlayer, and start commentary. You can close the player window and
keep listening. Use **Quit Celtic Audio** in the bar popup to stop the app.
The icon is available after login; it launches the player on demand.

### Update

From your cloned repository:

```sh
git pull --ff-only
./bin/install
```

Quit the running app from its bar popup before updating, then reopen it.
Repeating the installer updates the widget without adding duplicate bar icons.
It replaces the widget's files, so keep any personal widget changes separately;
the installer also saves the previous copy in its backup directory.

### Repair or remove the bar widget

To reinstall just the widget and its layout entry without rebuilding the app:

```sh
./bin/install-widget
```

To uninstall:

```sh
./bin/install-widget --remove
sudo pacman -R celtic-audio
```

Quit the app first. Removal affects only this widget and its bar entries.
Your CelticPlayer profile and installer backups are retained. The profile lives
in Qt's standard application data/cache locations under `LocalTools/celtic-audio`.
If widget setup fails after the package installed, correct the reported issue
and rerun `./bin/install-widget`. Invalid bar JSON is left untouched.

### Build or test without installing

```sh
./bin/build
./bin/test
```

Dependencies are listed in `pkgbuild/PKGBUILD`; tests also need Python 3.
The source requires Qt WebEngine 6.8 or newer. Build artifacts stay in `build/`.

## Validation

- Eight installer tests cover preservation, backups, repeat installs, removal,
  missing world clocks, malformed configuration and symlink protection.
- Seven Qt Test checks pass, covering observed playback state, command gating,
  volume bounds, theme loading and Danish translation.
- Exercised actual D-Bus Play, Pause, PlayPause, Stop and Volume against local
  audio in an embedded frame. Observed Playing/Paused transitions from the
  media element, rather than assuming a command succeeded.
- Visually inspected the real QML window using the bundled synthetic audio page.
- Earlier Qt WebEngine probe: user confirmed CelticPlayer audio playback.
- Version 0.2: visually verified the bar icon and popup beside Elsewhen.
- Final installed app: real CelticPlayer media controls still need user testing
  after sign-in. Website changes, shadow-DOM media or unusual player internals
  may require adapting the frame media detection.

`./build/celtic-audio --test-media` opens the bundled local audio fixture and
writes `test-preview.png` after four seconds. This mode allows programmatic
playback for testing; normal mode requires an initial user gesture.

Theme/translation helpers follow the Omarchy app templates; see LICENSE.
