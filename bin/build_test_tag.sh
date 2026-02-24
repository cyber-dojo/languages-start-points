#!/usr/bin/env bash
set -Eeu

repo_root() { git rev-parse --show-toplevel; }

readonly BIN_DIR="$(repo_root)/bin"
source "${BIN_DIR}/lib.sh"
source "${BIN_DIR}/echo_env_vars.sh"
export $(echo_env_vars)
readonly TMP_DIR=$(mktemp -d /tmp/cyber-dojo.languages-start-points.XXXXXXXXX)
trap 'rm -rf ${TMP_DIR} > /dev/null' INT EXIT

# - - - - - - - - - - - - - - - - - - - - - - - -
build_test_tag()
{
  local -r names="$(tr '\n' ' ' < "$(repo_root)/git_repo_urls.tagged")"

  # Ensure latest env-vars are tunnelled into cyber_dojo -> cyber_dojo_inner script.
  export $(docker run --rm cyberdojo/versioner:latest)

  # build
  $(cyber_dojo) start-point create "$(image_name)" --languages "${names}"

  # test
  local -r expected="${CYBER_DOJO_START_POINTS_BASE_SHA}"
  local -r actual="$(image_base_sha)"
  assert_equal "${expected}" "${actual}"

  # tag
  docker tag "$(image_name):latest" "$(image_name):$(git_commit_tag)"

  echo
  echo "  echo CYBER_DOJO_LANGUAGES_START_POINTS_SHA=$(git_commit_sha)"
  echo "  echo CYBER_DOJO_LANGUAGES_START_POINTS_TAG=$(git_commit_tag)"
  echo
  echo "$(image_name):$(git_commit_tag)"
}


# - - - - - - - - - - - - - - - - - - - - - - - -
assert_equal()
{
  local -r expected="${1}"
  local -r actual="${2}"
  if [ "${expected}" != "${actual}" ]; then
    echo ERROR
    echo "expected:'${expected}'"
    echo "  actual:'${actual}'"
    exit 42
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - -
cyber_dojo()
{
  local -r name=cyber-dojo
  if [ -x "$(command -v ${name})" ]; then
    >&2 echo "Found executable ${name} on the PATH"
    echo "${name}"
  else
    local -r url="https://raw.githubusercontent.com/cyber-dojo/commander/master/${name}"
    >&2 echo "Did not find executable ${name} on the PATH"
    >&2 echo "Curling it from ${url}"
    curl --fail --output "${TMP_DIR}/${name}" --silent "${url}"
    chmod 700 "${TMP_DIR}/${name}"
    echo "${TMP_DIR}/${name}"
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - -
build_test_tag
