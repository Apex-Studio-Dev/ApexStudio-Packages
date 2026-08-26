#!/usr/bin/env bash
# Generate packages.json from one or more APT Packages files
# Usage: ./generate-packages-json.sh <output.json> <Packages-file> [Packages-file...]
set -euo pipefail

OUTPUT="${1:?Usage: $0 <output.json> <Packages-file> [Packages-file...]}"
shift
[[ $# -ge 1 ]] || { echo "Usage: $0 <output.json> <Packages-file> [Packages-file...]"; exit 1; }

for f in "$@"; do
  [[ -f "$f" ]] || { echo "Error: $f not found"; exit 1; }
done

python3 -c "
import json, sys

packages = []
current = {}

def flush():
    global current
    if 'name' in current:
        packages.append(current)
    current = {}

for path in sys.argv[2:]:
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

# deduplicate by name (keep last seen, e.g. binary-aarch64 before binary-all)
seen = {}
for pkg in packages:
    seen[pkg['name']] = pkg
result = sorted(seen.values(), key=lambda p: p['name'])

with open(sys.argv[1], 'w') as f:
    json.dump(result, f, indent=2)

print(f'Generated {len(result)} packages')
" "$OUTPUT" "$@"
