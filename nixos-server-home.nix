# ye-olde-server's home-manager config. Synced to
# ~/.config/home-manager/home.nix by `make sync-server`, with home-common.nix
# (the shell and editor setup every home shares) next to it.
{ ... }:
{
  imports = [ ./home-common.nix ];

  home.username = "mac";
  home.homeDirectory = "/home/mac";
}
