{ config, pkgs, ... }:
let
  # plasma-manager lets us manage KDE settings declaratively. Fetched
  # unpinned; add a `ref`/`rev` here if we ever need reproducibility.
  plasma-manager = builtins.fetchTarball "https://github.com/nix-community/plasma-manager/archive/trunk.tar.gz";
in
{
  imports = [
    "${plasma-manager}/modules"
  ];

  # The framework's KDE settings. `make sync` copies this next to home.nix,
  # which imports it when it's there.

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
      InputMethod = "/run/current-system/sw/share/applications/com.github.maliit.keyboard.desktop";
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

  # Framework's built-in speakers are physically small and bass-light. This is
  # a per-user output EQ, which is why it lives here and not in
  # configuration.nix - it's a session daemon with user presets, and NixOS has
  # no equivalent module. PipeWire itself is deliberately left stock apart
  # from the sample-rate drop-in; see the comment on services.pipewire there.
  #
  # programs.dconf, which this module's docs require, is already enabled
  # system-wide by nixpkgs' plasma6 module - nothing to add in configuration.nix.
  #
  # extraPresets is what makes this reproducible rather than captured GUI
  # state: the JSON below is generated from Nix into
  # ~/.local/share/easyeffects/output/framework-speakers.json, and `preset`
  # pins it as the one loaded at startup (--load-preset).
  services.easyeffects = {
    enable = true;
    preset = "framework-speakers";

    # Tuned by ear, not a measured correction. Started as an AutoEQ-style
    # parametric text export imported into EasyEffects, then adjusted while
    # listening - which is why every band is mode "APO (DR)":
    # that is what the APO/AutoEQ text importer sets, and it is kept so the
    # filter shapes stay identical to what was actually auditioned.
    #
    # Rationale per band: a 70Hz hi-pass so excursion isn't wasted on bass
    # these drivers cannot reproduce; +10.07dB at 180Hz for body, which is low
    # enough to add warmth but still inside the driver's usable range;
    # -0.68dB at 1.6kHz to take out the boxy/honky shout; +11.86dB at 7kHz for
    # air. output-gain is -6.9dB: the largest boost is +11.86dB, so this keeps
    # the two boosts from clipping into the limiter without fully cancelling
    # them. Turn system volume up to compensate.
    #
    # To retune: adjust in the EasyEffects GUI, then read the live values out
    # of ~/.config/easyeffects/db/equalizerrc and transcribe them here.
    #
    # Do NOT hit save onto the framework-speakers preset. home-manager owns
    # ~/.local/share/easyeffects/output/framework-speakers.json as a read-only
    # nix-store symlink, so the write fails silently AND EasyEffects then
    # reloads the preset from disk, wiping the in-app tuning you just made.
    # (Saving under a different, unmanaged preset name does work.)
    # Enum note: equalizerrc stores indices - Mode 6 = "APO (DR)", Mode absent
    # = "RLC (BT)"; Slope absent = "x1", band0Slope=1 = "x2".
    extraPresets.framework-speakers.output = {
      blocklist = [ ];
      plugins_order = [ "equalizer#0" ];
      "equalizer#0" = {
        bypass = false;
        input-gain = 0.0;
        output-gain = -6.9;
        mode = "IIR";
        num-bands = 4;
        split-channels = false;
        balance = 0.0;
        pitch-left = 0.0;
        pitch-right = 0.0;
        left = {
          band0 = {
            type = "Hi-pass";
            mode = "APO (DR)";
            slope = "x1";
            solo = false;
            mute = false;
            gain = 0.0;
            frequency = 70.0;
            q = 0.7;
            width = 4.0;
          };
          band1 = {
            type = "Bell";
            mode = "APO (DR)";
            slope = "x1";
            solo = false;
            mute = false;
            gain = 10.07;
            frequency = 180.0;
            q = 0.9;
            width = 4.0;
          };
          band2 = {
            type = "Bell";
            mode = "APO (DR)";
            slope = "x1";
            solo = false;
            mute = false;
            gain = -0.68;
            frequency = 1600.0;
            q = 1.2;
            width = 4.0;
          };
          band3 = {
            type = "Bell";
            mode = "APO (DR)";
            slope = "x1";
            solo = false;
            mute = false;
            gain = 11.86;
            frequency = 7000.0;
            q = 0.8;
            width = 4.0;
          };
        };
        # split-channels = false means EasyEffects drives both channels from
        # the left bank, but it still serialises a right bank - keep identical
        # so toggling split in the GUI doesn't lurch the sound.
        right = {
          band0 = {
            type = "Hi-pass";
            mode = "APO (DR)";
            slope = "x1";
            solo = false;
            mute = false;
            gain = 0.0;
            frequency = 70.0;
            q = 0.7;
            width = 4.0;
          };
          band1 = {
            type = "Bell";
            mode = "APO (DR)";
            slope = "x1";
            solo = false;
            mute = false;
            gain = 10.07;
            frequency = 180.0;
            q = 0.9;
            width = 4.0;
          };
          band2 = {
            type = "Bell";
            mode = "APO (DR)";
            slope = "x1";
            solo = false;
            mute = false;
            gain = -0.68;
            frequency = 1600.0;
            q = 1.2;
            width = 4.0;
          };
          band3 = {
            type = "Bell";
            mode = "APO (DR)";
            slope = "x1";
            solo = false;
            mute = false;
            gain = 11.86;
            frequency = 7000.0;
            q = 0.8;
            width = 4.0;
          };
        };
      };
    };
  };
}
