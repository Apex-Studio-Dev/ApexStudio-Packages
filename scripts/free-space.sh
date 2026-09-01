#!/bin/sh

# Free disk space on CI runner (~20GB)
# Based on upstream termux-packages/scripts/free-space.sh
# IMPORTANT: Do NOT purge python3 - needed for generate-packages-json.sh
#
# NOTE: uses dpkg --remove --force-* instead of `apt purge`. On the
# ubuntu-26.04 based ghcr.io/termux/package-builder container, apt's resolver
# fails with "conflicting assignments" when purging the gcc/cpp toolchains,
# because build-essential still depends on gcc. Force removal bypasses the
# resolver so the big toolchain packages actually get deleted.

if [ "${CI-false}" != "true" ]; then
	echo "ERROR: not running on CI, not deleting system files to free space!"
	exit 1
fi

echo "=== Before cleanup ==="
df -h /

# Force-remove big toolchain / language-runtime packages (KEEP python3!).
# The list is filtered to packages actually installed on this image.
PKGS=$(
	dpkg -l |
		grep '^ii' |
		awk '{ print $2 }' |
		grep -P '(llvm|clang|gcc|g\+\+|cpp|gcj|objc|libstdc\+\+-|liblldb|lib32|libx32|dotnet|aspnetcore|netstandard|ghc|libmono|mono|liblua|apache|pandoc|luajit|mesa|libgl|libegl|google-cloud|azure-|mysql|postgresql|ruby3|swift|nodejs|firefox|snapd|kubectl|podman|skopeo|buildah|git-lfs|shellcheck|vim|temurin|mecab|gfortran|cabal|ant)'
)
if [ -n "$PKGS" ]; then
	echo "Force-removing $(echo "$PKGS" | wc -w) packages"
	# Remove one-by-one so a single failure doesn't abort the rest.
	for pkg in $PKGS; do
		sudo dpkg --remove --force-remove-reinstreq --force-remove-essential --force-depends "$pkg" >/dev/null 2>&1 || true
	done
fi

# Remove directories
sudo rm -rf /opt/ghc /opt/az /opt/hostedtoolcache /opt/actionarchivecache /opt/runner-cache
sudo rm -rf /opt/pipx /usr/share/dotnet /usr/share/swift /usr/share/miniconda /usr/share/az_* /usr/share/gradle-* /usr/share/java /home/runner/.rustup
sudo rm -rf /etc/skel /home/packer /home/linuxbrew
sudo rm -rf /usr/local /usr/src/
sudo rm -rf /usr/lib/llvm-* /usr/lib/llvm

# Remove agent tools directory
sudo rm -rf "$AGENT_TOOLSDIRECTORY"

# Clean docker images
sudo rm -rf /var/lib/containerd/io.containerd.content.v1.content/

# Tidy up remaining packages without hitting the resolver
sudo apt autoremove -yq >/dev/null 2>&1 || true
sudo apt clean >/dev/null 2>&1 || true
sudo rm -rf /var/cache/apt/archives /var/lib/apt/lists/* 2>/dev/null || true

echo "=== After cleanup ==="
df -h /