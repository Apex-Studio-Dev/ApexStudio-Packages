#!/usr/bin/env bash

# AuraStudio wrapper utilities

RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[34m"
YELLOW="\033[33m"
NC="\033[0m"

aurastudio_info() {
  printf "${BLUE}%s${NC}\n" "$1"
}

aurastudio_ok() {
  printf "${GREEN}%s${NC}\n" "$1"
}

aurastudio_warn() {
  printf "${YELLOW}%s${NC}\n" "$1"
}

aurastudio_error() {
  printf "${RED}%s${NC}\n" "$1" >&2
}

aurastudio_error_exit() {
  aurastudio_error "$1"
  return 1
}

aurastudio_check_command() {
  if [[ -z "${1:-}" ]]; then
    aurastudio_error "Usage: $0 <command>"
    return 1
  fi

  if ! command -v "$1" &>/dev/null; then
    aurastudio_error "'$1' command is not available in PATH. Please install $1."
    return 1
  fi
}
