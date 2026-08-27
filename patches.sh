#!/usr/bin/env bash

# AuraStudio patch module — shared by build.sh and generate-bootstrap-archive.sh
# Applies AuraStudio patches to termux-packages before build or bootstrap generation.

# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

# Patch configuration (defaults — override by setting before sourcing or before calling)
BUILD_PACKAGE_NAME="${BUILD_PACKAGE_NAME:-$AURASTUDIO_PACKAGE_NAME}"
export BUILD_PACKAGE_NAME
BUILD_GPG_KEY="${BUILD_GPG_KEY:-$AURASTUDIO_GPG_KEY}"
export BUILD_GPG_KEY
BUILD_REPO="${BUILD_REPO:-$AURASTUDIO_REPO}"
export BUILD_REPO
BUILD_EXTRAS="${BUILD_EXTRAS:-false}"
export BUILD_EXTRAS

# Critical patches (always applied for bootstrap build)
declare -a PATCHES=(
  # GPG keys — template files
  "termux-keyring.patch.in"

  # Package name replacement in termux-tools
  "termux-tools-name.patch.in"

  # CI: disable AppArmor + fuse-overlayfs for termux-am (#29118)
  "disable-apparmor-fuse-overlayfs.patch"

  # Bootstrap changes (optimized ZIP, brotli, strip)
  "scripts-generate-bootstraps-aurastudio.patch"
  "scripts-cleanup-in-second-stage.patch"

  # -I dependency install: import our GPG key alongside upstream keys
  "use-our-keys-to-install-deps.patch"

  # Build fixes
  "openjdk-17-cleanup.patch"
  "openjdk-21-cleanup.patch"

  # Shared memory (needed by libx11, libdb, etc.)
  "libandroid-shmem-revert-a-shared-memory-patch.patch"
  "libdb-depend-on-android-shmem.patch"
  "libunbound-depend-on-android-shmem.patch"
  "libx11-depend-on-android-shmem.patch"
  "apr-link-against-libandroid-shmem.patch"

  # Build fixes
  "pulseaudio-link-against-libiconv.patch"
  "libuv-force-cmake-build.patch"
  "coreutils-depend-on-libacl.patch"
  "subversion-missing-apr-includes.patch"

  # Termux motd
  "termux-tools-motd.patch"
)

# Optional build-fix patches (applied with --extras flag)
declare -a EXTRA_PATCHES=(
)

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
      sed -e "s|@AURASTUDIO_GPG_KEY@|$(basename "$BUILD_GPG_KEY")|g" \
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

  # Savannah mirrors are down — use mirror URL
  aurastudio_info "[*] Fixing Savannah source URLs..."
  grep -rlE "https?://download\.savannah\.gnu\.org" --include="build.sh" packages/ 2>/dev/null |
    xargs -L1 sed -i -E 's|https?://download\.savannah\.gnu\.org|https://download-mirror.savannah.gnu.org|g' ||
    aurastudio_warn "[!] No Savannah URLs found"

  # Step 5b: (handled by static patch: disable-apparmor-fuse-overlayfs.patch)

  # Step 6: Replace repo URLs with our hosted repo (for -I dependency fetch)
  aurastudio_info "[*] Replacing repo URLs: official → $BUILD_REPO"
  grep -rlF "https://packages-cf.termux.dev/apt/termux-main" --exclude-dir='.git' . 2>/dev/null |
    xargs -L1 sed -i "s|https://packages-cf.termux.dev/apt/termux-main|${BUILD_REPO}|g" ||
    aurastudio_warn "[!] No repo URLs found to replace"

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