#!/usr/bin/env bash

# AuraStudio bootstrap package lists

# Base packages common for all builds
declare -a AURASTUDIO_PACKAGES__BASE=(
  ## ---- Bootstrap packages ---- ##
  "apt"
  "bash"
  "coreutils"
  "dash"
  "diffutils"
  "findutils"
  "gawk"
  "grep"
  "gzip"
  "inetutils"
  "less"
  "libbz2"
  "libcurl"
  "liblzma"
  "procps"
  "psmisc"
  "sed"
  "tar"
  "termux-core"
  "termux-exec"
  "termux-keyring"
  "termux-tools"
  "util-linux"

  ## ---- Additional (base) ---- ##
  "ed"
  "debianutils"
  "dos2unix"
  "git"
  "lsof"
  "nano"
  "net-tools"
  "openjdk-21"
  "patch"
  "unzip"
  "libandroid-support"
  "libandroid-glob"
  "libsndfile"
)

# Debug-only packages
declare -a AURASTUDIO_PACKAGES__DEBUG=(
  "binutils"
  "brotli"
  "cmake"
  "jq"
  "libllvm"
  "libprotobuf"
  "libsqlite"
  "mandoc"
  "python"
  "python-pip"
  "vim"
  "wget"
  "which"
  "zip"
  "zlib"
)

# Release-only packages
declare -a AURASTUDIO_PACKAGES__RELEASE=()

# All packages
declare -a AURASTUDIO_PACKAGES=(
  "${AURASTUDIO_PACKAGES__BASE[@]}"
  "${AURASTUDIO_PACKAGES__DEBUG[@]}"
  "${AURASTUDIO_PACKAGES__RELEASE[@]}"
)
