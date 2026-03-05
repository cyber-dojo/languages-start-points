#!/usr/bin/env bash
set -Eeu

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${MY_DIR}/all_start_points.sh"
source "${MY_DIR}/update_one_start_point.sh"

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
  for name in "${ALL_START_POINTS[@]}"
  do
    update_one_start_point "${name}" # eg csharp-nunit
  done
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  check_args "$@"
  update_all_start_points
fi
