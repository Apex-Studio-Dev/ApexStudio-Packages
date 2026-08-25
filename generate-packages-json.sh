#!/usr/bin/env bash
# Generate packages.json from APT Packages index
# Usage: ./generate-packages-json.sh <Packages-file> <output.json>
set -euo pipefail

PACKAGES_FILE="${1:?Usage: $0 <Packages-file> <output.json>}"
OUTPUT="${2:?Usage: $0 <Packages-file> <output.json>}"

if [[ ! -f "$PACKAGES_FILE" ]]; then
  echo "Error: $PACKAGES_FILE not found"
  exit 1
fi

python3 -c "
import json, sys

packages = []
current = {}

with open(sys.argv[1]) as f:
    for line in f:
        line = line.rstrip()
        if line == '':
            if 'name' in current:
                packages.append(current)
            current = {}
            continue
        if line.startswith(' '):
            continue
        key, _, val = line.partition(':')
        key = key.strip().lower()
        val = val.strip()
        if key == 'package':
            current['name'] = val
        elif key == 'version':
            current['version'] = val
        elif key == 'description':
            current['desc'] = val
    if 'name' in current:
        packages.append(current)

with open(sys.argv[2], 'w') as f:
    json.dump(packages, f, indent=2)

print(f'Generated {len(packages)} packages')
" "$PACKAGES_FILE" "$OUTPUT"
