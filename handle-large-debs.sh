#!/usr/bin/env bash
# Handle large .deb files (>100MB) by uploading to GitHub Releases
# and updating Packages index to point to release URL.
#
# Usage:
#   export GH_TOKEN="..."
#   export GITHUB_REPOSITORY="Arata-Labs/aurastudio-termux"
#   bash handle-large-debs.sh <repo_dir> [max_size_mb]

set -euo pipefail

REPO_DIR="${1:-.}"
MAX_SIZE_MB="${2:-100}"
RELEASE_TAG="debs"
GITHUB_REPO="${GITHUB_REPOSITORY:-Arata-Labs/aurastudio-termux}"
RELEASE_URL="https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}"

echo "=== Handle Large Debs ==="
echo "Repo dir: ${REPO_DIR}"
echo "Max size: ${MAX_SIZE_MB}MB"
echo "Release tag: ${RELEASE_TAG}"
echo ""

# Find large .deb files
LARGE_DEBS=()
while IFS= read -r -d '' deb; do
  size_mb=$(du -m "$deb" | cut -f1)
  if [ "$size_mb" -ge "$MAX_SIZE_MB" ]; then
    LARGE_DEBS+=("$deb")
    echo "Large: ${deb} (${size_mb}MB)"
  fi
done < <(find "${REPO_DIR}" -name "*.deb" -type f -print0 2>/dev/null)

if [ ${#LARGE_DEBS[@]} -eq 0 ]; then
  echo "No large .deb files found. Skipping."
  exit 0
fi

echo ""
echo "Found ${#LARGE_DEBS[@]} large .deb files"

# Create or update release
echo ""
echo "=== Upload to GitHub Release ==="

# Delete existing release if present
gh release delete "$RELEASE_TAG" --yes --cleanup-tag 2>/dev/null || true

# Create release
gh release create "$RELEASE_TAG" \
  --title "Large .deb packages" \
  --notes "Auto-uploaded large .deb files (>${MAX_SIZE_MB}MB) for APT repo" \
  --tag "$RELEASE_TAG" 2>/dev/null || true

# Upload each large .deb
for deb in "${LARGE_DEBS[@]}"; do
  filename=$(basename "$deb")
  echo "Uploading: ${filename}"
  gh release upload "$RELEASE_TAG" "$deb" --clobber 2>/dev/null || {
    echo "WARN: Failed to upload ${filename}"
    continue
  }
  echo "Uploaded: ${filename}"
done

# Update Packages files
echo ""
echo "=== Update Packages index ==="

for arch in aarch64 arm all; do
  PACKAGES_FILE="${REPO_DIR}/dists/stable/main/binary-${arch}/Packages"
  if [ ! -f "$PACKAGES_FILE" ]; then
    continue
  fi

  for deb in "${LARGE_DEBS[@]}"; do
    filename=$(basename "$deb")
    # Check if this .deb is in this arch's Packages
    if grep -q "Filename:.*${filename}" "$PACKAGES_FILE" 2>/dev/null; then
      # Update Filename to point to release URL
      sed -i "s|Filename:.*${filename}|Filename: ${RELEASE_URL}/${filename}|g" "$PACKAGES_FILE"
      echo "Updated ${arch}: ${filename} → Release URL"

      # Remove from repo (was in dists/.../binary-arch/)
      rm -f "$deb"
      echo "Removed from pool: ${filename}"
    fi
  done
done

# Regenerate Release files
echo ""
echo "=== Regenerate Release files ==="

# Generate Release file
cd "${REPO_DIR}"
apt-ftparchive release dists/stable > dists/stable/Release 2>/dev/null || {
  echo "WARN: apt-ftparchive not available, skipping Release regeneration"
  cd - > /dev/null
  exit 0
}

# Re-sign if GPG key available
if [ -n "${GPG_KEY_ID:-}" ] || gpg --list-secret-keys "5F128F230DEEF535" &>/dev/null; then
  KEY_ID="${GPG_KEY_ID:-5F128F230DEEF535}"
  echo "Signing with key: ${KEY_ID}"

  gpg --batch --yes --pinentry-mode loopback --digest-algo SHA256 \
    --clearsign -u "${KEY_ID}" \
    -o dists/stable/InRelease \
    dists/stable/Release

  gpg --batch --yes --pinentry-mode loopback --digest-algo SHA256 \
    -u "${KEY_ID}" \
    --detach-sign \
    -o dists/stable/Release.gpg \
    dists/stable/Release

  echo "Signed successfully"
else
  echo "No GPG key, skipping signing"
fi

cd - > /dev/null

echo ""
echo "=== Done ==="
echo "Large .debs uploaded to: ${RELEASE_URL}/"
echo "APT repo updated to point to release URLs"
