# dotfiles

## Pre-requisite for Mac

Install Firefox

Install [homebrew](https://brew.sh) to install git and clone this repo

```
curl -sSfL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | sh
eval "$(/usr/local/bin/brew shellenv)"
brew install git
git clone https://github.com/andrewalexander/dotfiles
```

Install [alacritty](https://alacritty.org/) or [iTerm](https://iterm2.com/index.html) for terminal

## Installation
```
# make init # for linux
make init-mac # for mac
make install
make plugins
```

## Trackpad scroll direction
For some reason the magic trackpad didn't respect the settings in the UI. Adding this to `/etc/X11/xorg.conf.d/30-touchpad.conf` made it work and persist

```
Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "NaturalScrolling" "false"
EndSection
```

## Notes
Uses the arch gvim package even for vim so that it gets compiled with `+clipboard` and can use the system clipboard which alacritty is also configured to share.

Uses stow to create symlinks of everything in `config/` to `~/`

## Further customization for mac
System Settings we can't necessarily automate (or can we? 🤔). We usually won't have to do this unless it's a brand new mac or a truly fresh install. 

Even if a Security Response breaks our install on an out of support mac, we can always re-install the OS using our recovery drive via the OpenCore Legacy Patcher [USB Boot Drive](https://dortania.github.io/OpenCore-Legacy-Patcher/BOOT.html) we will keep around (or create in a pinch).
- it is unclear if re-installing macos via the recovery partition will install the last officially supported macOS version apple released for the hardware or if it will use the version installed with Open Core Legacy Patcher. Rather than find out the last time around, I just used the USB drive to do a clean Mojave install (Disk Utiliy -> Erase Macintosh HD before installing Mojave).

### General
#### Software Update
Automatic Updates
-> Install macOS updates: Disabled
-> Install App store updates: Disabled
-> Install Security Responses: Disabled - one of the more recent ones made the mac unbootable and i had to reinstall; even after removing it it would hang after the keyboard's backlight would turn on

#### Airdrop
Disable

### Appearance
Dark
Highlight Color: Purple

Show Scroll bars: Always
Click in the scroll bar to: Jump to the spot that's clicked

### Accessibility
#### Pointer Control
Trackpad Options... 
-> Use trackpad for dragging: Enabled
-> Dragging Style: Three Finger Drag

### Control Center
Wifi: Don't Show
Bluetooth: Don't Show
AirDrop: Don't Show
Focus: Active
Stage Manager: Don't Show
Screen Recording: Active
Display: Active
Sound: Always
Now Playing: Don't Show

Battery 
-> Show in menu bar: Enabled
-> Show Percentage: Enabled

Clock Options...
-> Show Day of the week
-> Use 24 hour
-> Display time with seconds

Spotlight: Don't Show
Siri: Don't Show

### Siri & Spotlight
Disable Ask Siri

Unselect:
- Events & Reminders
- Fonts
- Siri Suggestions
- Tips

### Privacy & Security
#### Location Services
Off

### Desktop & Dock
Size: Second to smallest
Minimize windows into application icon

Recent documents: 5

Prefer tabs when opening docs: Always

Stage Manager: Disabled

Default Browser: Firefox

### Screen Saver
Shifting Tiles w/ default colors

### Lock Screen
Screen Saver: 5 mins
Display off on battery: after 2 mins
Display off AC power: 20 mins
Require password: 15 mins

Login window shows: Name and password
Show sleep, restart, and shutdown buttons

### Keyboard
Re-map modifier keys: Keyboard -> Keyboard Shortcuts -> Modifier Keys on the left nav
- caps lock is control on both keyboards
- for external keyboard, swap option and command

update key repeat rate to fastest available; delay until repeat at second to shortest

### Trackpad
#### Point & Click
Force Click and Haptic feedback off (with old mac, irrelevant/not functional)
Look up and data detectors off
Secondary Click: Click or Tap with Two Fingers
Tap to click enabled

#### Scroll & Zoom
Natural scrolling off
zoom in or out on
smart zoom off
rotate on

#### More Gestures 

Swipe between apps with 4 fingers
Mission Control and App Expose use 4 fingers
Disable Launchpad
Disable Show Desktop

### Set up Printer
Just add it :D


