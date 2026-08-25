#!/usr/bin/env bash

# AuraStudio bootstrap package lists

# Base packages common for all builds
declare -a AURASTUDIO_PACKAGES__BASE=(
  ## ---- Bootstrap packages ---- ##
  "apt"
  "bash"
  "bzip2"
  "command-not-found"
  "coreutils"
  "curl"
  "dash"
  "diffutils"
  "findutils"
  "gawk"
  "grep"
  "gzip"
  "inetutils"
  "less"
  "libbz2"
  "procps"
  "psmisc"
  "sed"
  "tar"
  "termux-core"
  "termux-exec"
  "termux-keyring"
  "termux-tools"
  "util-linux"
  "xz-utils"

  ## ---- Additional ---- ##
  "ed"
  "debianutils"
  "dos2unix"
  "git"
  "lsof"
  "nano"
  "net-tools"
  "patch"
  "unzip"
)

# Debug-only packages
declare -a AURASTUDIO_PACKAGES__DEBUG=(
  "file"
  "vim"
  "wget"
  "which"
)

# Release-only packages
declare -a AURASTUDIO_PACKAGES__RELEASE=()

# All packages
declare -a AURASTUDIO_PACKAGES=(
  "${AURASTUDIO_PACKAGES__BASE[@]}"
  "${AURASTUDIO_PACKAGES__DEBUG[@]}"
  "${AURASTUDIO_PACKAGES__RELEASE[@]}"
)
