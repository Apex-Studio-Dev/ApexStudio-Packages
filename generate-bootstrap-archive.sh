#!/usr/bin/env bash
# Generate bootstrap archives for AuraStudio
# Adapted from terminal-packages (CoGo)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

# shellcheck source=packages.sh
. "$SCRIPT_DIR/packages.sh"

COTG_RELEASE="false"
COTG_LOCAL="false"

usage() {
  echo "Script to generate bootstrap archives for AuraStudio."
  echo
  echo "Usage: $0 [options] [arch]"
  echo
  echo "Options:"
  echo "  -g        Generate release bootstrap (includes debug packages)."
  echo "  -l        Use local packages repository."
  echo "  -r URL    Repository URL (default: $AURASTUDIO_REPO)."
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
    aurastudio_error_exit "variant, arch, and repo must not be empty"
  fi

  local bootstrap_name="bootstrap-${arch}.zip"
  local bootstrap_out="${AURASTUDIO_OUTPUT_DIR}/bootstrap-${variant}-${arch}.zip"

  echo
  echo "==="
  echo "Building bootstrap: ${bootstrap_out}"
  echo "==="
  echo

  local out_dir="$SCRIPT_DIR/output/$arch"
  mkdir -p "$out_dir"
  pushd "$out_dir" || aurastudio_error_exit "Unable to switch to output dir: ${out_dir}"

  if ! {
    set -x
    time "$TERMUX_PACKAGES_DIR/scripts/generate-bootstraps.sh" \
      --architectures "$arch" \
      --repository "$repo" \
      --add "${packages}" |&
      tee "$out_dir/generate-bootstrap-${variant}.log"
  }; then
    aurastudio_error_exit "Failed to generate bootstrap for ${arch} ${variant}."
  fi

  # Rename the built files
  mv "${bootstrap_name}" "${bootstrap_out}" 2>/dev/null || true

  popd || aurastudio_error_exit "Unable to switch from output dir: ${out_dir}"
}

# Parse arguments
while getopts "glr:h" opt; do
  case "$opt" in
    g) COTG_RELEASE="true" ;;
    l) COTG_LOCAL="true" ;;
    r) AURASTUDIO_REPO="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) aurastudio_error "Invalid option"; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

if [[ "$COTG_LOCAL" == "true" ]]; then
  AURASTUDIO_REPO="file://${AURASTUDIO_REPO_DIR}"
fi

if [[ -z "${AURASTUDIO_REPO}" ]]; then
  aurastudio_error_exit "Repository URL must be specified."
fi

# Determine variant and packages
COTG_VARIANT="debug"
declare -a COTG_EXTRA_PACKAGES
COTG_EXTRA_PACKAGES=("${AURASTUDIO_PACKAGES__BASE[@]}")

if [[ "$COTG_RELEASE" == "true" ]]; then
  COTG_VARIANT="release"
  COTG_EXTRA_PACKAGES+=("${AURASTUDIO_PACKAGES__RELEASE[@]}")
else
  COTG_EXTRA_PACKAGES+=("${AURASTUDIO_PACKAGES__DEBUG[@]}")
fi

echo "Using configuration:"
echo "  Variant        : ${COTG_VARIANT}"
echo "  Repository     : ${AURASTUDIO_REPO}"
echo "  Extra packages : ${COTG_EXTRA_PACKAGES[*]}"

# Build for target architectures
for arch in aarch64; do
  build_bootstrap "$COTG_VARIANT" "$arch" "$AURASTUDIO_REPO" "${COTG_EXTRA_PACKAGES[@]}" ||
    aurastudio_error_exit "Unable to build bootstrap for ${arch}"
done
