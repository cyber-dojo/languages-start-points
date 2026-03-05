#!/usr/bin/env bash
set -Eeu

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${MY_DIR}/all_start_points.sh"

readonly URLS_FILENAME="${MY_DIR}/../git_repo_urls.tagged"

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function show_help()
{
    local -r MY_NAME=$(basename "${BASH_SOURCE[0]}")
    cat <<- EOF

    Use: ./bin/${MY_NAME}

    Concatenates all the files data/*/git_repo.url into the file
    git_repo_urls.tagged 
    
    Typically followed by:
    \$ make image

    Example:
      \$ ./bin/${MY_NAME}
      bash-bats
      bash-shunit2
      bash-unit
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
function concat_all_start_points()
{
  echo -n "" > "${URLS_FILENAME}"
  IFS=$'\n' sorted=($(sort -n -k1 <<<"${ALL_START_POINTS[*]}")); unset IFS
  for name in "${sorted[@]}"
  do
    dir_name="${MY_DIR}/../data/${name}"
    cat "${dir_name}/git_repo.url" >> "${URLS_FILENAME}"
    echo "${name}"
  done
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  check_args "$@"
  concat_all_start_points
fi


