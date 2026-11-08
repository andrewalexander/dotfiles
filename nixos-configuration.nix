{
  config,
  lib,
  pkgs,
  ...
}:

# The unstable set is a separate nixpkgs instantiation, so `nixpkgs.config`
# below does not reach it - the unfree predicate has to be passed in here.
let
  allowedUnfree = [
    "discord"
    "sublimetext4"
    "claude-code"
  ];
  allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) allowedUnfree;

  unstable = import <nixos-unstable> {
    system = pkgs.stdenv.hostPlatform.system;
    config = { inherit allowUnfreePredicate; };
  };
in
{
  imports = [
    <nixos-hardware/framework/12-inch/13th-gen-intel>
    ./hardware-configuration.nix
    ./nixos-common.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_7_3;

  # The patch file must be synced to /etc/nixos too - see `make sync-nixos`.
  boot.kernelPatches = [
    {
      name = "i2c-hid-ili2901-unreliable-input-size";
      patch = ./patches/i2c-hid-ili2901-unreliable-input-size.patch;
    }
  ];

  # PIXA3854 touchpad: after resuming from hibernation (seen 2026-10-27) it
  # came back reporting clicks but no motion, pinning the cursor bottom-right.
  # Kernel side looked healthy - bound to hid-multitouch, not runtime
  # suspended, not inhibited, no i2c-hid errors - and a transport rebind
  # (same mechanism as fix-touch, touchpad only) restored it. So rebind it
  # unconditionally on every resume. Runs from post-resume.service, which
  # covers both suspend and hibernate. Harmless when the touchpad is fine,
  # but it also hides whether the fault still happens - drop this to re-test.
  powerManagement.resumeCommands = ''
    d=/sys/bus/i2c/drivers/i2c_hid_acpi
    if [ -e "$d/i2c-PIXA3854:00" ]; then
      echo -n i2c-PIXA3854:00 > "$d/unbind" || true
      sleep 1
    fi
    echo -n i2c-PIXA3854:00 > "$d/bind" || true
  '';

  networking.hostName = "ye-olde-framework12";
  hardware.bluetooth.enable = true;

  # PipeWire itself is enabled in nixos-common.nix.
  services.pipewire = {
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;

    # Upstream ships allowed-rates = [ 48000 ] only, so every 44.1kHz stream
    # (i.e. most music) is resampled through the quality-4 resampler forever.
    # The ALC285 in this machine advertises 44100/48000/96000/192000 natively
    # (/proc/asound/card0/codec#0), so letting the device switch rates is
    # strictly better than converting. Two rates only, deliberately: each
    # extra rate is another chance to glitch on a switch, and 96k/192k buy
    # nothing on built-in speakers. default.clock.rate stays 48000 as the
    # idle/default, which is what conferencing and system sounds want.
    #
    # Each attr here becomes one drop-in in /etc/pipewire/pipewire.conf.d.
    extraConfig.pipewire."10-clock-rates" = {
      "context.properties" = {
        "default.clock.allowed-rates" = [
          44100
          48000
        ];
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."andrew" = {
    isNormalUser = true;
    description = "Andrew ";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      musescore
      discord
    ];
  };

  environment.systemPackages = [
    # keep unstable up here
    unstable.libfprint
    unstable.claude-code
    pkgs.vim
    pkgs.git
    pkgs.discord
    pkgs.go
    pkgs.ghostty
    pkgs.maliit-keyboard
    pkgs.dbeaver-bin
    pkgs.usbutils
    pkgs.home-manager
    pkgs.gnumake
    pkgs.kdePackages.plasma-thunderbolt
    pkgs.python3
    # input debugging for the ILIT2901 touchscreen work - libinput
    # debug-events shows what userspace actually receives, evtest shows
    # raw kernel events. both were being nix-shell'd ad hoc.
    pkgs.libinput
    pkgs.evtest
    # pa is for pactl ONLY; the daemon stays off, see
    # services.pulseaudio.enable = false above
    pkgs.alsa-utils
    pkgs.pulseaudio
    # PipeWire-native mixer: shows real nodes and the negotiated sample rate,
    # which plasma-pa hides
    pkgs.pwvucontrol

    # iReal Pro, packaged from the vendor .deb in pkgs/irealpro. Imported with
    # `inherit pkgs` rather than callPackage because the expression takes a
    # whole `pkgs` argument, not individual dependencies. Installing it
    # system-wide is what registers the .desktop entry and icon with XDG, so
    # it appears in the Plasma launcher instead of needing the store path.
    # NOTE: this path has to exist under /etc/nixos too - see `make sync-nixos`.
    (import ./pkgs/irealpro { inherit pkgs; })
  ];

  nixpkgs.config.allowUnfreePredicate = allowUnfreePredicate;

  # services.fprintd.enable = true;
  services.fprintd = {
    enable = true;
    package = unstable.fprintd;
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # don't do it
  system.stateVersion = "26.05"; # Did you read the comment?
}
