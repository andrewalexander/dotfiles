{ config, pkgs, ... }:
let
  # plasma-manager lets us manage KDE settings declaratively. Fetched
  # unpinned to match how configuration.nix pulls nixvim; add a `ref`/`rev`
  # here if we ever need reproducibility.
  plasma-manager = builtins.fetchTarball
    "https://github.com/nix-community/plasma-manager/archive/trunk.tar.gz";
in
{
  imports = [
    "${plasma-manager}/modules"
  ];

  # linux (NixOS): set up for standalone channels at the moment
  # make init
  home.username = "andrew";
  home.homeDirectory = "/home/andrew";

  # rtfm...
  home.stateVersion = "26.05"; # Please read the comment before changing.

  home.packages = [
	pkgs.zplug
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

  # KDE Plasma settings, managed declaratively.
  programs.plasma = {
    enable = true;

    # On-screen keyboard. Plasma 6.6's own default (org.kde.plasma.keyboard)
    # is a known source of input corruption - repeated letters and a "key
    # never released" stuck-input effect, which shows up even when you aren't
    # using the on-screen keyboard - so we point KWin at maliit instead.
    #
    # VirtualKeyboardEnabled = false stops it auto-popping on every text
    # field. It should only ever appear when explicitly asked for - currently
    # that means the org.kde.plasma.manage-inputmethod tray applet.
    #
    # NOTE: KWin only reads InputMethod at startup - changing it requires a
    # logout/login, not just a reconfigure.
    configFile.kwinrc.Wayland = {
      InputMethod =
        "/run/current-system/sw/share/applications/com.github.maliit.keyboard.desktop";
      VirtualKeyboardEnabled = false;
    };

    # NEXT STEP (only after the virtual keyboard behaves): re-add
    # disable-touchpad-while-typing. Touchpad is PIXA3854:00 093A:0239;
    # vendorId/productId are hex, per plasma-manager's option docs.
    #
    # input.touchpads = [{
    #   name = "PIXA3854:00 093A:0239 Touchpad";
    #   vendorId = "093A";
    #   productId = "0239";
    #   disableWhileTyping = true;
    # }];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
