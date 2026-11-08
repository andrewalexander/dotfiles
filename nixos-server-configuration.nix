# ye-olde-server. Synced to /etc/nixos/configuration.nix by `make sync`.
# hardware-configuration.nix stays on the host, same as the laptop, and this
# network's addresses are in the gitignored nixos-server-private.nix.

{
  lib,
  config,
  pkgs,
  ...
}:

let
  private = import ./nixos-server-private.nix;

  # The monitoring tool and the Jellyfin stack, pinned. To work against local
  # checkouts instead, set monitoringSrc/jellyfinSrc in nixos-server-private.nix.
  # Bump: change rev, then sha256 from `nix-prefetch-url --unpack <url>`.
  github =
    repo: rev: sha256:
    builtins.fetchTarball {
      url = "https://github.com/andrewalexander/${repo}/archive/${rev}.tar.gz";
      inherit sha256;
    };
  monitoringSrc =
    private.monitoringSrc or (github "ye-olde-monitoring" "5f062bc428a1c48448b902c40e41f6f957530e0d"
      "1k9k9pb3v4ab88k1q2flf51n8i48isg9f83xf3s57cdxsbiz1g0q"
    );
  jellyfinSrc =
    private.jellyfinSrc or (github "ye-olde-jellyfin" "ebaf92f60e28ff72fdcac8d5ea07a47aee611078"
      "1a2ny388xzbj99p6j8qws1am9jnblhzfnp4br5mnzpvs4w69rjik"
    );
in
{
  imports = [
    ./hardware-configuration.nix
    ./nixos-common.nix
    "${monitoringSrc}/nix/module.nix"
    "${jellyfinSrc}/nix/vpn-netns.nix"
    "${jellyfinSrc}/nix/wifi-watchdog.nix"
    "${jellyfinSrc}/nix/media.nix"
  ];

  # Only Transmission and Jackett use the tunnel. They can't reach anything else
  # if it's down, and the rest of the machine never touches it. Key:
  # /var/lib/secrets/mullvad.key
  services.vpnNamespace = {
    inherit (private.mullvad) address publicKey endpoint;
    downloadDir = "/mnt/big-boi/Downloads";
    transmissionCredentialsFile = "/var/lib/secrets/transmission.json";
  };

  # No Ethernet on this laptop, and the wl driver can stop receiving while still
  # reporting "connected". The router's syslog never stops for long, so a quiet
  # raw directory means inbound traffic has died. See
  # ye-olde-jellyfin's nix/wifi-watchdog.nix.
  services.wifiWatchdog = {
    enable = true;
    interface = "wlp2s0";
    inherit (private) gateway;
    driver = "wl";
    inboundPath = "/var/lib/dnscount/raw";
  };
  networking.networkmanager.wifi.powersave = false;

  # ye-olde-monitoring: requests, DNS lookups, alerts and bans. The steps for
  # this host are in homelab.private.md (gitignored); the generic version is
  # ye-olde-jellyfin's docs/runbook.md.
  # Listens on all addresses so a DHCP change can't stop it binding: the
  # firewall rule and the allow list both limit senders to the router.
  services.dnscount = {
    enable = true;
    package = pkgs.callPackage "${monitoringSrc}/nix/package.nix" { };
    environmentFile = "/var/lib/secrets/dnscount.env";
    syslog = {
      enable = true;
      allow = [ private.gateway ];
    };
  };

  networking.hostName = "ye-olde-server";

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
    options = [
      "nofail"
      "x-systemd.device-timeout=30s"
    ];
  };
  fileSystems."/mnt/Media" = {
    device = "/dev/disk/by-uuid/68f95af7-f7c6-4ec8-867b-1f712524b36e";
    fsType = "xfs";
    options = [
      "nofail"
      "x-systemd.device-timeout=30s"
    ];
  };

  # Weekly updates from the 26.05 channel. Never reboots by itself, so a new
  # kernel waits for a manual reboot. Failures are in journalctl -u nixos-upgrade.
  system.autoUpgrade = {
    enable = true;
    dates = "Sun 04:00";
    randomizedDelaySec = "45min";
    allowReboot = false;
  };
  # hardware-configuration.nix allows broadcom-sta by an exact name that includes
  # the kernel version, so any kernel update would break the upgrade. wl is
  # insecure, but this laptop has no other way onto the network.
  nixpkgs.config.allowInsecurePredicate = pkg: lib.getName pkg == "broadcom-sta";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."mac" = {
    isNormalUser = true;
    description = "mac";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "media"
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
    openssh.authorizedKeys.keys = private.authorizedKeys;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Jellyfin behind Caddy, so dnscount sees every request. Its port and network
  # settings are managed by media.nix.
  services.mediaStack = {
    inherit (private) lans serverAddress domain;
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

  # Remote access from my own devices, for ssh and the LAN-only sites (the
  # tailnet is in `lans`). Nothing new is forwarded on the router: Tailscale
  # connects out, directly or through DERP relays. Tagged, so its key never
  # expires; the auth key is only needed for the first login and can be
  # deleted after: /var/lib/secrets/tailscale.key. tailscale0 isn't trusted, so
  # the firewall opens only 22 and the `lans` ports to it, and the tailnet
  # policy narrows that to my devices.
  services.tailscale = {
    enable = true;
    authKeyFile = "/var/lib/secrets/tailscale.key";
    openFirewall = true; # UDP 41641, for direct (non-relayed) connections
    extraUpFlags = [
      "--advertise-tags=tag:server"
      "--accept-dns=false" # keep this host's resolver; MagicDNS is for clients
    ];
  };

  environment.systemPackages = [
    pkgs.vim
    pkgs.git
    pkgs.ripgrep
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
