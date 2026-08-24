#!/data/data/com.termux/files/usr/bin/env bash

# AuraStudio termux-packages wrapper configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

# Original Termux package name (for sed replacement)
TERMUX_PACKAGE_NAME="com.termux"
export TERMUX_PACKAGE_NAME

# Target package name for AuraStudio
AURASTUDIO_PACKAGE_NAME="com.aurastudio"
export AURASTUDIO_PACKAGE_NAME

# Supported architectures (aarch64 only)
AURASTUDIO_ARCHS=" aarch64 "
export AURASTUDIO_ARCHS

# API level (Android 9+)
TERMUX_PKG_API_LEVEL=28
export TERMUX_PKG_API_LEVEL

# Path to termux-packages clone
TERMUX_PACKAGES_DIR="${TERMUX_PACKAGES_DIR:-$SCRIPT_DIR/termux-packages}"
export TERMUX_PACKAGES_DIR

# GPG key path
AURASTUDIO_GPG_KEY="${SCRIPT_DIR}/aurastudio.gpg"
export AURASTUDIO_GPG_KEY

# GPG key fingerprint (placeholder — generate with gpg first)
AURASTUDIO_GPG_KEY_FP="${AURASTUDIO_GPG_KEY_FP:-}"
export AURASTUDIO_GPG_KEY_FP

# APT repository URL (for future publishing)
AURASTUDIO_REPO="${AURASTUDIO_REPO:-https://packages.aurastudio.dev/apt/termux-main}"
export AURASTUDIO_REPO

# Base output directory
AURASTUDIO_OUTPUT_DIR="${AURASTUDIO_OUTPUT_DIR:-$SCRIPT_DIR/output}"
export AURASTUDIO_OUTPUT_DIR

# Directory for local repository
AURASTUDIO_REPO_DIR="${AURASTUDIO_OUTPUT_DIR}/repo"
export AURASTUDIO_REPO_DIR

# Patched marker file
AURASTUDIO_PATCHED_MARKER="${TERMUX_PACKAGES_DIR}/.aurastudio-patched"
export AURASTUDIO_PATCHED_MARKER
