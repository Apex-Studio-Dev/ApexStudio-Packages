#!/bin/sh

# Free disk space on CI runner (~20GB)
# Based on upstream termux-packages/scripts/free-space.sh
# IMPORTANT: Do NOT purge python3 - needed for generate-packages-json.sh

if [ "${CI-false}" != "true" ]; then
	echo "ERROR: not running on CI, not deleting system files to free space!"
	exit 1
fi

echo "=== Before cleanup ==="
df -h /

# Remove unused packages (KEEP python3!)
sudo apt purge -yq --allow-remove-essential $(
	dpkg -l |
		grep '^ii' |
		awk '{ print $2 }' |
		grep -P '(llvm|clang|gcc-12|gcc-13|gcc-14|gcc-15|cpp-|g\+\+-|dotnet-|ghc-|ant|liblua)'
)

sudo apt purge -yq \
	snapd \
	kubectl \
	podman \
	ruby3.2-doc \
	mercurial-common \
	git-lfs \
	skopeo \
	buildah \
	vim \
	python3-botocore \
	azure-cli \
	shellcheck \
	firefox

# Remove directories
sudo rm -rf /opt/ghc /opt/az /opt/hostedtoolcache /opt/actionarchivecache /opt/runner-cache
sudo rm -rf /opt/pipx /usr/share/dotnet /usr/share/swift /usr/share/miniconda /usr/share/az_* /usr/share/gradle-* /usr/share/java /home/runner/.rustup
sudo rm -rf /etc/skel /home/packer /home/linuxbrew
sudo rm -rf /usr/local /usr/src/

# Remove agent tools directory
sudo rm -rf "$AGENT_TOOLSDIRECTORY"

# Clean docker images
sudo rm -rf /var/lib/containerd/io.containerd.content.v1.content/

sudo apt autoremove -yq
sudo apt clean

echo "=== After cleanup ==="
df -h /
