#!/usr/bin/env bash

# AuraStudio bootstrap package lists

declare -a AURASTUDIO_PACKAGES=(
  ## ---- Bootstrap packages ---- ##
  "apt"
  "bash"
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
  "libcurl"
  "liblzma"
  "ncurses-utils"
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
  "aria2"
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
  "aapt2"
  "binutils"
  "brotli"
  "cmake"
  "gradle"
  "jq"
  "libllvm"
  "libprotobuf"
  "libsqlite"
  "make"
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
