{ config, pkgs, ... }:
{
  # macos: set up for standalone channels at the moment
  # make init-mac
  home.username = "andrew";
  home.homeDirectory = "/Users/andrew";

  # rtfm...
  home.stateVersion = "26.05"; # Please read the comment before changing.

  home.packages = [
  	ghostty-bin
	zplug
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
	".vimrc".source = "${config.home.homeDirectory}/dotfiles/config/.vimrc";
	".vim/autoload/plug.vim".source = "${config.home.homeDirectory}/dotfiles/config/.vim/autoload/plug.vim";
	".vim/general.vimrc".source = "${config.home.homeDirectory}/dotfiles/config/.vim/general.vimrc";
	".vim/mappings.vimrc".source = "${config.home.homeDirectory}/dotfiles/config/.vim/mappings.vimrc";
	".vim/style.vimrc".source = "${config.home.homeDirectory}/dotfiles/config/.vim/style.vimrc";
	".vim/plugins.vimrc".source = "${config.home.homeDirectory}/dotfiles/config/.vim/plugins.vimrc";

	".zshrc".source = "${config.home.homeDirectory}/dotfiles/config/.zshrc";
	".shellrc".source = "${config.home.homeDirectory}/dotfiles/config/.shellrc";
	".ripgreprc".source = "${config.home.homeDirectory}/dotfiles/config/.ripgreprc";
    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/andrew/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR="vim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
