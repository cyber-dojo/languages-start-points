#!/usr/bin/env bash
set -Eeu

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${MY_DIR}/lib.sh"

readonly ALL_START_POINTS_FILENAME="${MY_DIR}/all_start_points.sh"
readonly TMP_DIR=$(mktemp -d /tmp/cyber-dojo.languages-start-points.add.XXXXXX)
function remove_tmps() { rm -rf "${TMP_DIR}" > /dev/null; }
trap 'remove_tmps; exit 130' INT
trap remove_tmps EXIT

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function show_help()
{
    local -r MY_NAME=$(basename "${BASH_SOURCE[0]}")
    cat <<- EOF

    Use: ./bin/${MY_NAME} [START-POINT-NAME]

    Brings one start-point into the repo, measuring only that one.
    - creates data/[START-POINT-NAME] holding durations.json,
      rag_results.json, git_repo.url and compressed_image.size
    - adds START-POINT-NAME to the ALL_START_POINTS array in
      bin/all_start_points.sh, in sorted position
    - rebuilds git_repo_urls.tagged
    - rebuilds docs/durations.red|amber|green|mean

    This is what \$ make all_start_points does, except that it measures
    the one named start-point instead of all of them. The two rebuilt
    files are read off disk, so they still cover every start-point.

    Re-running for an already-listed name re-measures it, which is the
    way to refresh one start-point and both aggregate files.

    Typically followed by:
    \$ make image

    Options:
      -h    Show this help

    Example:
      \$ ./bin/${MY_NAME} typescript-vitest

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
    '')
      show_help
      stderr "no argument - must be name of https://github.com/cyber-dojo-start-points repo"
      exit_non_zero
      ;;
  esac
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function listed_in_all_start_points()
{
  local -r name="${1}" # eg typescript-vitest
  grep --quiet "^  ${name}\$" "${ALL_START_POINTS_FILENAME}"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# concat_all_start_points.sh iterates ALL_START_POINTS rather than data/, so a
# name missing from the array is left out of git_repo_urls.tagged silently, and
# the start-point is absent from the image. Inserting it here is what makes one
# command enough to add one.
function insert_into_all_start_points()
{
  local -r name="${1}"
  if listed_in_all_start_points "${name}"; then
    echo "${name} is already in ALL_START_POINTS"
    return
  fi
  # Sorted position, matching the order the array is already written in, so the
  # diff is one added line where a reader would look for the name. The first
  # rule catches a name sorting after every entry, whose place is the line
  # closing the array.
  local -r inserted="${TMP_DIR}/all_start_points.sh"
  awk -v entry="  ${name}" '
    !inserted && /^\)$/                   { print entry; inserted = 1 }
    !inserted && /^  [a-z]/ && entry < $0 { print entry; inserted = 1 }
    { print }
  ' "${ALL_START_POINTS_FILENAME}" > "${inserted}"
  if ! grep --quiet "^  ${name}\$" "${inserted}"; then
    stderr "${name} could not be inserted into ${ALL_START_POINTS_FILENAME}"
    exit_non_zero
  fi
  # cp rather than mv, so the file keeps its own permissions.
  cp "${inserted}" "${ALL_START_POINTS_FILENAME}"
  echo "Added ${name} to bin/all_start_points.sh"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function add_one_start_point()
{
  local -r name="${1}" # eg typescript-vitest

  # Measuring before listing the name is what leaves the repo as it was when a
  # start-point cannot be measured: update_one_start_point.sh removes the data
  # dir it created, and the array is not yet claiming data that is not there.
  echo "[1/3] measuring ${name}"
  "${MY_DIR}/update_one_start_point.sh" "${name}"

  echo "[2/3] rebuilding git_repo_urls.tagged"
  insert_into_all_start_points "${name}"
  # Its per-start-point progress lines say nothing new here; the grep below
  # reports the one line this run is adding.
  "${MY_DIR}/concat_all_start_points.sh" > /dev/null
  grep "/${name}\$" "${MY_DIR}/../git_repo_urls.tagged"

  echo "[3/3] rebuilding docs/durations.red|amber|green|mean"
  "${MY_DIR}/print_durations_to_files.sh"
  grep " ${name}\$" "${MY_DIR}/../docs/durations.mean"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  exit_non_zero_unless_installed jq
  check_args "$@"
  add_one_start_point "${1}"
fi
