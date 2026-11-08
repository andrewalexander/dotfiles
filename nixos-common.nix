# What the NixOS machines (the framework and ye-olde-server) both set: boot,
# locale, the Plasma desktop, sound and zsh. Imported by nixos-configuration.nix
# and nixos-server-configuration.nix; `make sync-nixos` and `make
# sync-server-nixos` copy it next to them in /etc/nixos.
{ ... }:
{
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire. Per-machine tuning (the framework's clock
  # rates) is added in that machine's config.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Required, not optional: NixOS asserts that a user whose shell is zsh must
  # also have programs.zsh.enable, because this is what generates /etc/zshrc -
  # without it a zsh login has no nix directories on PATH. environment.shells
  # alone is not enough.
  #
  # This does not take zsh config away from home-manager. The split is:
  # NixOS owns /etc/zshrc (system PATH and profile plumbing) and /etc/shells;
  # home-manager owns ~/.zshrc and everything in it, including zplug (see
  # programs.zsh in home-common.nix).
  programs.zsh.enable = true;

  # Install firefox.
  programs.firefox.enable = true;
}
