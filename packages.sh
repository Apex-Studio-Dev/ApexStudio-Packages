#!/usr/bin/env bash

# AuraStudio bootstrap package lists

# Base packages common for all builds
declare -a AURASTUDIO_PACKAGES__BASE=(
  ## ---- Bootstrap packages ---- ##
  "apt"
  "bash"
  "command-not-found"
  "coreutils"
  "dash"
  "diffutils"
  "findutils"
  "gawk"
  "grep"
  "gzip"
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
