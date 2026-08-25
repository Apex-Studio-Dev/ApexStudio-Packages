#!/usr/bin/env bash
# Generate APT repository using termux-apt-repo
# Usage: ./generate-apt-repo.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

OUTPUT_DIR="${AURASTUDIO_OUTPUT_DIR:-$SCRIPT_DIR/output}"
REPO_DIR="${AURASTUDIO_REPO_DIR:-$OUTPUT_DIR/repo}"
DEBS_DIR="$OUTPUT_DIR/debs"
TERMUX_APT_REPO="$OUTPUT_DIR/termux-apt-repo"

# Clean previous state
rm -rf "$DEBS_DIR" "$REPO_DIR"

# Download termux-apt-repo tool if not cached
if [[ ! -f "$TERMUX_APT_REPO" ]]; then
  aurastudio_info "[*] Downloading termux-apt-repo..."
  curl -L \
    "https://github.com/termux/termux-apt-repo/raw/refs/heads/master/termux-apt-repo" \
    -o "$TERMUX_APT_REPO"
  chmod +x "$TERMUX_APT_REPO"
fi

# Create directories
mkdir -p "$DEBS_DIR" "$REPO_DIR"

# Symlink all debs into debs directory
aurastudio_info "[*] Collecting .deb files..."
for arch_dir in "$OUTPUT_DIR"/aarch64 "$OUTPUT_DIR"/arm; do
  if [[ -d "$arch_dir" ]]; then
    find "$arch_dir" \
      -mindepth 1 -maxdepth 1 \
      -type f -name "*.deb" \
      -exec ln -sf {} "$DEBS_DIR/" \; || true
  fi
done

deb_count=$(find "$DEBS_DIR" -name "*.deb" -type f 2>/dev/null | wc -l)
aurastudio_info "[*] Found $deb_count .deb files"

if [[ "$deb_count" -eq 0 ]]; then
  aurastudio_error_exit "No .deb files found in $OUTPUT_DIR"
fi

# Generate APT repository
aurastudio_info "[*] Generating APT repository..."
"$TERMUX_APT_REPO" "$DEBS_DIR" "$REPO_DIR" stable main

# Clean up debs symlink directory
rm -rf "$DEBS_DIR"

aurastudio_ok "[+] APT repository generated: $REPO_DIR"
