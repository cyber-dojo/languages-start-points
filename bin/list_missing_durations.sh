#!/usr/bin/env bash
set -Eeu

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${MY_DIR}/all_start_points.sh"

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function list_missing_durations()
{
  for name in "${ALL_START_POINTS[@]}"
  do
    filename="${MY_DIR}/../data/${name}/durations.json"
    if [ ! -f "${filename}" ]; then
      echo "${name}"
    fi
  done
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  list_missing_durations
fi
