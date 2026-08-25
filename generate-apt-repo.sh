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

# Symlink all debs into debs directory
info "[*] Collecting .deb files..."
for arch_dir in "$OUTPUT_DIR"/aarch64 "$OUTPUT_DIR"/arm; do
  if [[ -d "$arch_dir" ]]; then
    find "$arch_dir" \
      -mindepth 1 -maxdepth 1 \
      -type f -name "*.deb" \
      -exec ln -sf {} "$DEBS_DIR/" \; || true
  fi
done

deb_count=$(find "$DEBS_DIR" -name "*.deb" -type f 2>/dev/null | wc -l)
info "[*] Found $deb_count .deb files"

if [[ "$deb_count" -eq 0 ]]; then
  die "No .deb files found in $OUTPUT_DIR"
fi

# Generate APT repository
info "[*] Generating APT repository..."
"$TERMUX_APT_REPO" "$DEBS_DIR" "$REPO_DIR" stable main

# Clean up debs symlink directory
rm -rf "$DEBS_DIR"

ok "[+] APT repository generated: $REPO_DIR"
