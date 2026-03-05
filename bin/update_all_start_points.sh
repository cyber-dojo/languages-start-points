#!/usr/bin/env bash
set -Eeu

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${MY_DIR}/all_start_points.sh"
source "${MY_DIR}/update_one_start_point.sh"

function update_all_start_points()
{
  for i in "${!ALL_START_POINTS[@]}"
  do
    local name="${ALL_START_POINTS[$i]}"  # eg csharp-nunit
    update_one_start_point "${name}"
  done
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  update_all_start_points
fi
