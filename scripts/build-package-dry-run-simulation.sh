#!/bin/bash

# Dry-run simulation for build-package.sh
# Based on upstream termux-packages/scripts/bin/build-package-dry-run-simulation.sh

set -e -u

DRY_RUN_SCRIPT_NAME=$(basename "$0")
BUILDSCRIPT_NAME="build.sh"
TERMUX_ARCH="aarch64"
TERMUX_DEBUG_BUILD="false"

declare -a PACKAGE_LIST=()
while [ $# -ge 1 ]; do
	case "$1" in
		-a)
			if [ $# -lt 2 ]; then
				echo "$DRY_RUN_SCRIPT_NAME: Option '-a' requires an argument"
				exit 1
			fi
			shift 1
			if [ -z "$1" ]; then
				echo "$DRY_RUN_SCRIPT_NAME: Argument to '-a' should not be empty."
				exit 1
			fi
			TERMUX_ARCH="$1"
			;;
		-d) TERMUX_DEBUG_BUILD="true" ;;
		-*) ;;
		*) PACKAGE_LIST+=("$1") ;;
	esac
	shift 1
done

# Resolve packages directory (termux-packages/packages or packages)
if [ -d "termux-packages/packages" ]; then
	PACKAGES_DIR="termux-packages/packages"
elif [ -d "packages" ]; then
	PACKAGES_DIR="packages"
else
	echo "$DRY_RUN_SCRIPT_NAME: No packages directory found"
	exit 1
fi

for ((i=0; i<${#PACKAGE_LIST[@]}; i++)); do
	TERMUX_PKG_NAME="${PACKAGE_LIST[i]}"
	TERMUX_PKG_BUILDER_SCRIPT="${PACKAGES_DIR}/${TERMUX_PKG_NAME}/build.sh"

	if [ ! -f "$TERMUX_PKG_BUILDER_SCRIPT" ]; then
		echo "$DRY_RUN_SCRIPT_NAME: Package $TERMUX_PKG_NAME not found"
		exit 1
	fi

	# Check excluded arches
	if [ "${TERMUX_ARCH}" != "all" ] && \
		grep -qE "^TERMUX_PKG_EXCLUDED_ARCHES=.*${TERMUX_ARCH}" "$TERMUX_PKG_BUILDER_SCRIPT"; then
		echo "$DRY_RUN_SCRIPT_NAME: Skipping building $TERMUX_PKG_NAME for arch $TERMUX_ARCH"
		continue
	fi

	# Check debug build
	if [ "${TERMUX_DEBUG_BUILD}" = "true" ] && \
		grep -qE "^TERMUX_PKG_HAS_DEBUG=.*false" "$TERMUX_PKG_BUILDER_SCRIPT"; then
		echo "$DRY_RUN_SCRIPT_NAME: Skipping building debug build for $TERMUX_PKG_NAME"
		continue
	fi

	echo "$DRY_RUN_SCRIPT_NAME: $BUILDSCRIPT_NAME would have continued building $TERMUX_PKG_NAME"
	SOME_WOULD_BUILD=true
done

if [ "${SOME_WOULD_BUILD:-false}" != "true" ] && [ ${#PACKAGE_LIST[@]} -gt 0 ]; then
	echo "$DRY_RUN_SCRIPT_NAME: $BUILDSCRIPT_NAME would not have built any packages"
	exit 85 # EX_C__NOOP
fi

echo "$DRY_RUN_SCRIPT_NAME: Unknown arguments, pass to the real $BUILDSCRIPT_NAME"
exit 0
