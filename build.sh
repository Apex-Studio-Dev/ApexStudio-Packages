#!/usr/bin/env bash
# AuraStudio wrapper for termux-packages: patch + build
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

# Critical patches (always applied for bootstrap build)
declare -a PATCHES=(
  # GPG keys — template files
  "termux-keyring.patch.in"

  # Package name replacement in termux-tools
  "termux-tools-name.patch.in"

  # GPG key IDs for dep installation (-I flag)
  "use-our-keys-to-install-deps.patch"

  # CI: disable AppArmor + fuse-overlayfs for termux-am (#29118)
  "disable-apparmor-fuse-overlayfs.patch"

  # Bootstrap changes (optimized ZIP, brotli, strip)
  "scripts-generate-bootstraps-CoGo-changes.patch"
  "scripts-cleanup-in-second-stage.patch"
)

# Optional build-fix patches (applied with --extras flag)
declare -a EXTRA_PATCHES=(
  "libdb-depend-on-android-shmem.patch"
  "libunbound-depend-on-android-shmem.patch"
  # libx11: handled via sed (upstream changed)
  "libuv-force-cmake-build.patch"
  "openjdk-21-cleanup.patch"
  "coreutils-depend-on-libacl.patch"
  "libandroid-shmem-revert-a-shared-memory-patch.patch"
  "subversion-missing-apr-includes.patch"
  "git-symlink-scalar.patch"
)

# Script configuration
BUILD_ARCH=""
BUILD_EXPLICIT="false"
BUILD_NO_BUILD="false"
BUILD_INSTALL_DEPS="false"
BUILD_EXTRAS="false"
BUILD_PACKAGE_NAME="$AURASTUDIO_PACKAGE_NAME"
BUILD_REPO="$AURASTUDIO_REPO"
BUILD_GPG_KEY="$AURASTUDIO_GPG_KEY"

usage() {
  cat <<EOF
AuraStudio wrapper for termux-packages

Usage: $0 -a ARCH [options] [package...]

Options:
  -a ARCH        Target architecture (must be aarch64)
  -e             Build only explicitly specified packages
  -n             Patch only, do not build
  -p NAME        Override package name (default: $AURASTUDIO_PACKAGE_NAME)
  -r URL         Override repo URL (default: $AURASTUDIO_REPO)
  -s KEY         Override GPG key path
  -I             Install dependencies from repo before building
  -f             Force rebuild (clean + build)
  --extras       Also apply build-fix patches (libdb, libuv, etc.)
  -h             Show this help

Examples:
  $0 -a aarch64 bash coreutils
  $0 -a aarch64 -I -e bash
  $0 -n    (patch only)
EOF
}

sed_escape() {
  printf '%s\n' "$1" | sed -e 's/[.[\*^$/]/\\&/g' -e 's/\\/\\\\/g' -e 's/#/\\#/g'
}

setup_aurastudio_patches() {
  pushd "$TERMUX_PACKAGES_DIR" || aurastudio_error_exit "Unable to enter termux-packages"

  # Step 1: Global sed replace com.termux → com.aurastudio
  aurastudio_info "[*] Replacing package name: $TERMUX_PACKAGE_NAME → $BUILD_PACKAGE_NAME"
  local count
  count=$(grep -rlF "$TERMUX_PACKAGE_NAME" --include='*.sh' --include='*.patch' --include='*.in' --include='*.py' --include='*.ac' --include='*.am' --include='*.conf' --include='*.cmake' --include='*.mk' --exclude-dir='.git' . 2>/dev/null | wc -l)
  aurastudio_info "[*] Found $count files with $TERMUX_PACKAGE_NAME"

  grep -rlF "$TERMUX_PACKAGE_NAME" --include='*.sh' --include='*.patch' --include='*.in' --include='*.py' --include='*.ac' --include='*.am' --include='*.conf' --include='*.cmake' --include='*.mk' --exclude-dir='.git' . 2>/dev/null |
    xargs -L1 sed -i "s|${TERMUX_PACKAGE_NAME}|${BUILD_PACKAGE_NAME}|g" ||
    aurastudio_error_exit "Failed to replace package name"

  # Step 2: DO NOT delete upstream GPG keys — they're needed for -I dependency fetch
  # Our key is added alongside them, and use-our-keys-to-install-deps.patch imports all 4 keys
  aurastudio_info "[*] Keeping upstream GPG keys for dependency resolution"

  # Step 3: Copy our GPG key alongside upstream keys (restored by patch)
  if [[ -f "$BUILD_GPG_KEY" ]]; then
    aurastudio_info "[*] Installing AuraStudio GPG key..."
    cp "$BUILD_GPG_KEY" "./packages/termux-keyring/$(basename "$BUILD_GPG_KEY")"
  else
    aurastudio_warn "[!] GPG key not found at $BUILD_GPG_KEY — patches will use placeholder"
  fi

  # Step 4: Generate and apply patches
  for patch in "${PATCHES[@]}"; do
    if [[ "$patch" == *.in ]]; then
      # Template file — process with sed
      local out="${patch%.in}"
      aurastudio_info "[*] Generating patch: $patch → $out"
      sed -e "s|@COTG_GPG_KEY@|$(basename "$BUILD_GPG_KEY")|g" \
          -e "s|@AURASTUDIO_GPG_KEY@|$(basename "$BUILD_GPG_KEY")|g" \
          -e "s|@TERMUX_PACKAGE_NAME@|$(sed_escape "$BUILD_PACKAGE_NAME")|g" \
          -e "s|@AURASTUDIO_PACKAGE_NAME@|$(sed_escape "$BUILD_PACKAGE_NAME")|g" \
          "$SCRIPT_DIR/patches/$patch" > "$SCRIPT_DIR/patches/$out" 2>/dev/null || {
            aurastudio_warn "[!] Template $patch not found, skipping"
            continue
          }
      patch="$out"
    fi

    if [[ ! -f "$SCRIPT_DIR/patches/$patch" ]]; then
      aurastudio_warn "[!] Patch $patch not found, skipping"
      continue
    fi

    aurastudio_info "[*] Applying patch: $patch"
    if patch -p1 --no-backup-if-mismatch < "$SCRIPT_DIR/patches/$patch"; then
      aurastudio_ok "[+] Applied '$patch'"
    else
      aurastudio_error_exit "Failed to apply '$patch'"
    fi
  done

  # Step 5: Additional package-specific fixes via sed
  aurastudio_info "[*] Applying package-specific fixes..."

  # libx11: add libandroid-shmem dependency
  if grep -q 'TERMUX_PKG_DEPENDS="libandroid-support, libxcb' packages/libx11/build.sh 2>/dev/null; then
    sed -i 's|TERMUX_PKG_DEPENDS="libandroid-support, libxcb|TERMUX_PKG_DEPENDS="libandroid-support, libandroid-shmem, libxcb|g' packages/libx11/build.sh
    aurastudio_ok "[+] Fixed libx11: added libandroid-shmem dependency"
  fi

  # Step 5b: (handled by static patch: disable-apparmor-fuse-overlayfs.patch)

  # Step 6: Replace repo URLs — DISABLED
  # Official Termux repos must remain for -I dependency fetch.
  # Our repo is added separately in repo.json.
  aurastudio_info "[*] Skipping repo URL replacement (official repos kept for -I)"

  # Mark as patched
  touch "$AURASTUDIO_PATCHED_MARKER"
  aurastudio_ok "[+] Termux-packages patched for AuraStudio ($BUILD_PACKAGE_NAME)"

  # Apply extra build-fix patches if requested
  if [[ "$BUILD_EXTRAS" == "true" ]]; then
    pushd "$TERMUX_PACKAGES_DIR" || aurastudio_error_exit "Unable to enter termux-packages"
    for patch in "${EXTRA_PATCHES[@]}"; do
      if [[ ! -f "$SCRIPT_DIR/patches/$patch" ]]; then
        aurastudio_warn "[!] Extra patch $patch not found, skipping"
        continue
      fi
      aurastudio_info "[*] Applying extra patch: $patch"
      if patch -p1 --no-backup-if-mismatch < "$SCRIPT_DIR/patches/$patch"; then
        aurastudio_ok "[+] Applied '$patch'"
      else
        aurastudio_warn "[!] Failed to apply '$patch' (may not be needed)"
      fi
    done
    popd || aurastudio_error_exit "Unable to leave termux-packages"
  fi

  popd || aurastudio_error_exit "Unable to leave termux-packages"
}

# Argument parsing
while getopts "a:enp:r:s:Ifh" opt; do
  case "$opt" in
    a) BUILD_ARCH="$OPTARG" ;;
    e) BUILD_EXPLICIT="true" ;;
    n) BUILD_NO_BUILD="true" ;;
    p) BUILD_PACKAGE_NAME="$OPTARG" ;;
    r) BUILD_REPO="$OPTARG" ;;
    s) BUILD_GPG_KEY="$(realpath "$OPTARG")" ;;
    I) BUILD_INSTALL_DEPS="true" ;;
    f) FORCE_REBUILD=true ;;
    -) case "${OPTARG}" in
         extras) BUILD_EXTRAS="true" ;;
         *) aurastudio_error "Unknown option: --$OPTARG"; exit 1 ;;
       esac; shift ;;
    h) usage; exit 0 ;;
    *) aurastudio_error "Invalid option"; usage; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

# Validate
if [[ "$BUILD_NO_BUILD" != "true" ]]; then
  if [[ -z "$BUILD_ARCH" ]]; then
    aurastudio_error "Architecture (-a) is required for build mode"
    usage
    exit 1
  fi

  if [[ "$AURASTUDIO_ARCHS" != *" $BUILD_ARCH "* ]]; then
    aurastudio_error_exit "Unsupported arch: '$BUILD_ARCH'. Supported: $AURASTUDIO_ARCHS"
  fi
fi

# Check required commands
aurastudio_check_command "git"
aurastudio_check_command "patch"

# Apply patches if not already patched
if [[ ! -f "$AURASTUDIO_PATCHED_MARKER" ]]; then
  setup_aurastudio_patches
else
  aurastudio_ok "[*] Already patched. Use -f to force rebuild."
fi

# If patch-only mode, stop here
if [[ "$BUILD_NO_BUILD" == "true" ]]; then
  aurastudio_ok "[*] Patching complete (no build requested)."
  exit 0
fi

# Create output directory
OUTPUT_DIR="${AURASTUDIO_OUTPUT_DIR}/$BUILD_ARCH"
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
    BUILD_PACKAGES=("${AURASTUDIO_PACKAGES__BASE[@]}")
  fi
fi

aurastudio_info "[*] Building packages: ${BUILD_PACKAGES[*]}"

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

BUILD_ARGS+=("${BUILD_PACKAGES[@]}")

# Run build-package.sh inside termux-packages
pushd "$TERMUX_PACKAGES_DIR" || aurastudio_error_exit "Unable to enter termux-packages"
echo
echo "==="
echo "Building: ${BUILD_PACKAGES[*]} for $BUILD_ARCH"
echo "==="
echo

if ! { time ./build-package.sh "${BUILD_ARGS[@]}" 2>&1 | tee "$OUTPUT_DIR/build.log"; }; then
  aurastudio_error_exit "Build failed. See $OUTPUT_DIR/build.log"
fi

popd || aurastudio_error_exit "Unable to leave termux-packages"
aurastudio_ok "[+] Build complete. Output: $OUTPUT_DIR"
