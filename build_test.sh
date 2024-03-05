#!/usr/bin/env bash
set -Eeu

repo_root() { git rev-parse --show-toplevel; }
source "$(repo_root)/sh/lib.sh"

make image
echo
echo "echo CYBER_DOJO_LANGUAGES_START_POINTS_SHA="$(git_commit_sha)""
echo "echo CYBER_DOJO_LANGUAGES_START_POINTS_TAG="$(git_commit_tag)""
