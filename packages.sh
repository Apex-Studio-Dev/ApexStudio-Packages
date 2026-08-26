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
  "patch"
  "unzip"
  "libandroid-support"
  "libandroid-glob"

  ## ---- Audio deps (must be before openjdk-21) ---- ##
  "libogg"
  "libflac"
  "libmp3lame"
  "libmpg123"
  "libopus"
  "libvorbis"
  "libsndfile"

  ## ---- JDK ---- ##
  "openjdk-21"
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
