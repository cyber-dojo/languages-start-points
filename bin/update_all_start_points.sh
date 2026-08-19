#!/usr/bin/env bash
set -Eeu

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${MY_DIR}/all_start_points.sh"
source "${MY_DIR}/lib.sh"

# Set when Ctrl-C arrives. bash defers the handler until the start-point running
# in the foreground has finished, so the flag is read between start-points.
interrupted=''
trap 'interrupted=1' INT

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function show_help()
{
    local -r MY_NAME=$(basename "${BASH_SOURCE[0]}")
    cat <<- EOF

    Use: ./bin/${MY_NAME}

    Refreshes all the data/*/git_repo.url files by iterating
    over ALL_START_POINTS from bin/all_start_points.sh 
    
    Typically followed by:
    \$ make concat_all_start_points
    \$ make image

    Example:
      \$ ./bin/${MY_NAME}
      62d4547@https://github.com/cyber-dojo-start-points/bash-bats
      22082016 ghcr.io/cyber-dojo-languages/bash_bats:cc4f391 21.05 MiB
      ededcb8@https://github.com/cyber-dojo-start-points/bash-shunit2
      18841258 ghcr.io/cyber-dojo-languages/bash_shunit2:07becff 17.96 MiB
      6011b21@https://github.com/cyber-dojo-start-points/bash-unit
      18835421 ghcr.io/cyber-dojo-languages/bash_unit:19b5bea 17.96 MiB
      ...    

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

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function update_all_start_points()
{
  local -r total="${#ALL_START_POINTS[@]}"
  local index=0
  local -a failed=()
  local status
  for name in "${ALL_START_POINTS[@]}"
  do
    index=$((index + 1))
    echo "[${index}/${total}] ${name}"
    # A separate process per start-point. Calling a function from an
    # if-condition suspends set -e for that function's whole body, so a failed
    # clone or pull would carry on to the next step instead of stopping.
    status=0
    "${MY_DIR}/update_one_start_point.sh" "${name}" || status=$? # eg csharp-nunit
    # A status of 128 or more means a signal ended it, which is a reason to stop
    # rather than to record one bad start-point and continue.
    if [ -n "${interrupted}" ] || [ "${status}" -ge 128 ]; then
      stderr "interrupted during [${index}/${total}] ${name}"
      exit 130
    fi
    if [ "${status}" != '0' ]; then
      failed+=("[${index}/${total}] ${name}")
    fi
  done
  if [ "${#failed[@]}" != '0' ]; then
    stderr "${#failed[@]} of ${total} start-points did not update:"
    local entry
    for entry in "${failed[@]}"; do
      stderr "  ${entry}"
    done
    stderr "re-run one with: ./bin/update_one_start_point.sh NAME"
    exit_non_zero
  fi
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  check_args "$@"
  update_all_start_points
fi
