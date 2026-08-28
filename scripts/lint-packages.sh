#!/bin/bash

# Lint package build.sh files
# Based on upstream termux-packages/scripts/lint-packages.sh (simplified)

set -e -u

start_time="$(date +%10s.%3N)"

check_package_name() {
	local pkg_name="$1"
	echo -n "Package name '${pkg_name}': "
	if [ ${#pkg_name} -lt 2 ]; then
		echo "INVALID (less than two characters long)"
		return 1
	fi
	if ! dpkg --validate-pkgname "${pkg_name}" &> /dev/null; then
		echo "INVALID ($(dpkg --validate-pkgname "${pkg_name}"))"
		return 1
	fi
	echo "PASS"
	return 0
}

check_package_license() {
	local pkg_licenses license license_ok=true
	IFS=',' read -ra pkg_licenses <<< "${1//, /,}"
	for license in "${pkg_licenses[@]}"; do
		case "$license" in
			AFL-2.1|AFL-3.0|APL-1.0|APSL-2.0);;
			Apache-1.0|Apache-1.1|Apache-2.0|Artistic-License-2.0|Attribution);;
			BSD|"BSD 2-Clause"|"BSD 3-Clause"|"BSD New"|"BSD Simplified");;
			BSL-1.0|CC0-1.0|CDDL-1.0|CDDL-1.1|CPAL-1.0|CPL-1.0);;
			CPOL|CeCILL-1|CeCILL-2|CeCILL-2.1|CeCILL-B|CeCILL-C);;
			Codehaus|Copyfree|curl|ECL2|EPL-1.0|EPL-2.0);;
			EUPL-1.1|EUPL-1.2|Eiffel-2.0|Entessa-1.0|Facebook-Platform|Fair);;
			GPL-2.0|GPL-2.0-only|GPL-2.0-or-later);;
			AGPL-3.0|AGPL-3.0-only|AGPL-3.0-or-later);;
			GPL-3.0|GPL-3.0-only|GPL-3.0-or-later);;
			ISC|JSON|JTidy);;
			LGPL-2.0|LGPL-2.0-only|LGPL-2.0-or-later);;
			LGPL-2.1|LGPL-2.1-only|LGPL-2.1-or-later);;
			LGPL-3.0|LGPL-3.0-only|LGPL-3.0-or-later);;
			LPPL-1.0|Libpng|MIT|MPL-2.0|MS-PL|MS-RL|MirOS);;
			Mozilla-1.1|NASA-1.3|NCSA|NOSL-3.0|NTP|NUnit-2.6.3);;
			Nethack|Nokia-1.0a|OCLC-2.0|OSL-3.0|OpenLDAP);;
			OpenSSL|OFL-1.1|Opengroup|PHP-3.0|PHP-3.01|PostgreSQL);;
			"Public Domain"|"Public Domain - SUN"|PythonPL);;
			QTPL-1.0|RPL-1.5|Real-1.0|RicohPL|SUNPublic-1.0|Scala|SimPL-2.0|Sleepycat);;
			Sybase-1.0|TMate|UPL-1.0|Unicode-DFS-2015|Unlicense|UoI-NCSA|"VIM License");;
			VovidaPL-1.0|W3C|WTFPL|wxWindows|X11|Xnet|ZLIB|ZPL-2.0);;
			*)
				license_ok=false
				break
			;;
		esac
	done
	if [ "$license_ok" = 'false' ]; then
		echo "INVALID"
		return 1
	fi
	echo "PASS"
	return 0
}

lint_package() {
	local package_script="$1"
	local package_name
	package_name="$(basename "$(dirname "$package_script")")"

	echo "================================================================"
	echo
	echo "Package: $package_name"
	echo

	echo -n "Layout: "
	if [ ! -d "$(dirname "$package_script")" ]; then
		echo "FAIL - not a directory"
		return 1
	fi
	if [ ! -f "${package_script}" ]; then
		echo "FAIL - no build.sh"
		return 1
	fi
	echo "PASS"

	check_package_name "$package_name" || return 1

	echo -n "End of line check: "
	local last2octet
	read -r _ last2octet _ < <(xxd -s -2 "$package_script")
	if [ "$last2octet" = "0a0a" ]; then
		echo "FAILED (duplicate newlines at the end)"
		return 1
	fi
	if [[ "$last2octet" != *"0a" ]]; then
		echo "FAILED (no newline terminated)"
		return 1
	fi
	echo "PASS"

	echo -n "File permission check: "
	local file_permission
	file_permission=$(stat -c "%A" "$package_script")
	if [[ "$file_permission" == *"x"* ]]; then
		echo "FAILED (executable bit is set)"
		echo "${file_permission}"
		return 1
	fi
	echo "PASS"

	echo -n "Syntax check: "
	local syntax_errors
	syntax_errors=$(bash -n "$package_script" 2>&1)
	if [ ${#syntax_errors} -gt 0 ]; then
		echo "FAILED"
		echo
		echo "$syntax_errors"
		echo
		return 1
	fi
	echo "PASS"

	echo -n "Trailing whitespace check: "
	local re=$'[\t ]\n'
	if [[ "$(< "$package_script")" =~ $re ]]; then
		echo "FAILED"
		grep -Hn '[[:space:]]$' "$package_script"
		echo
		return 1
	fi
	echo "PASS"

	# Source build.sh and check fields
	(set +e +u
		local pkg_lint_error=false

		TERMUX_PKG_API_LEVEL=24
		. "$package_script"

		echo -n "TERMUX_PKG_HOMEPAGE: "
		if [ ${#TERMUX_PKG_HOMEPAGE} -gt 0 ]; then
			echo "PASS"
		else
			echo "NOT SET"
			pkg_lint_error=true
		fi

		echo -n "TERMUX_PKG_DESCRIPTION: "
		if [ ${#TERMUX_PKG_DESCRIPTION} -gt 0 ]; then
			if [ ${#TERMUX_PKG_DESCRIPTION} -gt 100 ]; then
				echo "TOO LONG (max 100 chars)"
			else
				echo "PASS"
			fi
		else
			echo "NOT SET"
			pkg_lint_error=true
		fi

		echo -n "TERMUX_PKG_LICENSE: "
		if [ ${#TERMUX_PKG_LICENSE} -gt 0 ]; then
			case "$TERMUX_PKG_LICENSE" in
				*custom*) echo "CUSTOM" ;;
				'non-free') echo "NON-FREE";;
				*) check_package_license "$TERMUX_PKG_LICENSE" || pkg_lint_error=true ;;
			esac
		else
			echo "NOT SET"
			pkg_lint_error=true
		fi

		echo -n "TERMUX_PKG_MAINTAINER: "
		if [ ${#TERMUX_PKG_MAINTAINER} -gt 0 ]; then
			echo "PASS"
		else
			echo "NOT SET"
			pkg_lint_error=true
		fi

		echo -n "TERMUX_PKG_SRCURL: "
		case "${TERMUX_PKG_SKIP_SRC_EXTRACT:-false}" in
			true|TRUE) echo "SKIP (TERMUX_PKG_SKIP_SRC_EXTRACT=true)" ;;
			*)
				if [ ${#TERMUX_PKG_SRCURL} -gt 0 ]; then
					echo "PASS"
				else
					echo "NOT SET"
					pkg_lint_error=true
				fi
			;;
		esac

		if [ "$pkg_lint_error" = 'true' ]; then
			exit 1
		fi
		exit 0
	)

	local ret=$?
	echo
	return "$ret"
}

linter_main() {
	local problems_found=false
	local package_script

	for package_script in "$@"; do
		if ! lint_package "$package_script"; then
			problems_found=true
			break
		fi
		: $(( package_counter++ ))
	done

	if [ "$problems_found" = 'true' ]; then
		echo "================================================================"
		echo
		echo "A problem has been found in '$(realpath --relative-to="$(pwd)" "$package_script")'."
		echo "Checked $package_counter packages before the first error was detected."
		echo
		echo "================================================================"
		unset package_counter
		exit 1
	fi

	echo "================================================================"
	echo
	echo "Checked $package_counter packages."
	echo "Everything seems ok."
	echo
	echo "================================================================"
	return
}

echo "[INFO]: Starting build script linter"
trap 'echo "[INFO]: Finished linting"' EXIT

package_counter=0
if [ $# -gt 0 ]; then
	linter_main "$@"
	unset package_counter
else
	echo "No packages specified"
	exit 1
fi
