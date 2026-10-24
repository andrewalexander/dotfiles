# Portable zsh config, shared by mac and linux. Deployed as ~/.zshrc.shared.
#
# OS-specific bits live in .zshrc.mac / .zshrc.linux. zplug is not set up
# here: mac bootstraps it in .zshrc.mac, linux gets it from home-manager's
# programs.zsh.zplug module. This file is sourced after zplug has loaded,
# so the autosuggest bindkeys below work.

export PATH="$HOME/.local/bin:$PATH"

# go's protoc path
export PATH="$HOME/go/bin:$PATH"
export GOPRIVATE="github.com/helmet-sh/*"
export GOPATH=$HOME/go
# keep these around in case we ever run into proxy issues again
#export GOPROXY=direct
#export GOSUMDB=off

# source aliases and the like from .shellrc
source $HOME/.shellrc

# enable extended globbing for cfn-lint and other tools
setopt extended_glob

# VIM mode
export KEYTIMEOUT=20

bindkey -v
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins '^a' beginning-of-line
bindkey -M viins '^e' end-of-line
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward
#bindkey '^s' history-incremental-search-forward
bindkey -M vicmd 'H' beginning-of-line
bindkey -M vicmd 'L' end-of-line

# Use vim keys in tab complete menu:
#bindkey -M menuselect 'h' vi-backward-char
#bindkey -M menuselect 'k' vi-up-line-or-history
#bindkey -M menuselect 'l' vi-forward-char
#bindkey -M menuselect 'j' vi-down-line-or-history
#bindkey -v '^?' backward-delete-char

# Ctrl+Space accept autosuggestions
bindkey '^ ' autosuggest-accept

# Ctrl+Enter execute autosuggestions
# Requires terminal to rebind ctrl+enter to escape sequence
bindkey '^[M' autosuggest-execute

export AWS_DEFAULT_PROFILE=dev-admin
