#!/usr/bin/env bash
set -Eeu

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${MY_DIR}/lib.sh"

readonly DOCKERHUB=https://hub.docker.com/v2/repositories
readonly TMP_DIR=$(mktemp -d /tmp/cyber-dojo.languages-start-points.build.XXXXXX)

function remove_tmps()
{
   rm -rf "${TMP_DIR}" > /dev/null
}
trap remove_tmps INT EXIT

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function show_help()
{
    local -r MY_NAME=$(basename "${BASH_SOURCE[0]}")
    cat <<- EOF

    Use: ./bin/${MY_NAME} [START-POINT-NAME]

    Updates the file data/[START-POINT-NAME]/git_repo.url
    so its contents reflect the most recent version of 
    https://github.com/cyber-dojo-start-points/START-POINT-NAME

    Typically followed by:
    \$ make concat_all_start_points
    \$ make image

    Example:
      \$ ./bin/${MY_NAME} gcc-assert
      80c713e@https://github.com/cyber-dojo-start-points/gcc-assert
      121608680 ghcr.io/cyber-dojo-languages/gcc_assert:98e787d 115.97 MiB

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
function update_one_start_point()
{
  local -r name="${1}" # eg csharp-nunit
  local -r url="https://github.com/cyber-dojo-start-points/${1}"
  local repo_dir="${TMP_DIR}"
  rm -rf "${repo_dir}"
  mkdir "${repo_dir}"
  git clone "${url}" "${repo_dir}" > /dev/null 2>&1
  get_tagged_repo_url "${name}" "${repo_dir}"
  get_compressed_image_size "${name}" "${repo_dir}"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function get_tagged_repo_url()
{
  local -r name="${1}"
  local -r repo_dir="${2}"
  local -r sha="$(cd "${repo_dir}" && git rev-parse HEAD)"
  local -r tag=${sha:0:7}
  echo "${tag}@${url}" | tee  "${MY_DIR}/../data/${name}/git_repo.url"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function get_compressed_image_size()
{
  local -r name="${1}"
  local -r repo_dir="${2}"

  local -r filename="${repo_dir}/start_point/manifest.json"
  local -r image_name=$(jq --raw-output '.image_name' "${filename}")      # Eg ghcr.io/cyber-dojo-languages/csharp_nunit:70e19ed
  local -r untagged="$(echo "${image_name}" | awk -F: '{print $(NF-1)}')" # Eg ghcr.io/cyber-dojo-languages/csharp_nunit
  local -r tag="$(echo "${image_name}" | awk -F: '{print $(NF)}')"        # Eg 70e19ed

  # Since we're in the process of moving images from DockerHub to GHCR, 
  # we need to handle both cases
  local size
  if on_GHCR "${image_name}"; then
    # Get the sha digest for the amd image (since we now create both amd and arm)
    sha=$(docker manifest inspect "${image_name}" | jq -r '.manifests[] | select(.platform.architecture | contains ("amd")) | .digest')
    size=$(docker manifest inspect "${untagged}@${sha}" | jq -r '.config.size + ([.layers[].size] | add)' )
  else
    size=$(curl --silent "${DOCKERHUB}/${untagged}/tags/${tag}" | jq '.full_size') # 227987976
  fi

  local -r human=$(human_size "${size}")                                           # 217.42 MiB
  echo "${size} ${image_name} ${human}" | tee "${MY_DIR}/../data/${name}/compressed_image.size"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function on_GHCR()
{
  local -r image_name="${1}"
  local -r start="$(echo "${image_name}" | awk -F '/' '{print $1}')"
  [ "${start}" == "ghcr.io" ]
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function human_size()
{
    local i=${1:-0}
    local d=""
    local s=0
    local S=("Bytes" "KiB" "MiB" "GiB" "TiB" "PiB" "EiB" "YiB" "ZiB")
    while ((i > 1024 && s < ${#S[@]}-1)); do
        printf -v d ".%02d" $((i % 1024 * 100 / 1024))
        i=$((i / 1024))
        s=$((s + 1))
    done
    echo "${i}${d} ${S[$s]}"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
    check_args "$@"
    update_one_start_point "${1}"
fi
