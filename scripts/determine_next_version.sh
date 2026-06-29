#!/usr/bin/env bash

set -exu

semanticRelease=$(npx semantic-release --dry-run --ci false)
version=$(echo "$semanticRelease" | sed -nE 's/.+The next release version is (.+)/\1/p')

if [ -z "$version" ]; then
    echo "Error: could not determine next version from git tags via semantic-release" >&2
    exit 1
fi

echo "$version" > "$VERSION_FILE"
