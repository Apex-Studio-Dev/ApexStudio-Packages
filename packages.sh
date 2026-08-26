#!/usr/bin/env bash

# AuraStudio bootstrap package lists

declare -a AURASTUDIO_PACKAGES=(
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

  ## ---- Development tools ---- ##
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

  ## ---- JDK ---- ##
  "openjdk-21"
)
