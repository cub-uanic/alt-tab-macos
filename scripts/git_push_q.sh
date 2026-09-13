#!/usr/bin/env bash

set -euo pipefail

# Assumes local master already contains the local fixes (e.g. cherry-picked "always PRO")
# on top of a fresh upstream master.
git fetch upstream --tags --force # force: upstream's v11.7.0 conflicts with the fork's same-named tag
git push origin --tags --force # force: overwrite the fork's v11.7.0 with upstream's
git push --force-with-lease origin master
