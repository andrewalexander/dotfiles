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
  };

  # services.libinput.enable only generates Xorg InputClass config - it's a
  # no-op under this Wayland (KDE Plasma) session, since KWin reads the
  # libinput library directly. Touchpad/touchscreen tuning for this session
  # goes through KDE (plasma-manager, in home-manager) or libinput quirks
  # files, not this option.

  # zsh itself is configured by home-manager (programs.zsh + the zplug
  # module in nixos-home.nix). The only part that has to live at the system
  # level is making it a legal login shell: /etc/shells and the passwd entry
  # are not writable from home-manager. Deliberately not programs.zsh.enable,
  # which would pull in system-wide zsh integration we do not want.
  environment.shells = [ pkgs.zsh ];

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
