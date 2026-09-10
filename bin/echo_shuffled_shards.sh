#!/usr/bin/env bash
set -Eeu

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${MY_DIR}/all_start_points.sh"
source "${MY_DIR}/lib.sh"

# Matches max-parallel in refresh.yml. Splitting into more shards than can run
# at once makes each one pay its own setup cost without any finishing sooner.
readonly DEFAULT_SHARD_COUNT=10

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Prints the help text.
function show_help()
{
    local -r MY_NAME=$(basename "${BASH_SOURCE[0]}")
    cat <<- EOF

    Use: ./bin/${MY_NAME} [SHARD-COUNT]

    Shuffles ALL_START_POINTS from bin/all_start_points.sh, splits it into
    SHARD-COUNT groups, and echoes them as a one-line JSON array, ready to be
    read as a GitHub Actions matrix. Each entry holds
      id     names the matrix job
      names  the group's start-point names, space separated, ready for
             ./bin/update_all_start_points.sh

    SHARD-COUNT defaults to ${DEFAULT_SHARD_COUNT}.

    Shuffled because the language images run from tens of MiB to over a GiB and
    pulling them is most of what a refresh spends its time on. Splitting the
    list in its published order would put whole families of big images, which
    sort together by name, into a shard of their own.

    Options:
      -h    Show this help

    Example:
      \$ ./bin/${MY_NAME} 3 | jq .
      [
        {
          "id": "1",
          "names": "java-junit bash-bats swift-xctest"
        },
        ...
      ]

EOF
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Exits unless "${1}" is a shard count that can be split into.
function check_args()
{
  case "${1:-}" in
    '-h' | '--help')
      show_help
      exit 0
      ;;
  esac
  if [ -n "${1:-}" ] && ! [[ "${1}" =~ ^[1-9][0-9]*$ ]]; then
    show_help
    stderr "SHARD-COUNT must be a positive integer, got '${1}'"
    exit_non_zero
  fi
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Echoes every start-point, one per line, in a random order. Shuffled in bash
# rather than by shuf, which is not on a mac, where these scripts also run.
function echo_shuffled_start_points()
{
  local -a names=("${ALL_START_POINTS[@]}")
  local index
  local pick
  local swap
  for ((index = ${#names[@]} - 1; index > 0; index--))
  do
    pick=$((RANDOM % (index + 1)))
    swap="${names[index]}"
    names[index]="${names[pick]}"
    names[pick]="${swap}"
  done
  printf '%s\n' "${names[@]}"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Echoes the shards as a JSON array, dealing the shuffled start-points round
# robin so the shards differ in size by at most one start-point.
function echo_shuffled_shards()
{
  local -r count="${1}"
  local -a shard_names=()
  local index
  for ((index = 0; index < count; index++))
  do
    shard_names[index]=''
  done

  index=0
  local name
  while read -r name
  do
    shard_names[index]="${shard_names[index]:+${shard_names[index]} }${name}"
    index=$(((index + 1) % count))
  done < <(echo_shuffled_start_points)

  # A shard with no names is dropped rather than emitted. Asked for more shards
  # than there are start-points, the tail of them would hold nothing, and
  # update_all_start_points.sh given no names updates every start-point.
  local records=''
  for ((index = 0; index < count; index++))
  do
    if [ -n "${shard_names[index]}" ]; then
      records+="${shard_names[index]}"$'\n'
    fi
  done

  jq --raw-input --slurp --compact-output '
    split("\n")
    | map(select(length > 0))
    | to_entries
    | map({
        id:    (.key + 1 | tostring),
        names: .value
      })
  ' <<< "${records}"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  exit_non_zero_unless_installed jq
  check_args "$@"
  echo_shuffled_shards "${1:-${DEFAULT_SHARD_COUNT}}"
fi
