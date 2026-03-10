#!/usr/bin/env bash
set -Eeu

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${MY_DIR}/lib.sh"

readonly DOCKERHUB=https://hub.docker.com/v2/repositories
readonly TMP_DIR=$(mktemp -d /tmp/cyber-dojo.languages-start-points.build.XXXXXX)
function remove_tmps() { rm -rf "${TMP_DIR}" > /dev/null; }
trap remove_tmps INT EXIT

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function show_help()
{
    local -r MY_NAME=$(basename "${BASH_SOURCE[0]}")
    cat <<- EOF

    Use: ./bin/${MY_NAME} [START-POINT-NAME]

    Updates the files in data/[START-POINT-NAME]
    - durations.json
      A summary of the red/amber/green test runs
    - git_repo.url
      The most recent commit of 
      https://github.com/cyber-dojo-start-points/[START-POINT-NAME]
    - compressed_image.size
      The size and full registry path of the docker image 

    Typically followed by:
    \$ make concat_all_start_points
    \$ make image

    Example:
      \$ ./bin/${MY_NAME} gcc-assert
      {
        "red_duration": "0.788800584",
        "amber_duration": "0.362212917",
        "green_duration": "0.47537575",
        "mean_duration": "0.5421297503333333"
      }
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
  git clone "${url}" "${repo_dir}" &> /dev/null
  get_red_amber_green_durations "${name}" "${repo_dir}"
  get_tagged_repo_url           "${name}" "${repo_dir}"
  get_compressed_image_size     "${name}" "${repo_dir}"
}

function get_red_amber_green_durations()
{
  local -r name="${1}"
  local -r repo_dir="${2}"

  # Pull image_name used in red_amber_green_test.sh before running
  # it to avoid implicit initial docker-pull peturbing the durations.

  local -r image_name="$(jq --raw-output .image_name "${repo_dir}/start_point/manifest.json")"
  docker pull --platform=linux/amd64 "${image_name}"

  # Now run red_amber_green_test.sh with magic env-var to capture test durations
  export CYBER_DOJO_RAG_RUN_FILE_PREFIX=/tmp/hiker_run

  "$(red_amber_green_test)" "${repo_dir}"  

  # Check test duration files were created
  exit_non_zero_unless_file_exists "${CYBER_DOJO_RAG_RUN_FILE_PREFIX}.red.json"
  exit_non_zero_unless_file_exists "${CYBER_DOJO_RAG_RUN_FILE_PREFIX}.amber.json"
  exit_non_zero_unless_file_exists "${CYBER_DOJO_RAG_RUN_FILE_PREFIX}.green.json"

  # Get the durations
  local -r red_duration="$(jq .summary.duration "${CYBER_DOJO_RAG_RUN_FILE_PREFIX}.red.json")"
  local -r amber_duration="$(jq .summary.duration "${CYBER_DOJO_RAG_RUN_FILE_PREFIX}.amber.json")"
  local -r green_duration="$(jq .summary.duration "${CYBER_DOJO_RAG_RUN_FILE_PREFIX}.green.json")"
  local -r all="[${red_duration},${amber_duration},${green_duration}]"
  local -r mean_duration="$(jq '[.. | numbers] | add / length' <<< "${all}")"

  # Put them into a single JSON file
  local -r durations_filename="${MY_DIR}/../data/${name}/durations.json"
  jq --arg red_duration   "${red_duration}"   \
     --arg amber_duration "${amber_duration}" \
     --arg green_duration "${green_duration}" \
     --arg mean_duration  "${mean_duration}"  \
     '$ARGS.named' <<< '{}' > "${durations_filename}"

  jq . "${durations_filename}"

  # Clean up
  rm "${CYBER_DOJO_RAG_RUN_FILE_PREFIX}.red.json"
  rm "${CYBER_DOJO_RAG_RUN_FILE_PREFIX}.amber.json"
  rm "${CYBER_DOJO_RAG_RUN_FILE_PREFIX}.green.json"
  unset CYBER_DOJO_RAG_RUN_FILE_PREFIX
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function get_tagged_repo_url()
{
  local -r name="${1}"
  local -r repo_dir="${2}"
  local -r sha="$(cd "${repo_dir}" && git rev-parse HEAD)"
  local -r tag=${sha:0:7}
  echo "${tag}@${url}" | tee "${MY_DIR}/../data/${name}/git_repo.url"
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
function red_amber_green_test()
{
  local -r name=red_amber_green_test.sh
  if [ -x "$(command -v ${name})" ]; then
    >&2 echo "Found ${name} on the PATH"
    echo "${name}"
  else
    local -r github=raw.githubusercontent.com
    local -r org=cyber-dojo-start-points
    local -r repo=shared-scripts
    local -r branch=master
    local -r url="https://${github}/${org}/${repo}/${branch}/${name}"
    >&2 echo "Did not find executable ${name} on the PATH"
    >&2 echo "Attempting to curl it from ${url}"
    curl --fail --output "${TMP_DIR}/${name}" --silent "${url}"
    chmod 700 "${TMP_DIR}/${name}"
    echo "${TMP_DIR}/${name}"
  fi
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
  exit_non_zero_unless_installed jq
  check_args "$@"
  update_one_start_point "${1}"
fi
