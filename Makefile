# Plain `make` does nothing: every real target names the machine it syncs.
all:

sync-nixos:
	sudo cp nixos-configuration.nix /etc/nixos/configuration.nix
	sudo cp nixos-common.nix /etc/nixos/nixos-common.nix
	sudo mkdir -p /etc/nixos/patches
	sudo cp patches/*.patch /etc/nixos/patches/
	sudo rm -rf /etc/nixos/pkgs
	sudo cp -r pkgs /etc/nixos/pkgs

sync-home-linux:
	cp nixos-home.nix ~/.config/home-manager/home.nix
	cp home-common.nix ~/.config/home-manager/home-common.nix

sync-home-mac:
	cp home.nix ~/.config/home-manager/home.nix
	cp home-common.nix ~/.config/home-manager/home-common.nix

sync-server-nixos:
	sudo cp nixos-server-configuration.nix /etc/nixos/configuration.nix
	sudo cp nixos-common.nix /etc/nixos/nixos-common.nix
	sudo cp nixos-server-private.nix /etc/nixos/nixos-server-private.nix

sync-server-home:
	mkdir -p ~/.config/home-manager
	cp nixos-server-home.nix ~/.config/home-manager/home.nix
	cp home-common.nix ~/.config/home-manager/home-common.nix

sync-linux: sync-nixos sync-home-linux

sync-server: sync-server-nixos sync-server-home

sync-mac: sync-home-mac

init-mac: 
	curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --no-daemon
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

# The runbook for this network, rendered from ye-olde-jellyfin's generic one
# and diffed against homelab.private.md. Empty diff: they agree.
JELLYFIN ?= $(HOME)/src/ye-olde-jellyfin
homelab:
	sed -f homelab.values $(JELLYFIN)/docs/runbook.md | diff -u homelab.private.md - || true
