#!/bin/sh

killall picom
picom --config $HOME/.config/picom/picom.conf > $HOME/.config/picom/picom.log
