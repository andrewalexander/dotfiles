# homebrew pkgs in path + completion for zsh
export PATH="$HOME/.local/bin:$PATH"
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# go's protoc path
export PATH="$HOME/go/bin:$PATH"
export GOPRIVATE="github.com/helmet-sh/*"
export GOPATH=$HOME/go
# keep these around in case we ever run into proxy issues again
#export GOPROXY=direct
#export GOSUMDB=off

# nvm's path + completion
export NVM_DIR="$HOME/.nvm" # without this, we lose our stuff every upgrade 
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# rust's path
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

# source aliases and the like from .shellrc
source $HOME/.shellrc

# enable extended globbing for cfn-lint and other tools
setopt extended_glob

# plugins
source ~/.zplug/init.zsh

zplug "zsh-users/zsh-autosuggestions" 

#plugins=(
  #archlinux
  #aws
  #colored-man-pages
  #git
  #history-substring-search
  #kubectl
  #vi-mode
  #zsh-autosuggestions
  #zsh-navigation-tools
  #zsh-syntax-highlighting
#
#
## Grab binaries from GitHub Releases
# and rename with the "rename-to:" tag
#zplug "junegunn/fzf", \
    #from:gh-r, \
    #as:command, \
    #use:"*darwin*amd64*"
#
## Supports oh-my-zsh plugins and the like
#zplug "plugins/git",   from:oh-my-zsh

# load them after we zplug them
#zplug load --verbose
zplug load 

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
