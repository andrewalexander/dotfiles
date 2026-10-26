{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "irealpro";
  version = "2026.9.7";

  src = pkgs.fetchurl {
    url = "https://linux.irealpro.com/irealpro_latest_amd64.deb";
    sha256 = "sha256-HrS1oXytCjOVdTnJ6cqoaHLCKflnXqWkt7IAAcA7/Ro=";
  };

  dontWrapQtApps = true;

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.dpkg
    pkgs.makeWrapper
  ];

  buildInputs = [
    pkgs.alsa-lib # Accessed via pkgs, so hyphens are fine
    pkgs.at-spi2-core
    pkgs.cairo
    pkgs.cups
    pkgs.dbus
    pkgs.expat
    pkgs.glib
    pkgs.glibc
    pkgs.gtk3
    pkgs.libdrm
    pkgs.libnotify
    pkgs.libsecret
    pkgs.libxkbcommon
    pkgs.mesa
    pkgs.nspr
    pkgs.nss
    pkgs.pango
    pkgs.systemd
    pkgs.libx11
    pkgs.libxcomposite
    pkgs.libxdamage
    pkgs.libxext
    pkgs.libxfixes
    pkgs.libxrandr
    pkgs.libxcb
  ];

  unpackPhase = ''
    ar -x $src
    tar -xf data.tar.xz
  '';

  autoPatchelfIgnoreMissingDeps = [
      "libQt5Core.so.5"
      "libQt5Gui.so.5"
      "libQt5Widgets.so.5"
      "libQt6Core.so.6"
      "libQt6Gui.so.6"
      "libQt6Widgets.so.6"
    ];

  installPhase = ''
    mkdir -p $out
    cp -r usr/* $out/ 2>/dev/null || true
    cp -r opt/* $out/ 2>/dev/null || true
    cp -r bin/* $out/ 2>/dev/null || true

    MAIN_BIN=$(find $out -type f -executable -size +10M | head -n1)

    if [ -n "$MAIN_BIN" ]; then
      mkdir -p $out/bin
      ln -sf "$MAIN_BIN" "$out/bin/irealpro"

      # We use pkgs.lib.makeLibraryPath here
      wrapProgram "$out/bin/irealpro" \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [
            pkgs.libglvnd
            pkgs.mesa
            pkgs.libdrm
            pkgs.vulkan-loader
            pkgs.libxkbcommon
            pkgs.gtk3
            pkgs.alsa-lib
            pkgs.nss
            pkgs.nspr
            pkgs.expat
            pkgs.dbus
            pkgs.at-spi2-core
            pkgs.pango
            pkgs.cairo
            pkgs.libsecret
            pkgs.libnotify
            pkgs.systemd
        ]}" \
        --add-flags "--no-sandbox"

      # The vendor .desktop hardcodes Exec=/opt/iRealPro/irealpro, which does
      # not exist here. Point it at the wrapper so the launcher entry works.
      if [ -f $out/share/applications/irealpro.desktop ]; then
        substituteInPlace $out/share/applications/irealpro.desktop \
          --replace "/opt/iRealPro/irealpro" "$out/bin/irealpro"
      fi
    fi
  '';

  meta = {
    description = "Music practice tool with chord charts, backing tracks, and more";
    platforms = [ "x86_64-linux" ];
  };
}
