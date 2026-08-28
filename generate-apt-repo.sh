#!/usr/bin/env bash
# Generate APT repository using termux-apt-repo
# Usage: ./generate-apt-repo.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OUTPUT_DIR="${AURASTUDIO_OUTPUT_DIR:-$SCRIPT_DIR/output}"
REPO_DIR="${AURASTUDIO_REPO_DIR:-$OUTPUT_DIR/repo}"
DEBS_DIR="$OUTPUT_DIR/debs"
TERMUX_APT_REPO="$OUTPUT_DIR/termux-apt-repo"

info()  { printf "\033[34m%s\033[0m\n" "$1"; }
ok()    { printf "\033[32m%s\033[0m\n" "$1"; }
warn()  { printf "\033[33m%s\033[0m\n" "$1" >&2; }
die()   { printf "\033[31m%s\033[0m\n" "$1" >&2; exit 1; }

# Clean previous state
rm -rf "$DEBS_DIR" "$REPO_DIR"

# Download termux-apt-repo tool if not cached
if [[ ! -f "$TERMUX_APT_REPO" ]]; then
  info "[*] Downloading termux-apt-repo..."
  curl -L \
    "https://github.com/termux/termux-apt-repo/raw/refs/heads/master/termux-apt-repo" \
    -o "$TERMUX_APT_REPO"
  chmod +x "$TERMUX_APT_REPO"
fi

# Create directories
mkdir -p "$DEBS_DIR" "$REPO_DIR"

# Symlink all .debs into the debs directory. Each candidate is validated with
# dpkg-deb --info; any corrupt/truncated .deb (e.g. interrupted large-deb fetch)
# aborts the publish so a package is never silently dropped from the repo.
invalid=0
info "[*] Collecting .deb files..."
while IFS= read -r -d '' src; do
  if ! dpkg-deb --info "$src" >/dev/null 2>&1; then
    warn "[!] Invalid .deb: $src"
    invalid=$((invalid + 1))
    continue
  fi
  ln -sf "$src" "$DEBS_DIR/$(basename "$src")"
done < <(find "$OUTPUT_DIR" \
  -type f -name "*.deb" \
  -not -path "$DEBS_DIR/*" \
  -not -path "$REPO_DIR/*" \
  -print0 2>/dev/null)

if [ "$invalid" -gt 0 ]; then
  die "Found $invalid invalid .deb file(s); aborting to avoid dropping packages from the repo"
fi

deb_count=$(find "$DEBS_DIR" -name "*.deb" \( -type f -o -type l \) 2>/dev/null | wc -l)
info "[*] Found $deb_count .deb files"

if [[ "$deb_count" -eq 0 ]]; then
  die "No .deb files found in $OUTPUT_DIR"
fi

# Generate APT repository
info "[*] Generating APT repository..."
"$TERMUX_APT_REPO" "$DEBS_DIR" "$REPO_DIR" stable main

# Serve only the plain-text Packages index. termux-apt-repo also produces
# Packages.xz/.gz; the compressed variants are dropped so the repo keeps a
# single, immutable object per binary-<arch> path. This avoids Hash Sum
# mismatches caused by stale CDN/edge copies of Packages.xz surviving across
# deploys (each re-deploy replaced the .xz while Release already pointed to
# the new hash -> apt on devices kept fetching the stale .xz object).
info "[*] Removing compressed index variants (Packages.xz/.gz)..."
find "$REPO_DIR/dists" -type f \( -name "Packages.xz" -o -name "Packages.gz" \) -delete
if command -v apt-ftparchive >/dev/null 2>&1; then
  info "[*] Regenerating Release (plain-text indices only)..."
  ( cd "$REPO_DIR" && apt-ftparchive release dists/stable > dists/stable/Release )
else
  warn "[!] apt-ftparchive not found; Release file may still reference removed files"
fi

# Clean up debs symlink directory
rm -rf "$DEBS_DIR"

ok "[+] APT repository generated: $REPO_DIR"
