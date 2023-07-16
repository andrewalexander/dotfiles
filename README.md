# dotfiles

## Pre-requisite for Mac

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

Notes:
- Uses the arch gvim package even for vim so that it gets compiled with `+clipboard` and can use the system clipboard.
- Uses stow to create symlinks of everything


