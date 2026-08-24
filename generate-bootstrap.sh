#!/usr/bin/env bash
# AuraStudio bootstrap builder — builds bootstrap from source via build-bootstraps.sh
#
# This uses the upstream build-bootstraps.sh which compiles all packages from
# source and creates a bootstrap archive. No published APT repo needed.
#
# Usage:
#   ./generate-bootstrap.sh                    # all arches
#   ./generate-bootstrap.sh --architectures aarch64

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=utils.sh
. "$SCRIPT_DIR/utils.sh"
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

# Default architectures
BOOTSTRAP_ARCHS="aarch64"
BOOTSTRAP_ANDROID10=false

usage() {
  cat <<EOF
AuraStudio Bootstrap Builder

Usage: $0 [options]

Options:
  --architectures ARCHS   Comma-separated list (default: aarch64)
  --android10             Generate Android 10+ compatible bootstrap
  -f                      Force rebuild
  -h                      Show this help

Examples:
  $0
  $0 --architectures aarch64
  $0 --android10
EOF
}

FORCE_FLAG=""
declare -a EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --architectures) BOOTSTRAP_ARCHS="$2"; shift 2 ;;
    --android10) BOOTSTRAP_ANDROID10=true; EXTRA_ARGS+=("--android10"); shift ;;
    -f) FORCE_FLAG="-f"; EXTRA_ARGS+=("-f"); shift ;;
    -h) usage; exit 0 ;;
    *) aurastudio_error "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# Ensure termux-packages is patched
if [[ ! -f "$AURASTUDIO_PATCHED_MARKER" ]]; then
  aurastudio_error "termux-packages not patched. Run build.sh -n first."
  exit 1
fi

# Check for required tools
aurastudio_check_command "zip"

aurastudio_info "[*] Building bootstrap for architectures: $BOOTSTRAP_ARCHS"

# Enter termux-packages and run build-bootstraps.sh
pushd "$TERMUX_PACKAGES_DIR" || aurastudio_error_exit "Unable to enter termux-packages"

BUILD_BOOTSTRAPS="$TERMUX_PACKAGES_DIR/scripts/build-bootstraps.sh"
if [[ ! -x "$BUILD_BOOTSTRAPS" ]]; then
  chmod +x "$BUILD_BOOTSTRAPS"
fi

aurastudio_info "[*] Running build-bootstraps.sh..."
if ! { time "$BUILD_BOOTSTRAPS" --architectures "$BOOTSTRAP_ARCHS" "${EXTRA_ARGS[@]}" 2>&1 | tee "$AURASTUDIO_OUTPUT_DIR/bootstrap-build.log"; }; then
  aurastudio_error_exit "Bootstrap build failed. See $AURASTUDIO_OUTPUT_DIR/bootstrap-build.log"
fi

popd || aurastudio_error_exit "Unable to leave termux-packages"

# Show result
aurastudio_ok "[+] Bootstrap build complete!"
ls -lh "$TERMUX_PACKAGES_DIR"/bootstrap-*.zip 2>/dev/null || true
