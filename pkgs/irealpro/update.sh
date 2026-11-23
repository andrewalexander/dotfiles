#!/usr/bin/env bash
# One command to update the iReal Pro package.
#
# The vendor only publishes a moving "latest" URL, so this checks the .deb's
# Last-Modified and Content-Length against what was recorded on the last run
# (upstream.json). If they moved, app2nix regenerates the derivation, the local
# edits in customizations.patch go back on top, and the result is built, synced
# to /etc/nixos and switched into the system profile.
#
# app2nix only takes .deb, so the vendor .rpm is not usable here.
set -euo pipefail

# Overridable only so the flow can be exercised without the vendor and the
# ~232MB download; both default to the real thing.
URL="${IREALPRO_URL:-https://linux.irealpro.com/irealpro_latest_amd64.deb}"
APP2NIX="${IREALPRO_APP2NIX:-github:Er1ckR1ck0/app2nix}"

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$PKG_DIR/../.." && pwd)"
DERIVATION="$PKG_DIR/default.nix"
PATCH_FILE="$PKG_DIR/customizations.patch"
STATE="$PKG_DIR/upstream.json"

force=0
do_switch=1
keep_scratch=0

usage() {
  cat <<'USAGE'
usage: update.sh [--force] [--no-switch] [--keep-scratch]

  --force         regenerate even when upstream looks unchanged
  --no-switch     stop after updating and building the derivation; no sync/switch
  --keep-scratch  leave the app2nix scratch directory behind
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --force)        force=1 ;;
    --no-switch)    do_switch=0 ;;
    --keep-scratch) keep_scratch=1 ;;
    -h|--help)      usage; exit 0 ;;
    *)              echo "update.sh: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

say()  { printf '%s\n' "$*"; }
die()  { printf 'update.sh: %s\n' "$*" >&2; exit 1; }

# Refuse to run from the /etc/nixos copy that `make sync` leaves behind: the
# update has to land in the dotfiles checkout, where it can be committed.
[ -d "$REPO/.git" ] || die "$REPO is not a git checkout - run this from the dotfiles repo, not /etc/nixos"
[ -f "$DERIVATION" ]  || die "missing $DERIVATION"
[ -f "$PATCH_FILE" ]  || die "missing $PATCH_FILE"

# The pinned state, read straight out of the derivation.
nix_attr() { sed -n "s/^[[:space:]]*$1 = \"\\(.*\\)\";[[:space:]]*$/\\1/p" "$DERIVATION" | head -n1; }
pinned_version="$(nix_attr version)"
pinned_sha="$(nix_attr sha256)"
[ -n "$pinned_version" ] || die "could not read the version attr out of $DERIVATION"

# Reads one scalar field; the file is ours and one-field-per-line, so a pair of
# sed expressions (quoted string, then bare number) beats depending on jq, which
# is not installed on this host.
json_field() {
  [ -f "$STATE" ] || return 0
  sed -n -e "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" \
         -e "s/.*\"$1\"[[:space:]]*:[[:space:]]*\\([0-9][0-9]*\\).*/\\1/p" "$STATE" | head -n1
}

# ---------------------------------------------------------------- 1. is it stale?
say "==> checking $URL"
headers="$(curl -sSIL --max-time 60 "$URL" | tr -d '\r')" || die "HEAD request failed"
header_value() { printf '%s\n' "$headers" | awk -v k="$1" 'tolower($1) == k { v=$0; sub(/^[^:]*:[[:space:]]*/, "", v) } END { print v }'; }
up_modified="$(header_value 'last-modified:')"
up_length="$(header_value 'content-length:')"
[ -n "$up_length" ] || die "no Content-Length from the vendor - refusing to guess"

was_modified="$(json_field lastModified)"
was_length="$(json_field contentLength)"
was_version="$(json_field version)"
was_sha="$(json_field sha256)"

reason=""
if [ "$force" = 1 ]; then
  reason="--force"
elif [ ! -f "$STATE" ]; then
  reason="no $(basename "$STATE") yet"
elif [ -z "$up_modified" ]; then
  reason="vendor sent no Last-Modified"
elif [ "$up_modified" != "$was_modified" ] || [ "$up_length" != "$was_length" ]; then
  reason="upstream changed ($was_modified / $was_length -> $up_modified / $up_length)"
elif [ -n "$was_version" ] && { [ "$was_version" != "$pinned_version" ] || [ "$was_sha" != "$pinned_sha" ]; }; then
  reason="default.nix was edited by hand since the last run (recorded $was_version/$was_sha)"
fi

if [ -z "$reason" ]; then
  say "    pinned $pinned_version; upstream unchanged since $up_modified ($up_length bytes)"
  say "==> up to date, nothing to do"
  exit 0
fi
say "    $reason"

# ---------------------------------------------------------------- 2. sudo, once
if [ "$do_switch" = 1 ]; then
  say "==> asking for sudo up front so the build is not interrupted later"
  sudo -v
fi

# ---------------------------------------------------------------- 3. app2nix
scratch="$(mktemp -d)"
restore_backup=0
cleanup() {
  status=$?
  if [ "$status" != 0 ] && [ "$restore_backup" = 1 ]; then
    cp "$scratch/default.nix.bak" "$DERIVATION"
    say "    restored the previous $DERIVATION"
  fi
  if [ "$keep_scratch" = 1 ] || [ "$status" != 0 ]; then
    say "    scratch kept at $scratch"
  else
    rm -rf "$scratch"
  fi
}
trap cleanup EXIT

say "==> running app2nix (downloads the ~232MB .deb)"
# Passing the URL rather than a local file is what makes app2nix emit a
# fetchurl src with a pinned sha256.
#
# app2nix downloads with wget, which this host does not have, and its own
# "missing tools" escalation only supplies patchelf/binutils/nix-index - so it
# dies with a bare ENOENT. Hand it a wget; it still escalates for the rest,
# which is the same configuration that produced today's derivation.
( cd "$scratch" && nix-shell -p wget --run "nix run '$APP2NIX' \
    --extra-experimental-features nix-command --extra-experimental-features flakes \
    -- '$URL'" )
[ -f "$scratch/default.nix" ] || die "app2nix produced no default.nix in $scratch"

# app2nix wgets the .deb into its working directory, and the derivation's
# fetchurl would then download the same 222MB again. Adding the file we already
# have as a fixed-output path lands it exactly where fetchurl looks, so the
# build below finds it already there.
deb="$scratch/irealpro_latest_amd64.deb"
if [ -f "$deb" ]; then
  if added="$(nix-store --add-fixed sha256 "$deb" 2>/dev/null)"; then
    say "    seeded $added"
  else
    say "    could not seed the store; the build will re-download the .deb"
  fi
fi

# ---------------------------------------------------------------- 4. customizations
say "==> applying $(basename "$PATCH_FILE")"
if ! ( cd "$scratch" && patch -p0 --no-backup-if-mismatch < "$PATCH_FILE" ); then
  say ""
  say "The customizations did not apply - app2nix's output has moved. Merge by hand:"
  say "  generated: $scratch/default.nix"
  say "  rejects:   $scratch/default.nix.rej"
  say "  current:   $DERIVATION"
  diff -u "$DERIVATION" "$scratch/default.nix" || true
  die "$DERIVATION left untouched"
fi

nix-instantiate --parse "$scratch/default.nix" >/dev/null || die "the patched derivation does not parse"
grep -q 'pkgs.libx11' "$scratch/default.nix"          || die "the patched derivation lost the X11 input rename"
grep -q 'irealpro.desktop' "$scratch/default.nix"     || die "the patched derivation lost the .desktop fixup"

new_version="$(sed -n 's/^[[:space:]]*version = "\(.*\)";[[:space:]]*$/\1/p' "$scratch/default.nix" | head -n1)"
new_sha="$(sed -n 's/^[[:space:]]*sha256 = "\(.*\)";[[:space:]]*$/\1/p' "$scratch/default.nix" | head -n1)"
[ -n "$new_version" ] || die "the generated derivation has no version attr"

cp "$DERIVATION" "$scratch/default.nix.bak"
restore_backup=1
cp "$scratch/default.nix" "$DERIVATION"
say "    $pinned_version -> $new_version"

# ---------------------------------------------------------------- 5. build
say "==> nix-build pkgs/irealpro"
store_path="$(cd "$REPO" && nix-build --no-out-link pkgs/irealpro)"
desktop="$store_path/share/applications/irealpro.desktop"
[ -f "$desktop" ] || die "the build produced no irealpro.desktop"
grep -q '^Exec=/nix/store/' "$desktop" || die "irealpro.desktop still points outside the store: $(grep '^Exec=' "$desktop")"
grep -q 'AudioVideo;Audio;Music;' "$desktop" || die "irealpro.desktop lost its Categories fixup"
say "    $store_path"

# ------------------------------------------------- 6. record the check metadata
# Written only after a successful build, so a failed run never marks a release
# as already handled.
cat > "$STATE" <<JSON
{
  "url": "$URL",
  "lastModified": "$up_modified",
  "contentLength": $up_length,
  "version": "$new_version",
  "sha256": "$new_sha",
  "checkedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON

# ---------------------------------------------------------------- 7. sync+switch
if [ "$do_switch" = 1 ]; then
  # `make sync` dispatches on `hostname -s` and exits 1 on a host it has no
  # config for, so a wrong machine fails here rather than half-applying.
  say "==> make sync"
  make -C "$REPO" sync
  say "==> sudo nixos-rebuild switch"
  sudo nixos-rebuild switch
fi

restore_backup=0
say ""
say "iReal Pro $pinned_version -> $new_version"
say "  store path: $store_path"
[ "$do_switch" = 1 ] || say "  --no-switch: /etc/nixos and the system profile are unchanged"
say "  commit pkgs/irealpro/default.nix and pkgs/irealpro/upstream.json when you are happy with it"
