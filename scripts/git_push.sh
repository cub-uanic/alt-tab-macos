#!/usr/bin/env bash

set -euo pipefail

# Publish a rewritten master (local fixes on top of a fresh upstream master) to the fork, leaving the
# fork's plain tags an exact mirror of upstream's while keeping its own `-pro` tags.
#
# upstream is the only source of truth for tags. semantic-release derives the next version from the
# tags of the repo it pushes to (the fork): the highest non-prerelease `v*` tag whose commit is in
# master's history. A plain tag the fork keeps and upstream doesn't have only distorts that: it kills
# the next run with "fatal: tag 'v11.8.1' already exists", and a tag whose commit left the history is
# skipped, which silently renumbers the release.
upstream=${UPSTREAM_REMOTE:-upstream}
origin=${ORIGIN_REMOTE:-origin}
branch=${BRANCH:-master}
dryRun=
if [[ ${1:-} == --dry-run ]]; then dryRun=--dry-run; fi

# Uncommitted work is not pushed by this script; the commit message drives the version bump.
[[ -z $(git status --porcelain) ]] || { echo "The working tree is not clean, commit first" >&2; exit 1; }
git merge-base --is-ancestor "$upstream/$branch" HEAD ||
  { echo "$branch does not contain $upstream/$branch, rebase or cherry-pick onto it first" >&2; exit 1; }

# --force so a tag the fork moved doesn't fail the fetch. origin is fetched first and upstream last,
# so upstream's tags win where the two repos disagree.
git fetch --prune --tags --force "$origin"
git fetch --prune --tags --force "$upstream"

remoteTags() { git ls-remote --tags --refs "$1" | sed 's#.*refs/tags/##' | sort; }
upstreamTags=$(remoteTags "$upstream")
[[ -n $upstreamTags ]] || { echo "$upstream has no tags, refusing to purge" >&2; exit 1; }
# A deleted `-pro` tag takes its release off the fork's /releases page. Keeping it is safe: being a
# prerelease tag, it is ignored when the next version is computed.
staleLocal=$(comm -23 <(git tag | sort) <(echo "$upstreamTags") | grep -v -- '-pro$' || true)
staleRemote=$(comm -23 <(remoteTags "$origin") <(echo "$upstreamTags") | grep -v -- '-pro$' || true)
echo "Deleting, $upstream has none of them: ${staleLocal:-${staleRemote:-nothing}}"

[[ -z "$staleLocal" ]] || git tag -d $staleLocal
[[ -z "$staleRemote" ]] || git push $dryRun --force "$origin" --delete $staleRemote

# Tags before the branch: the branch push is what triggers the release CI, and that job fetches the
# tags from origin a few minutes in, after the build steps.
git push $dryRun --force "$origin" "refs/tags/*:refs/tags/*"
git merge-base --is-ancestor "$origin/$branch" HEAD ||
  echo "WARNING: this rolls $origin/$branch back to $(git --no-pager log --oneline -1 HEAD)" >&2
git push $dryRun --force-with-lease "$origin" "HEAD:$branch"

echo "Next version is computed from: $(git tag --merged HEAD --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1)"
