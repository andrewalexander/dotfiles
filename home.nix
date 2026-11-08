# The Macs' home-manager config (standalone channels; `make init-mac`).
# Synced to ~/.config/home-manager/home.nix by `make sync-home-mac`, with
# home-common.nix (the shell and editor setup every home shares) next to it.
{ config, ... }:
{
  imports = [ ./home-common.nix ];

  home.username = "andrew";
  home.homeDirectory = "/Users/andrew";

  # .zshrc.mac is the entry point here (homebrew/nvm/rustup + zplug from
  # ~/.zplug); it sources .zshrc.shared at the end.
  home.file.".zshrc".source = "${config.home.homeDirectory}/dotfiles/config/.zshrc.mac";

  programs.git = {
    enable = true;
    settings.user = {
      name = "Andrew Alexander";
      email = "andrewalex1992@gmail.com";
    };
  };
}
