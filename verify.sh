#!/usr/bin/env bash
#
# verify.sh — parse every configuration file in this repository
#
set -Eeuo pipefail

cd "$(dirname "$0")"

python3 - <<'PYEOF'
import glob
import sys
import tomllib

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: pip install PyYAML")

failures = []
checked = 0

for path in sorted(glob.glob("**/*.yml", recursive=True)):
    try:
        with open(path) as handle:
            yaml.safe_load(handle)
        checked += 1
    except Exception as exc:
        failures.append(f"{path}: {exc}")

for path in sorted(glob.glob("**/*.toml", recursive=True)):
    try:
        with open(path, "rb") as handle:
            tomllib.load(handle)
        checked += 1
    except Exception as exc:
        failures.append(f"{path}: {exc}")

print(f"parsed {checked} configuration file(s)")
for failure in failures:
    print(f"FAIL {failure}")

if failures:
    sys.exit(1)
print("all valid")
PYEOF
