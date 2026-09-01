#!/usr/bin/env bash

# Apex Studio termux-packages wrapper configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

# Original Termux package name (for sed replacement)
TERMUX_PACKAGE_NAME="com.termux"
export TERMUX_PACKAGE_NAME

# Target package name for Apex Studio.
# This determines the --prefix that termux binaries are compiled with:
# /data/data/<pkg>/files/usr. It MUST equal the installed app package
# (and TermuxConstants.TERMUX_PACKAGE_NAME in the ApexStudio app repo),
# currently dev.apexstudio.ide -> /data/data/dev.apexstudio.ide/files/usr
APEXSTUDIO_PACKAGE_NAME="dev.apexstudio.ide"
export APEXSTUDIO_PACKAGE_NAME

# Supported architectures
APEXSTUDIO_ARCHS=" aarch64 arm "
export APEXSTUDIO_ARCHS

# API level (Android 9+)
TERMUX_PKG_API_LEVEL=28
export TERMUX_PKG_API_LEVEL

# Path to termux-packages clone
TERMUX_PACKAGES_DIR="${TERMUX_PACKAGES_DIR:-$SCRIPT_DIR/termux-packages}"
export TERMUX_PACKAGES_DIR

# GPG key path
APEXSTUDIO_GPG_KEY="${SCRIPT_DIR}/apexstudio.gpg"
export APEXSTUDIO_GPG_KEY

# GPG key fingerprint (Apex Studio Builder primary)
APEXSTUDIO_GPG_KEY_FP="${APEXSTUDIO_GPG_KEY_FP:-2CF72FBB978DE04E1CE50C9D93342A231C32FCDE}"
export APEXSTUDIO_GPG_KEY_FP

# APT repository URL (deployed to pages branch of same repo)
APEXSTUDIO_REPO="${APEXSTUDIO_REPO:-https://apex-studio-dev.github.io/ApexStudio-Packages}"
export APEXSTUDIO_REPO

# Base output directory
APEXSTUDIO_OUTPUT_DIR="${APEXSTUDIO_OUTPUT_DIR:-$SCRIPT_DIR/output}"
export APEXSTUDIO_OUTPUT_DIR

# Directory for local repository
APEXSTUDIO_REPO_DIR="${APEXSTUDIO_OUTPUT_DIR}/repo"
export APEXSTUDIO_REPO_DIR

# Patched marker file
APEXSTUDIO_PATCHED_MARKER="${TERMUX_PACKAGES_DIR}/.apexstudio-patched"
export APEXSTUDIO_PATCHED_MARKER
