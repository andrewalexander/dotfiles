#!/usr/bin/env bash

# makes the lock screen a fuzzy/corrupted version of the current screen
tmpbg="$HOME/gotem.png"
#scrot "$tmpbg"; 
#i3lock -i "$tmpbg"; rm "$tmpbg"; setxkbmap -option ctrl:nocaps # ensure caps lock is still ctrl
#scrot "$tmpbg"
#corrupter -mag 3 -boffset 5 "$tmpbg" "$tmpbg" 
scrot "$tmpbg"; corruster "$tmpbg" "$tmpbg"
i3lock -i "$tmpbg"; setxkbmap -option ctrl:nocaps # ensure caps lock is still ctrl
