#!/usr/bin/env bash
# Generate packages.json from one or more APT Packages files
# Usage: ./generate-packages-json.sh <output.json> <Packages-file> [Packages-file...]
set -euo pipefail

OUTPUT="${1:?Usage: $0 <output.json> <Packages-file> [Packages-file...]}"
shift

# Filter out missing Packages files
VALID_FILES=()
for f in "$@"; do
  if [[ -f "$f" ]]; then
    VALID_FILES+=("$f")
  else
    echo "WARN: $f not found, skipping"
  fi
done

[[ ${#VALID_FILES[@]} -ge 1 ]] || { echo "Error: no Packages files found"; exit 1; }

python3 -c "
import json, sys, os

packages = []
current = {}
current_arch = ''

def flush():
    global current, current_arch
    if 'name' in current:
        current['arch'] = current_arch
        packages.append(current)
    current = {}
    current_arch = ''

for path in sys.argv[2:]:
    # Determine arch from path
    if 'binary-aarch64' in path:
        current_arch = 'aarch64'
    elif 'binary-arm' in path:
        current_arch = 'arm'
    elif 'binary-all' in path:
        current_arch = 'all'
    else:
        current_arch = 'unknown'

    with open(path) as f:
        for line in f:
            line = line.rstrip()
            if line == '':
                flush()
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
    flush()

# Merge: if package exists in multiple archs, mark as 'both'
seen = {}
for pkg in packages:
    name = pkg['name']
    arch = pkg.get('arch', 'unknown')
    if name in seen:
        old_arch = seen[name].get('arch', '')
        if old_arch != arch and old_arch != 'all' and arch != 'all':
            seen[name]['arch'] = 'both'
        elif arch == 'all':
            seen[name]['arch'] = 'all'
    else:
        seen[name] = pkg

result = sorted(seen.values(), key=lambda p: p['name'])

with open(sys.argv[1], 'w') as f:
    json.dump(result, f, indent=2)

print(f'Generated {len(result)} packages')
" "$OUTPUT" "${VALID_FILES[@]}"
