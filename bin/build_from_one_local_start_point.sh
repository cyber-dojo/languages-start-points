#!/usr/bin/env bash
set -Eeu

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${BIN_DIR}/lib.sh"
source "${BIN_DIR}/echo_env_vars.sh"
export $(echo_env_vars)
readonly TMP_DIR=$(mktemp -d /tmp/cyber-dojo.languages-start-points.XXXXXXXXX)
trap 'rm -rf ${TMP_DIR} > /dev/null' INT EXIT

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function show_help()
{
    local -r MY_NAME=$(basename "${BASH_SOURCE[0]}")
    cat <<- EOF

    Use: ./bin/${MY_NAME} [DIR]

    Creates a languages-start-point image containing the single
    start-point in [DIR]. The tag of the created image
    will be the short-sha of this languages-start-points repo.

    Often followed by running a local demo using the languages-start-point 
    image by:
    - moving to the web repo 
    - adding the two printed echo commands to the end of the echo_env_vars() 
      function in bin/echo_env_vars.sh 
    - make demo

    Example:
      \$ ./bin/${MY_NAME} /Users/jonjagger/repos/cyber-dojo-start-points/gcc-assert
      ...
      git clone file:///Users/jonjagger/repos/cyber-dojo-start-points/gcc-assert
      git checkout 3520429
      --languages 3520429@file:///Users/jonjagger/repos/cyber-dojo-start-points/gcc-assert
      Successfully built cyberdojo/languages-start-points

        echo CYBER_DOJO_LANGUAGES_START_POINTS_SHA=28ee25583a31b319da305ccab1b7311613e2a915
        echo CYBER_DOJO_LANGUAGES_START_POINTS_TAG=28ee255

      cyberdojo/languages-start-points:28ee255

EOF
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function check_args()
{
  case "${1:-}" in
    '-h' | '--help')
      show_help
      exit 0
      ;;
  esac
}

# - - - - - - - - - - - - - - - - - - - - - - - -
function build_from_one_local_start_point()
{
  local -r dir="${1}" # /Users/jonjagger/repos/cyber-dojo-start-points/gcc-assert
  local -r head_sha="$(echo_head_sha "${dir}")"
  local -r url="${head_sha}@file://${dir}"

  # Ensure latest env-vars are tunnelled into cyber_dojo -> cyber_dojo_inner script.
  export $(docker run --rm cyberdojo/versioner:latest)

  # build
  $(cyber_dojo) start-point create "$(image_name)" --languages "${url}"

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
function echo_head_sha()
{
  local -r dir="${1}"
  echo "$(cd "${dir}" && git rev-parse --short HEAD)"
}

# - - - - - - - - - - - - - - - - - - - - - - - -
function assert_equal()
{
  local -r expected="${1}"
  local -r actual="${2}"
  if [ "${expected}" != "${actual}" ]; then
    stderr "expected:'${expected}'"
    stderr "  actual:'${actual}'"
    exit_non_zero
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - -
function cyber_dojo()
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
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  check_args "$@"
  build_from_one_local_start_point "$@"
fi
