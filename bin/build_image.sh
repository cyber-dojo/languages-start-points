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

    Use: ./bin/${MY_NAME}

    Creates a languages-start-point image containing all the
    start-points specified in the file git_repo_urls.tagged
    You can build git_repo_urls.tagged from the data/*/git_repo.url 
    files using the script bin/concat_all_start_points.sh
    The tag of the created image will be the short-sha of this 
    languages-start-points repo.

    Example:
      \$ ./bin/${MY_NAME}
      ...
      git clone https://github.com/cyber-dojo-start-points/bash-bats
      git checkout 62d4547
      --languages 	 62d4547@https://github.com/cyber-dojo-start-points/bash-bats
      git clone https://github.com/cyber-dojo-start-points/bash-shunit2
      git checkout ededcb8
      --languages 	 ededcb8@https://github.com/cyber-dojo-start-points/bash-shunit2
      git clone https://github.com/cyber-dojo-start-points/bash-unit
      git checkout 6011b21
      --languages 	 6011b21@https://github.com/cyber-dojo-start-points/bash-unit
      git clone https://github.com/cyber-dojo-start-points/clang-assert
      git checkout 95f9402
      ...
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
function build_test_tag()
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
  build_test_tag
fi
