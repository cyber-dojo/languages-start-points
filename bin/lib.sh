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

function exit_non_zero()
{
  kill -INT $$
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

