#!/usr/bin/env bash
# Generate packages.json from one or more APT Packages files
# Usage: ./generate-packages-json.sh <output.json> <Packages-file> [Packages-file...]
set -euo pipefail

OUTPUT="${1:?Usage: $0 <output.json> <Packages-file> [Packages-file...]}"
shift

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
    global current
    if 'name' in current:
        current['arch'] = current_arch
        packages.append(current)
    current = {}

for path in sys.argv[2:]:
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
            elif key == 'filename':
                current['filename'] = val
    flush()

seen = {}
for pkg in packages:
    name = pkg['name']
    arch = pkg.get('arch', 'unknown')
    filename = pkg.get('filename', '')
    
    if name in seen:
        existing_archs = seen[name]['arch']
        if arch == 'all' or 'all' in existing_archs:
            seen[name]['arch'] = ['all']
        else:
            if arch not in existing_archs:
                existing_archs.append(arch)
        if filename:
            if 'filenames' not in seen[name]:
                seen[name]['filenames'] = {}
            seen[name]['filenames'][arch] = filename
    else:
        pkg['arch'] = ['all'] if arch == 'all' else [arch]
        if filename:
            pkg['filenames'] = {arch: filename}
            del pkg['filename']
        seen[name] = pkg

for pkg in seen.values():
    if 'all' in pkg['arch']:
        pkg['arch'] = ['all']
    else:
        order = {'aarch64': 0, 'arm': 1}
        pkg['arch'].sort(key=lambda x: order.get(x, 99))

result = sorted(seen.values(), key=lambda p: p['name'])

with open(sys.argv[1], 'w') as f:
    json.dump(result, f, indent=2)

print(f'Generated {len(result)} packages')
" "$OUTPUT" "${VALID_FILES[@]}"
