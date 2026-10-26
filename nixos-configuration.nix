# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs, ...
}:
let
  unstable = import <nixos-unstable> {};
in
{
  imports = [
    <nixos-hardware/framework/12-inch/13th-gen-intel>
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Pinned deliberately rather than linuxPackages_latest. The ILIT2901
  # touchscreen fault is still being bisected, and `nixos-rebuild --upgrade`
  # silently rolling the kernel forward makes that unfalsifiable - every
  # journal we have is already 7.3.0, so there is no baseline to compare to.
  # Pinned AT the running version on purpose: this freezes the kernel without
  # introducing a version change, so the cable-reseat test moves exactly one
  # variable.
  #
  # The fault is a corrupt 2-byte length prefix on i2c-hid reads. Root-caused
  # 2026-10-24: byte 0 of that prefix arrives zeroed, all-ones or bit-shifted
  # while the report payload behind it is intact. Not fixed by any kernel
  # version - it is absent from torvalds/master and hid.git for-next as of
  # 2026-10-24 - so bisecting kernels would not have found it.
  # linuxPackages_7_0 .. _7_3 are all in the channel if a version test is ever
  # wanted. Reversible via the systemd-boot menu.
  #
  # Correction to an earlier note here: hid_field_extract() DOES warn on this
  # machine ("called with n (64) > 32!"). It is harmless - RID 13 declares a
  # 64-bit Transducer Serial field, so it is a static descriptor property, and
  # it is hid_warn_once so it carries no frequency information. It is unrelated
  # to the length-prefix fault.
  boot.kernelPackages = pkgs.linuxPackages_7_3;

  # Workaround for the ILIT2901 length-prefix fault described above. Measured
  # over 695 traced i2c reads: only 20.9% carried the correct 0x0042, and in
  # 99.3% of the bad ones ONLY byte 0 differed, payload intact.
  #
  # i2c_hid_get_input() checks that prefix against wMaxInputLength but never
  # against the size the report descriptor declares, so in-range garbage is
  # accepted and hid_report_raw_event() zero-fills the absent tail. Fields that
  # never arrived read as 0 - hence phantom pen-ups, double-presses and the
  # jumping cursor. The patch trusts the descriptor over the prefix, but only
  # when the payload actually changed, and drops reads carrying a truncated
  # report followed by the next one.
  #
  # One slow stylus drag, before -> after, verified across two runs:
  #   short reports 197/1000 -> 0   | isolated zeros X/Y/P 13/22/33 -> 0/0/1
  #   spurious BTN_TOUCH 22 -> 4    | throughput 95/s -> 115-146/s
  # Throughput ROSE, so reports are recovered rather than suppressed.
  # Full data and the ruled-out hypotheses: ~/cap/ili2901-fix/README.md
  #
  # This does NOT fix the total dropouts. Traced during one: zero i2c
  # transfers to the digitizer for 67s while the touchpad on i2c-17 kept
  # working - the device stops asserting its interrupt, so no driver-side
  # change can recover data that never arrives. fix-touch (transport rebind)
  # remains the only mitigation for that.
  #
  # Cost: any kernelPatches entry forces a local kernel build, so
  # nixos-rebuild takes ~30-60 min here and misses the binary cache.
  # The patch file must be synced to /etc/nixos too - see `make sync-nixos`.
  boot.kernelPatches = [
    {
      name = "i2c-hid-ili2901-unreliable-input-size";
      patch = ./patches/i2c-hid-ili2901-unreliable-input-size.patch;
    }
  ];

  networking.hostName = "ye-olde-framework12"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Intel AX211 (USB 8087:0033) - the kernel already binds it via btusb and
  # rfkill shows it unblocked, but bluez userspace is what was missing: this
  # flag is what runs bluetoothd and registers org.bluez on the system bus.
  # Adding pkgs.bluez to systemPackages would install bluetoothctl with no
  # daemon behind it. This also gates the Plasma Bluetooth applet + System
  # Settings page: nixpkgs' plasma6 module adds bluedevil only under
  # lib.optionals config.hardware.bluetooth.enable, the same way
  # networkmanager above is what pulls in plasma-nm.
  hardware.bluetooth.enable = true;

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
        "default.clock.allowed-rates" = [ 44100 48000 ];
      };
    };
  };

  # services.libinput.enable only generates Xorg InputClass config - it's a
  # no-op under this Wayland (KDE Plasma) session, since KWin reads the
  # libinput library directly. Touchpad/touchscreen tuning for this session
  # goes through KDE (plasma-manager, in home-manager), or a libinput quirks
  # file - though note /etc/libinput/local-overrides.quirks does not currently
  # exist, so nothing is being tuned that way today.

  # Required, not optional: NixOS asserts that a user whose shell is zsh must
  # also have programs.zsh.enable, because this is what generates /etc/zshrc -
  # without it a zsh login has no nix directories on PATH. environment.shells
  # alone is not enough.
  #
  # This does not take zsh config away from home-manager. The split is:
  # NixOS owns /etc/zshrc (system PATH and profile plumbing) and /etc/shells;
  # home-manager owns ~/.zshrc and everything in it, including zplug (see
  # programs.zsh in nixos-home.nix).
  programs.zsh.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."andrew" = {
    isNormalUser = true;
    description = "Andrew ";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
	musescore
	discord
	kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];
  # environment.systemPackages = with pkgs; [
  environment.systemPackages = [
    pkgs.vim
    pkgs.git
    pkgs.discord
    pkgs.go
    pkgs.ghostty
    pkgs.maliit-keyboard
    pkgs.dbeaver-bin
    pkgs.usbutils
    unstable.libfprint
    pkgs.home-manager
    pkgs.claude-code
    pkgs.gnumake
    pkgs.kdePackages.plasma-thunderbolt
    pkgs.python3
    # input debugging for the ILIT2901 touchscreen work - libinput
    # debug-events shows what userspace actually receives, evtest shows
    # raw kernel events. both were being nix-shell'd ad hoc.
    pkgs.libinput
    pkgs.evtest
    # Audio triage tooling. Before this, the only things on PATH were the
    # pw-* tools and wpctl - no pactl, amixer, aplay or speaker-test - which
    # makes anything below the PipeWire layer awkward to inspect.
    pkgs.alsa-utils          # amixer/aplay/arecord/speaker-test vs the ALC285
    pkgs.pulseaudio          # for pactl ONLY; the daemon stays off, see
                             # services.pulseaudio.enable = false above
    pkgs.pwvucontrol         # PipeWire-native mixer: shows real nodes and the
                             # negotiated sample rate, which plasma-pa hides

    # iReal Pro, packaged from the vendor .deb in pkgs/irealpro. Imported with
    # `inherit pkgs` rather than callPackage because the expression takes a
    # whole `pkgs` argument, not individual dependencies. Installing it
    # system-wide is what registers the .desktop entry and icon with XDG, so
    # it appears in the Plasma launcher instead of needing the store path.
    # NOTE: this path has to exist under /etc/nixos too - see `make sync-nixos`.
    (import ./pkgs/irealpro { inherit pkgs; })
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "discord"
    "sublimetext4"
    "claude-code"
  ];

  # services.fprintd.enable = true;
  services.fprintd = {
	enable = true;
	package = unstable.fprintd;
  };
#  services.fprintd.tod.enable = true;


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
