#!/usr/bin/env bash
set -Eeu

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function print_durations_to_files()
{
  for colour in red amber green mean; do
    "${MY_DIR}/../bin/concat_all_durations.py" "${colour}" \
      > "${MY_DIR}/../docs/durations.${colour}"
  done

}

if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  print_durations_to_files
fi
