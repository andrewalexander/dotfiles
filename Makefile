# `make sync` copies this machine's configs to where they take effect; then
# `sudo nixos-rebuild switch` (NixOS) and `home-manager switch`.
HOST := $(shell hostname -s)
HM   := $(HOME)/.config/home-manager

sync:
ifeq ($(shell uname),Darwin)
	mkdir -p $(HM) && cp home.nix $(HM)/home.nix
else ifeq ($(HOST),ye-olde-framework12)
	sudo cp nixos-configuration.nix /etc/nixos/configuration.nix
	sudo cp nixos-common.nix /etc/nixos/nixos-common.nix
	sudo rm -rf /etc/nixos/patches /etc/nixos/pkgs
	sudo cp -r patches pkgs /etc/nixos/
	mkdir -p $(HM) && cp home.nix plasma.nix $(HM)/
else ifeq ($(HOST),ye-olde-server)
	sudo cp nixos-server-configuration.nix /etc/nixos/configuration.nix
	sudo cp nixos-common.nix nixos-server-private.nix /etc/nixos/
	mkdir -p $(HM) && cp home.nix $(HM)/home.nix
	rm -f $(HM)/plasma.nix
else
	@echo "make sync: no config for $(HOST)" && exit 1
endif
	rm -f $(HM)/home-common.nix

# One-time, on a fresh Mac.
init-mac:
	curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --no-daemon
	sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
	sudo nix-channel --update
	nix-shell '<home-manager>' -A install
	home-manager switch

.PHONY: sync init-mac
