#!/usr/bin/env bash

set -exu

# ------------------------------------------------------------
# 1️⃣  Run semantic-release in dry‑run mode to obtain the next version
# ------------------------------------------------------------
semanticRelease=$(npx semantic-release --dry-run --ci false)
# Try to extract the version from the dry‑run output
baseVersion=$(echo "$semanticRelease" | sed -nE 's/.+The next release version is (.+)/\1/p')

# ------------------------------------------------------------
# 2️⃣  Fallback: if semantic‑release did not propose a version (e.g. because the branch is behind remote),
#     use the latest tag in the repository.
# ------------------------------------------------------------
if [ -z "$baseVersion" ]; then
    # Ensure we have all tags (the CI checkout may be shallow)
    git fetch --tags --unshallow || true
    # Get the most recent tag that looks like a version tag (vX.Y.Z)
    baseVersion=$(git describe --tags --abbrev=0 --match 'v[0-9]*' | sed 's/^v//')
    echo "[Info] Fallback to latest git tag: $baseVersion"
fi

# Validate that we now have a version string
if [ -z "$baseVersion" ]; then
    echo "Error: could not determine next version from semantic‑release or git tags" >&2
    exit 1
fi

# ------------------------------------------------------------
# 3️⃣  Append our pre‑release identifier (‑pro) so the forked version stays lower than any future upstream release
# ------------------------------------------------------------
customVersion="${baseVersion}-pro"

echo "$customVersion" > "$VERSION_FILE"
echo "VERSION=$customVersion" >> $GITHUB_ENV
# Diagnostic output for CI logs.
echo "Base version from semantic‑release : $baseVersion"
echo "Custom fork version               : $customVersion"
