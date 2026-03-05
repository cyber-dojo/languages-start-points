#!/usr/bin/env bash
set -Eeu

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${MY_DIR}/all_start_points.sh"

readonly URLS_FILENAME="${MY_DIR}/../git_repo_urls.tagged"

echo -n "" > "${URLS_FILENAME}"

IFS=$'\n' sorted=($(sort -n -k1 <<<"${ALL_START_POINTS[*]}")); unset IFS

for name in "${sorted[@]}"
do
  dir_name="${MY_DIR}/../data/${name}"
  cat "${dir_name}/git_repo.url" >> "${URLS_FILENAME}"
  echo "${name}"
done
