# ye-olde-server. Synced to /etc/nixos/configuration.nix by `make sync-server`.
# hardware-configuration.nix stays on the host, same as the laptop, and this
# network's addresses are in the gitignored nixos-server-private.nix.
#
# Still here on purpose, until Jellyfin moves behind Caddy (dnscount's
# docs/homelab.md): its openFirewall and user = "mac".

{ lib, config, pkgs, ... }:

let
  private = import ./nixos-server-private.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    /home/mac/src/dnscount/nix/module.nix
    /home/mac/src/dnscount/deploy/nixos/vpn-netns.nix
    /home/mac/src/dnscount/deploy/nixos/wifi-watchdog.nix
  ];

  # Only Transmission and Jackett use the tunnel. They can't reach anything else
  # if it's down, and the rest of the machine never touches it. Key:
  # /var/lib/secrets/mullvad.key
  services.vpnNamespace = {
    inherit (private.mullvad) address publicKey endpoint;
    downloadDir = "/mnt/big-boi/Downloads";
  };

  # No Ethernet on this laptop, and the wl driver can stop receiving while still
  # reporting "connected". The router's syslog never stops for long, so a quiet
  # raw directory means inbound traffic has died. See
  # deploy/nixos/wifi-watchdog.nix.
  services.wifiWatchdog = {
    enable = true;
    interface = "wlp2s0";
    inherit (private) gateway;
    driver = "wl";
    inboundPath = "/var/lib/dnscount/raw";
  };
  networking.networkmanager.wifi.powersave = false;

  # Hit counter and request/DNS logger; see ~/src/dnscount/docs/homelab.md.
  # Listens on all addresses so a DHCP change can't stop it binding: the
  # firewall rule and the allow list both limit senders to the router.
  services.dnscount = {
    enable = true;
    package = pkgs.callPackage /home/mac/src/dnscount/nix/package.nix { };
    environmentFile = "/var/lib/secrets/dnscount.env";
    syslog = {
      enable = true;
      allow = [ private.gateway ];
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ye-olde-server";

  # Enable networking
  networking.networkmanager.enable = true;

  # This box serves things, so it must never go to sleep on its own. Plasma's
  # idle settings can't override these.
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  # Mounted at boot, by UUID, instead of by udisks at desktop login. udisks
  # picks the path at mount time: when big-boi's USB connection dropped and it
  # came back under a new device name, the old mount was still there and it
  # landed on /run/media/mac/big-boi1. nofail so a missing drive can't hold up
  # boot.
  fileSystems."/mnt/big-boi" = {
    device = "/dev/disk/by-uuid/56445c81-510e-4d4f-99db-257989f3fc1d";
    fsType = "btrfs";
    options = [ "nofail" "x-systemd.device-timeout=30s" ];
  };
  fileSystems."/mnt/Media" = {
    device = "/dev/disk/by-uuid/68f95af7-f7c6-4ec8-867b-1f712524b36e";
    fsType = "xfs";
    options = [ "nofail" "x-systemd.device-timeout=30s" ];
  };

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

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Required for a zsh login shell; see the note in nixos-configuration.nix.
  # home-manager owns ~/.zshrc.
  programs.zsh.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."mac" = {
    isNormalUser = true;
    description = "mac";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "media" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
    openssh.authorizedKeys.keys = private.authorizedKeys;
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "mac";
  };
  # Without the drive, stay down rather than scan an empty library.
  systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ "/mnt/big-boi" ];

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "mac" ];
      MaxAuthTries = 3;
      PerSourcePenalties = "crash:3600s authfail:3600s max:86400s";
      # One mistyped passphrase costs an hour under the penalties above, so
      # the controller is exempt. Not every neighbour on its network is.
      PerSourcePenaltyExemptList = private.sshExempt;
    };
  };

  environment.systemPackages = [
    pkgs.vim
    pkgs.git
    pkgs.gnumake
    pkgs.home-manager
    pkgs.jellyfin
    pkgs.vlc
  ];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "26.05"; # Did you read the comment?
}
