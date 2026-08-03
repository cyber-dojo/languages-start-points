#!/usr/bin/env bash
set -Eeu

function repo_root()
{ 
  git rev-parse --show-toplevel
}

function git_commit_sha()
{
  git rev-parse HEAD
}

function git_commit_tag()
{
  local -r sha="$(git_commit_sha)"
  echo "${sha:0:7}"
}

function image_name()
{
  echo "${CYBER_DOJO_LANGUAGES_START_POINTS_IMAGE}"
}

function image_base_sha()
{
  docker run --rm $(image_name) sh -c 'echo ${CYBER_DOJO_START_POINTS_BASE_SHA}'
}

# Ends the script, non-zero. Not kill -INT $$: a signal is a request, and four
# of the scripts sourcing this file trap INT to remove a temp dir. Those
# handlers do not exit, so bash ran the handler and then carried on from the
# next statement - a guard reporting a problem left the script running and
# exiting 0. exit cannot be declined; the EXIT trap still runs the cleanup.
function exit_non_zero()
{
  exit 42
}

function stderr()
{
  local -r message="${1}"
  >&2 echo "ERROR: ${message}"
}

function exit_non_zero_unless_installed()
{
  for dependent in "$@"
  do
    if ! installed "${dependent}" ; then
      stderr "${dependent} is not installed!"
      exit_non_zero
    fi
  done
}

function exit_non_zero_unless_file_exists()
{
  local -r filename="${1}"
  if [ ! -f "${filename}" ]; then
    stderr "${filename} does not exist"
    exit_non_zero
  fi
}

function installed()
{
  if hash "${1}" &> /dev/null; then
    true
  else
    false
  fi
}

