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
echo "Deleting existing release (if any)..."
gh release delete "$RELEASE_TAG" --yes --cleanup-tag 2>/dev/null && \
  echo "Deleted existing release" || \
  echo "No existing release to delete"

# Create release
echo "Creating release..."
if gh release create "$RELEASE_TAG" \
  --title "Large .deb packages" \
  --notes "Auto-uploaded large .deb files (>${MAX_SIZE_MB}MB) for APT repo" \
  --target main \
  2>&1; then
  echo "Release created successfully"
else
  echo "ERROR: Failed to create release!"
  echo "Skipping upload. Packages will point to non-existent release."
  echo "Check GH_TOKEN permissions (need repo scope)."
  exit 1
fi

# Upload each large .deb
UPLOAD_OK=true
for deb in "${LARGE_DEBS[@]}"; do
  filename=$(basename "$deb")
  echo "Uploading: ${filename} ($(du -h "$deb" | cut -f1))..."
  if gh release upload "$RELEASE_TAG" "$deb" --clobber 2>&1; then
    echo "Uploaded: ${filename}"
  else
    echo "ERROR: Failed to upload ${filename}"
    UPLOAD_OK=false
  fi
done

if [ "$UPLOAD_OK" = false ]; then
  echo ""
  echo "WARNING: Some uploads failed. Packages may point to non-existent files."
fi

# Update Packages files
echo ""
echo "=== Update Packages index ==="

UPDATED_COUNT=0
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
      UPDATED_COUNT=$((UPDATED_COUNT + 1))

      # Remove from repo
      rm -f "$deb"
      echo "Removed from repo: ${filename}"
    fi
  done
done

if [ "$UPDATED_COUNT" -eq 0 ]; then
  echo "WARNING: No Packages files were updated. Release URLs may not work."
fi

# Regenerate Release files
echo ""
echo "=== Regenerate Release files ==="

# Generate Release file
cd "${REPO_DIR}"
if apt-ftparchive release dists/stable > dists/stable/Release 2>/dev/null; then
  echo "Release file regenerated"
else
  echo "WARN: apt-ftparchive not available, skipping Release regeneration"
  cd - > /dev/null
  exit 0
fi

# Re-sign if GPG key available
if [ -n "${GPG_KEY_ID:-}" ] || gpg --list-secret-keys "6D81A8C48CD43B73" &>/dev/null; then
  KEY_ID="${GPG_KEY_ID:-6D81A8C48CD43B73}"
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
