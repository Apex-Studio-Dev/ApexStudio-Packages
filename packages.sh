#!/usr/bin/env bash

# Apex Studio package lists
#
# BOOTSTRAP = minimal core packages for initial setup (small, fast download)
# ALL = full packages including large dev tools (for complete build)

# ─────────────────────────────────────────────────────────────
# Bootstrap: core packages only (~50MB compressed)
# Users can apt install the rest after setup
# ─────────────────────────────────────────────────────────────
declare -a APEXSTUDIO_PACKAGES__BOOTSTRAP=(
  # Core system
  "apt"
  "bash"
  "coreutils"
  "dash"
  "diffutils"
  "findutils"
  "gawk"
  "grep"
  "gzip"
  "less"
  "sed"
  "tar"

  # Termux essentials
  "termux-core"
  "termux-exec"
  "termux-keyring"
  "termux-tools"
  "util-linux"

  # Networking
  "libcurl"
  "wget"

  # Shell tools
  "unzip"
  "procps"
  "psmisc"

  # Basic libs
  "libbz2"
)

# ─────────────────────────────────────────────────────────────
# All packages: full build including large dev tools
# ─────────────────────────────────────────────────────────────
declare -a APEXSTUDIO_PACKAGES=(
  "${APEXSTUDIO_PACKAGES__BOOTSTRAP[@]}"

  # Audio deps (for openjdk)
  "libogg"
  "libflac"
  "libmp3lame"
  "libmpg123"
  "libopus"
  "libvorbis"
  "libsndfile"

  # Shell tools
  "brotli"
  "nano"
  "patch"
  "zip"

  # Basic libs
  "liblzma"
  "ncurses"
  "libandroid-support"
  "libandroid-glob"

  # Development tools
  "aapt"
  "binutils"
  "cmake"
  "glib"
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
  "which"
  "zlib"

  # JDK
  "openjdk-17"
  "openjdk-21"
  "openjdk-25"

  # VCS
  "git"

  # Optional small
  "aria2"
  "debianutils"
  "dos2unix"
  "ed"
  "inetutils"
  "lsof"
  "net-tools"
)
