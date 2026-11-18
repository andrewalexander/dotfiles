# The home-manager config for every machine: the Macs, the framework and
# ye-olde-server. `make sync` copies it to ~/.config/home-manager/home.nix,
# with plasma.nix next to it on the framework only.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  dot = "${config.home.homeDirectory}/dotfiles/config";
in
{
  # Only the framework gets plasma.nix synced next to this file.
  imports = if builtins.pathExists ./plasma.nix then [ ./plasma.nix ] else [ ];

  config = lib.mkMerge [
    {
      # Standalone home-manager evaluates impurely, so the login decides:
      # andrew on the Macs and the framework, mac on ye-olde-server.
      home.username = builtins.getEnv "USER";
      home.homeDirectory = builtins.getEnv "HOME";

      # rtfm...
      home.stateVersion = "26.05"; # Please read the comment before changing.

      # After home-manager's own package, where they were before the split.
      home.packages = lib.mkAfter [
        pkgs.eza
        pkgs.zplug
        pkgs.nixfmt # vim formats .nix files with it on save
      ];

      # Three kinds of file, pick one per thing:
      # - store link (`source = "${dot}/X"`): Edit the dotfiles copy; run
      #   home-manager switch to get it into the env. The default.
      # - live link (config.lib.file.mkOutOfStoreSymlink): symlinks; share
      #   configs apps write themselves. machines should share resultant configs
      #   (xbar).  Edits land straight in the repo and show in `git diff`.
      # - not linked: machine-local state the app writes (vim undo/swap/
      #   plugged, caches). A real dir, so it never ends up in the repo; vim's
      #   is made by general.vimrc.
      home.file = {
        ".vimrc".source = "${dot}/.vimrc";
        ".vim/autoload/plug.vim".source = "${dot}/.vim/autoload/plug.vim";
        ".vim/general.vimrc".source = "${dot}/.vim/general.vimrc";
        ".vim/mappings.vimrc".source = "${dot}/.vim/mappings.vimrc";
        ".vim/style.vimrc".source = "${dot}/.vim/style.vimrc";
        ".vim/plugins.vimrc".source = "${dot}/.vim/plugins.vimrc";

        ".zshrc.shared".source = "${dot}/.zshrc";
        ".shellrc".source = "${dot}/.shellrc";
        ".ripgreprc".source = "${dot}/.ripgreprc";
      };

      home.sessionVariables = {
        EDITOR = "vim";
      };

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;
    }

    # On Linux, home-manager owns zsh. No ".zshrc" in home.file: programs.zsh
    # generates it, and the two would collide; it sources these two instead.
    # (The Macs link .zshrc.mac as ~/.zshrc instead; see below.)
    #
    # The system config only does the minimum needed to make zsh a legal login
    # shell (environment.shells + the passwd entry), which home-manager cannot
    # do itself.
    (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.file.".zshrc.linux".source = "${dot}/.zshrc.linux";

      programs.zsh = {
        enable = true;

        zplug = {
          enable = true;
          plugins = [ { name = "zsh-users/zsh-autosuggestions"; } ];
        };

        # Ordered after the zplug block (mkOrder 550) so the autosuggest
        # bindkeys in .zshrc.shared have the plugin available.
        initContent = ''
          source $HOME/.zshrc.shared
          source $HOME/.zshrc.linux
        '';
      };
    })

    # .zshrc.mac is the entry point on the Macs
    (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      home.file.".zshrc".source = "${dot}/.zshrc.mac";
      home.file.".aerospace.toml".source = "${dot}/.aerospace.toml";

      # Use the symlink. xbar writes *.vars.json here. plugins installed from
      # xbar's browser land here too. Tracked in git.
      home.file."Library/Application Support/xbar/plugins".source =
        config.lib.file.mkOutOfStoreSymlink "${dot}/xbar/plugins";

      programs.git = {
        enable = true;
        settings.user = {
          name = "Andrew Alexander";
          email = "andrewalex1992@gmail.com";
        };
      };
    })
  ];
}
