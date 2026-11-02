# ye-olde-server's home-manager config. Synced to
# ~/.config/home-manager/home.nix by `make sync-server`. The shell and editor
# parts of nixos-home.nix, without the framework's Plasma and speaker tuning.
{ config, pkgs, ... }:
{
  home.username = "mac";
  home.homeDirectory = "/home/mac";

  # rtfm...
  home.stateVersion = "26.05"; # Please read the comment before changing.

  home.packages = [
    pkgs.eza
    pkgs.zplug
  ];

  home.file = {
    ".vimrc".source = "${config.home.homeDirectory}/dotfiles/config/.vimrc";
    ".vim/autoload/plug.vim".source = "${config.home.homeDirectory}/dotfiles/config/.vim/autoload/plug.vim";
    ".vim/general.vimrc".source = "${config.home.homeDirectory}/dotfiles/config/.vim/general.vimrc";
    ".vim/mappings.vimrc".source = "${config.home.homeDirectory}/dotfiles/config/.vim/mappings.vimrc";
    ".vim/style.vimrc".source = "${config.home.homeDirectory}/dotfiles/config/.vim/style.vimrc";
    ".vim/plugins.vimrc".source = "${config.home.homeDirectory}/dotfiles/config/.vim/plugins.vimrc";

    # no ".zshrc" here - programs.zsh below generates it, and the two
    # would collide. it sources these two instead.
    ".zshrc.shared".source = "${config.home.homeDirectory}/dotfiles/config/.zshrc";
    ".zshrc.linux".source = "${config.home.homeDirectory}/dotfiles/config/.zshrc.linux";
    ".shellrc".source = "${config.home.homeDirectory}/dotfiles/config/.shellrc";
    ".ripgreprc".source = "${config.home.homeDirectory}/dotfiles/config/.ripgreprc";
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  # See the notes on programs.zsh in nixos-home.nix.
  programs.zsh = {
    enable = true;

    zplug = {
      enable = true;
      plugins = [ { name = "zsh-users/zsh-autosuggestions"; } ];
    };

    initContent = ''
      source $HOME/.zshrc.shared
      source $HOME/.zshrc.linux
    '';
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
