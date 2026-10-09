{ lib, config, pkgs, ... }:
# import the nixvim stuff to configure neovim system-wide; we also pass it into
# the home-manager home.packages so it becomes available in the home.nix under
# pkgs
let
	nixvim = import (builtins.fetchGit {
		url = "https://github.com/nix-community/nixvim";
		# If you are not running an unstable channel of nixpkgs, select the
		# corresponding branch of Nixvim.
		# ref = "nixos-26.05";
	});
in

{
	# wip - still using this to figure things out
	imports = [
		# For nix-darwin
		nixvim.nixDarwinModules.nixvim
	];

	programs.nixvim.enable = true;
	programs.nixvim = {
		plugins.lightline.enable = true;
		plugins.lastplace.enable = true;
		plugins.repeat.enable = true;
		plugins.vim-surround.enable = true;
		extraPlugins = with pkgs.vimPlugins; [
		  ctrlp-vim
		  delimitMate
		  neoformat
		  nerdcommenter
		  nerdtree
		  quick-scope
		  vim-bracketed-paste
		  vim-go
		];
	};

	# homebrew and go packages - issue open to get @ refs for the protoc-gen-go
	# in case we do need to pin them
	homebrew.enable = true;
	homebrew.enableZshIntegration = true;
	homebrew.brews = [
		"go"
		"nvm"
		"protobuf"
		"rustup"
		"vault"
	];
	homebrew.casks = [
		"orbstack"
	];
	homebrew.goPackages = [
		"google.golang.org/protobuf/cmd/protoc-gen-go"
		"google.golang.org/grpc/cmd/protoc-gen-go-grpc"
	]; 

	# $ nix-env -qaP | grep wget
	environment.systemPackages = [ 
		pkgs.neovim
		pkgs.firefox
		pkgs.google-chrome
		pkgs.orbstack
	];

	# unfree stuff gets allowlisted individually
	nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
		"google-chrome"
		"orbstack"
		"delimitMate"
	];

	# system and users
	system.primaryUser = "andrew";

	# Used for backwards compatibility, please read the changelog before changing.
	# $ darwin-rebuild changelog
	system.stateVersion = 6;

}

