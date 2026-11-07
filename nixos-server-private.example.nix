# Copy to nixos-server-private.nix (gitignored) and fill in. It's kept out of the
# repo because it describes this network. The WireGuard private key isn't here:
# it's in /var/lib/secrets/mullvad.key.
{
  gateway = "192.168.1.1"; # also the only address allowed to send syslog
  # Exempt from sshd's penalties.
  sshExempt = "192.168.1.50";
  # Public keys allowed to ssh in as mac.
  authorizedKeys = [ "ssh-ed25519 AAAA... you@controller" ];
  # This host, and the networks allowed to reach Jellyfin and the torrent UIs.
  serverAddress = "192.168.1.10";
  domain = "jellyfin.example.com"; # or null to stay LAN-only
  lans = [ "192.168.1.0/24" ];
  # From the Mullvad WireGuard config.
  mullvad = {
    address = [ "10.66.0.2/32" ];
    publicKey = "<server PublicKey>";
    endpoint = "<server IP>:51820";
  };
  # Optional: build from local checkouts instead of the pinned GitHub releases.
  # monitoringSrc = /home/mac/src/ye-olde-monitoring;
  # jellyfinSrc = /home/mac/src/ye-olde-jellyfin;
}
