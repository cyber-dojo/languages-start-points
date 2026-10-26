#!/usr/bin/env bash
set -Eeu

readonly LANGUAGES_REFERENCE='ghcr.io/cyber-dojo-languages/*'

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Prints usage help to stdout and is shown for -h/--help.
function show_help()
{
    local -r MY_NAME=$(basename "${BASH_SOURCE[0]}")
    cat <<- EOF

    Use: ./bin/${MY_NAME} [-h|--help]

    Removes every local ${LANGUAGES_REFERENCE} image, tagged or
    not. None needs keeping: each script that uses one pulls it.

    Options:
      -h, --help  Show this help

    Example:
      \$ ./bin/${MY_NAME}

EOF
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Removes every language image by ID, which takes all its tags and an
# untagged one alike.
function remove_language_images()
{
  local -r ids="$(docker image ls --quiet --filter reference="${LANGUAGES_REFERENCE}" | sort --unique)"
  if [ -n "${ids}" ]; then
    # shellcheck disable=SC2086 # one ID per word
    docker image rm --force ${ids} > /dev/null
  fi
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  case "${1:-}" in
    '-h' | '--help')
      show_help
      exit 0
      ;;
  esac
  remove_language_images
fi
