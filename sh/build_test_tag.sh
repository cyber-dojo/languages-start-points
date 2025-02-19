#!/usr/bin/env bash
set -Eeu

repo_root() { git rev-parse --show-toplevel; }

readonly SH_DIR="$(repo_root)/sh"
readonly TMP_DIR=$(mktemp -d /tmp/cyber-dojo.languages-start-points.XXXXXXXXX)
trap "rm -rf ${TMP_DIR} > /dev/null" INT EXIT
source "${SH_DIR}/lib.sh"
source "${SH_DIR}/echo_env_vars.sh"
export $(echo_env_vars)

# - - - - - - - - - - - - - - - - - - - - - - - -
build_test_tag()
{
  local -r image=cyberdojo/languages-start-points
  local -r names="$(cat "$(repo_root)/git_repo_urls.tagged" | tr '\n' ' ')"

  # build
  export GIT_COMMIT_SHA="$(git_commit_sha)"
  $(cyber_dojo) start-point create "$(image_name)" --languages "${names}"
  unset GIT_COMMIT_SHA

  # test
  assert_equal "$(git_commit_sha)" "$(image_sha)"

  # tag
  docker tag "$(image_name):latest" "$(image_name):$(git_commit_tag)"
  echo "tagged with :$(git_commit_tag)"
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
