#!/usr/bin/env bash
# Apex Studio wrapper for termux-packages: patch + build
#
# Usage:
#   ./build.sh -a aarch64 bash coreutils
#   ./build.sh -a aarch64 -I -e bash    (explicit + install deps)
#   ./build.sh -n                        (patch only, no build)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=utils.sh
. "$SCRIPT_DIR/utils.sh"
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"
# shellcheck source=packages.sh
. "$SCRIPT_DIR/packages.sh"
# shellcheck source=patches.sh
. "$SCRIPT_DIR/patches.sh"

# Script configuration
BUILD_ARCH=""
BUILD_EXPLICIT="false"
BUILD_NO_BUILD="false"
BUILD_INSTALL_DEPS="false"
BUILD_EXTRAS="false"
BUILD_KEEP_GOING="false"
BUILD_PACKAGE_NAME="$APEXSTUDIO_PACKAGE_NAME"
BUILD_REPO="$APEXSTUDIO_REPO"
BUILD_GPG_KEY="$APEXSTUDIO_GPG_KEY"

usage() {
  cat <<EOF
Apex Studio wrapper for termux-packages

Usage: $0 -a ARCH [options] [package...]

Options:
  -a ARCH        Target architecture (must be aarch64)
  -e             Build only explicitly specified packages
  -n             Patch only, do not build
  -p NAME        Override package name (default: $APEXSTUDIO_PACKAGE_NAME)
  -r URL         Override repo URL (default: $APEXSTUDIO_REPO)
  -s KEY         Override GPG key path
  -I             Install dependencies from repo before building
  -f             Force rebuild (clean + build)
  --keep-going   Skip failed packages, continue building others
  --extras       Also apply build-fix patches (libdb, libuv, etc.)
  -h             Show this help

Examples:
  $0 -a aarch64 bash coreutils
  $0 -a aarch64 -I -e bash
  $0 -n    (patch only)
EOF
}

# Argument parsing — handle long options before getopts
ARGS=("$@")
set -- 
for arg in "${ARGS[@]}"; do
  case "$arg" in
    --keep-going) BUILD_KEEP_GOING="true" ;;
    --extras) BUILD_EXTRAS="true" ;;
    --) shift ;;
    *) set -- "$@" "$arg" ;;
  esac
done

while getopts "a:enp:r:s:Ifkh" opt; do
  case "$opt" in
    a) BUILD_ARCH="$OPTARG" ;;
    e) BUILD_EXPLICIT="true" ;;
    n) BUILD_NO_BUILD="true" ;;
    p) BUILD_PACKAGE_NAME="$OPTARG" ;;
    r) BUILD_REPO="$OPTARG" ;;
    s) BUILD_GPG_KEY="$(realpath "$OPTARG")" ;;
    I) BUILD_INSTALL_DEPS="true" ;;
    f) FORCE_REBUILD=true ;;
    k) BUILD_KEEP_GOING="true" ;;
    h) usage; exit 0 ;;
    *) apexstudio_error "Invalid option"; usage; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

# Validate
if [[ "$BUILD_NO_BUILD" != "true" ]]; then
  if [[ -z "$BUILD_ARCH" ]]; then
    apexstudio_error "Architecture (-a) is required for build mode"
    usage
    exit 1
  fi

  if [[ "$APEXSTUDIO_ARCHS" != *" $BUILD_ARCH "* ]]; then
    apexstudio_error_exit "Unsupported arch: '$BUILD_ARCH'. Supported: $APEXSTUDIO_ARCHS"
  fi
fi

# Check required commands
apexstudio_check_command "git"
apexstudio_check_command "patch"

# Apply patches if not already patched
if [[ ! -f "$APEXSTUDIO_PATCHED_MARKER" ]]; then
  setup_apexstudio_patches
else
  apexstudio_ok "[*] Already patched. Use -f to force rebuild."
fi

# If patch-only mode, stop here
if [[ "$BUILD_NO_BUILD" == "true" ]]; then
  apexstudio_ok "[*] Patching complete (no build requested)."
  exit 0
fi

# Create output directory
OUTPUT_DIR="${APEXSTUDIO_OUTPUT_DIR}/$BUILD_ARCH"
mkdir -p "$OUTPUT_DIR"

# Symlink output dir into termux-packages
if [[ -L "$TERMUX_PACKAGES_DIR/output" ]] || [[ -d "$TERMUX_PACKAGES_DIR/output" ]]; then
  rm -rf "$TERMUX_PACKAGES_DIR/output"
fi
ln -sf "$OUTPUT_DIR" "$TERMUX_PACKAGES_DIR/output"

# Get packages to build
declare -a BUILD_PACKAGES=("$@")

if [[ "$BUILD_EXPLICIT" != "true" ]]; then
  # Add base packages if none specified
  if [[ ${#BUILD_PACKAGES[@]} -eq 0 ]]; then
    BUILD_PACKAGES=("${APEXSTUDIO_PACKAGES[@]}")
  fi
fi

apexstudio_info "[*] Building packages: ${BUILD_PACKAGES[*]}"

# Build arguments
declare -a BUILD_ARGS=(
  "-a" "$BUILD_ARCH"
  "-o" "$OUTPUT_DIR"
)

if [[ "$BUILD_INSTALL_DEPS" == "true" ]]; then
  BUILD_ARGS+=("-I")
fi

if [[ -n "${FORCE_REBUILD:-}" ]]; then
  BUILD_ARGS+=("-f")
fi

# Run build-package.sh inside termux-packages
pushd "$TERMUX_PACKAGES_DIR" || apexstudio_error_exit "Unable to enter termux-packages"
echo
echo "==="
echo "Building: ${BUILD_PACKAGES[*]} for $BUILD_ARCH"
echo "==="
echo

if [[ "$BUILD_KEEP_GOING" == "true" ]]; then
  # --- Keep-going mode: build one-by-one, skip failures ---
  FAILED_PKGS=()
  SUCCESS_COUNT=0
  TOTAL=${#BUILD_PACKAGES[@]}

  for pkg in "${BUILD_PACKAGES[@]}"; do
    IDX=$((SUCCESS_COUNT + ${#FAILED_PKGS[@]} + 1))
    echo ""
    echo ">>> [$IDX/$TOTAL] Building: $pkg"
    echo ""

    PKG_ARGS=("${BUILD_ARGS[@]}" "$pkg")
    if { time ./build-package.sh "${PKG_ARGS[@]}" 2>&1 | tee -a "$OUTPUT_DIR/build.log"; }; then
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
      apexstudio_ok "[OK] $pkg"
    else
      FAILED_PKGS+=("$pkg")
      apexstudio_error "[FAILED] $pkg — skipping"
    fi
  done

  echo ""
  echo "=== Build Summary ==="
  echo "Total:  $TOTAL"
  echo "Built:  $SUCCESS_COUNT"
  echo "Failed: ${#FAILED_PKGS[@]}"

  if [ ${#FAILED_PKGS[@]} -gt 0 ]; then
    printf '%s\n' "${FAILED_PKGS[@]}" > "$OUTPUT_DIR/failed-packages.txt"
    echo "Failed packages saved to: $OUTPUT_DIR/failed-packages.txt"
    echo "Failed: ${FAILED_PKGS[*]}"
  fi

  popd || apexstudio_error_exit "Unable to leave termux-packages"
  apexstudio_ok "[+] Build complete (keep-going). Output: $OUTPUT_DIR"
  exit 0
else
  # --- Normal mode: all-at-once ---
  BUILD_ARGS+=("${BUILD_PACKAGES[@]}")

  if ! { time ./build-package.sh "${BUILD_ARGS[@]}" 2>&1 | tee "$OUTPUT_DIR/build.log"; }; then
    apexstudio_error_exit "Build failed. See $OUTPUT_DIR/build.log"
  fi

  popd || apexstudio_error_exit "Unable to leave termux-packages"
  apexstudio_ok "[+] Build complete. Output: $OUTPUT_DIR"
fi
