init-nix:

sync-nixos:
	sudo cp nixos-configuration.nix /etc/nixos/configuration.nix
	sudo mkdir -p /etc/nixos/patches
	sudo cp patches/*.patch /etc/nixos/patches/

sync-darwin:
	sudo cp configuration.nix /etc/nix-darwin/configuration.nix

sync-home-linux:
	cp nixos-home.nix ~/.config/home-manager/home.nix

sync-home-mac:
	cp home.nix ~/.config/home-manager/home.nix

sync-linux: sync-nixos sync-home-linux

sync-mac: sync-darwin sync-home-mac

install:
	@stow -vS --no-folding config
	@fc-cache

clean:
	@stow -vD --no-folding config

init:
	yay -Sy rustup cmake stow extra/zip extra/fontconfig gvim tailscale ncat extra/nmap bind core/net-tools tilt-bin minikube extra/helm extra/docker ctlptl-bin extra/jq extra/aws-cli-v2 extra/dbeaver extra/nodejs-lts-jod nvm
	rustup default stable

init-mac: 
	curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --no-daemon
	sudo nix-channel --add https://github.com/nix-darwin/nix-darwin/archive/master.tar.gz darwin
	sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
	sudo nix-channel --update
	nix-shell '<home-manager>' -A install
	home-manager switch

	#curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
	#source "$HOME/.cargo/env"
	#brew install stow cmake exa tmux koekeishiya/formulae/yabai skhd
	#skhd --start-service
	#yabai --start-service
	#rustup default stable
	#curl -sSfL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
	#cargo install starship

plugins:
	git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting


