#!/usr/bin/env bash
# Generate bootstrap archives for Apex Studio
# Adapted from terminal-packages

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

# shellcheck source=packages.sh
. "$SCRIPT_DIR/packages.sh"

# shellcheck source=utils.sh
. "$SCRIPT_DIR/utils.sh"

# shellcheck source=patches.sh
. "$SCRIPT_DIR/patches.sh"

APEXSTUDIO_LOCAL="false"

usage() {
  echo "Script to generate bootstrap archives for Apex Studio."
  echo
  echo "Usage: $0 [options] [arch]"
  echo
  echo "Options:"
  echo "  -l        Use local packages repository."
  echo "  -r URL    Repository URL (default: $APEXSTUDIO_REPO)."
  echo "  -h        Show this help."
}

build_bootstrap() {
  local variant="$1"
  local arch="$2"
  local repo="$3"

  shift 3
  local pkgs=("$@")
  local packages
  packages=$(IFS=,; echo "${pkgs[*]}")

  if [[ -z "$variant" || -z "$arch" || -z "$repo" ]]; then
    apexstudio_error_exit "variant, arch, and repo must not be empty"
  fi

  local bootstrap_name="bootstrap-${arch}.zip"
  local bootstrap_out="${APEXSTUDIO_OUTPUT_DIR}/bootstrap-${variant}-${arch}.zip"

  echo
  echo "==="
  echo "Building bootstrap: ${bootstrap_out}"
  echo "Packages: ${#pkgs[@]}"
  echo "==="
  echo

  local out_dir="$SCRIPT_DIR/output/$arch"
  mkdir -p "$out_dir"
  pushd "$out_dir" || apexstudio_error_exit "Unable to switch to output dir: ${out_dir}"

  if ! { time "$TERMUX_PACKAGES_DIR/scripts/generate-bootstraps.sh" \
      --architectures "$arch" \
      --repository "$repo" \
      --add "${packages}" |& \
      tee "$out_dir/generate-bootstrap-${variant}.log"; }; then
    apexstudio_error "Failed to generate bootstrap for ${arch} ${variant}."
    return 1
  fi

  # Rename the built files
  mv "${bootstrap_name}" "${bootstrap_out}" 2>/dev/null || true

  # Show size
  if [[ -f "${bootstrap_out}" ]]; then
    local size
    size=$(du -h "${bootstrap_out}" | cut -f1)
    echo "Bootstrap size: ${size}"
  fi

  popd || apexstudio_error_exit "Unable to switch from output dir: ${out_dir}"
}

# Parse arguments
while getopts "lr:h" opt; do
  case "$opt" in
    l) APEXSTUDIO_LOCAL="true" ;;
    r) APEXSTUDIO_REPO="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) apexstudio_error "Invalid option"; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

if [[ "$APEXSTUDIO_LOCAL" == "true" ]]; then
  APEXSTUDIO_REPO="file://${APEXSTUDIO_REPO_DIR}"
fi

if [[ -z "${APEXSTUDIO_REPO}" ]]; then
  apexstudio_error_exit "Repository URL must be specified."
fi

# Apply patches to termux-packages (same phase as build.sh) before generating bootstrap
BUILD_REPO="$APEXSTUDIO_REPO"
if [[ ! -f "$APEXSTUDIO_PATCHED_MARKER" ]]; then
  setup_apexstudio_patches
else
  apexstudio_ok "[*] Termux-packages already patched ($APEXSTUDIO_PATCHED_MARKER)"
fi

# Use bootstrap packages only (core + small deps)
APEXSTUDIO_VARIANT="bootstrap"
declare -a APEXSTUDIO_EXTRA_PACKAGES
APEXSTUDIO_EXTRA_PACKAGES=("${APEXSTUDIO_PACKAGES__BOOTSTRAP[@]}")

echo "Using configuration:"
echo "  Variant        : ${APEXSTUDIO_VARIANT}"
echo "  Repository     : ${APEXSTUDIO_REPO}"
echo "  Packages       : ${#APEXSTUDIO_EXTRA_PACKAGES[@]}"

# Build for target architectures
TARGET_ARCH="${1:-aarch64}"
for arch in $TARGET_ARCH; do
  if ! build_bootstrap "$APEXSTUDIO_VARIANT" "$arch" "$APEXSTUDIO_REPO" "${APEXSTUDIO_EXTRA_PACKAGES[@]}"; then
    apexstudio_error "Unable to build bootstrap for ${arch}"
    exit 1
  fi
done
