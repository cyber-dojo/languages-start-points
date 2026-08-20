#!/usr/bin/env bash
set -Eeu

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${MY_DIR}/lib.sh"

readonly DOCKERHUB=https://hub.docker.com/v2/repositories
readonly TMP_DIR=$(mktemp -d /tmp/cyber-dojo.languages-start-points.build.XXXXXX)
function remove_tmps() { rm -rf "${TMP_DIR}" > /dev/null; }
# Ctrl-C must end this process, not just clean up and carry on to the next
# statement. 130 is the conventional status for death by SIGINT, and the caller
# looping over all start-points uses it to stop the whole run.
trap 'remove_tmps; exit 130' INT
trap remove_tmps EXIT

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
        "mean_duration": "0.5421297503333333",
        "architecture": "arm64"
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
  # Every step below exits non-zero on failure, which leaves this start-point's
  # data files as they were. The caller looping over all start-points runs this
  # script as a separate process, so one bad start-point does not end the loop.
  get_red_amber_green_durations "${name}" "${repo_dir}"
  get_tagged_repo_url           "${name}" "${repo_dir}"
  get_compressed_image_size     "${name}" "${repo_dir}"
  # Only on the success path, so a start-point that failed keeps its image for
  # investigating.
  remove_other_tags_of_image "$(jq --raw-output .image_name "${repo_dir}/start_point/manifest.json")"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# A start-point's manifest pins one tag of its language image, and every earlier
# tag still sitting in the local store is dead weight. Across 83 start-points
# those add up to more than the disk holds, so they go as each start-point is
# measured. The pinned tag stays, which keeps the next run's pull warm.
function remove_other_tags_of_image()
{
  local -r image_name="${1}"             # eg ghcr.io/cyber-dojo-languages/gcc_assert:98e787d
  local -r repository="${image_name%:*}" # eg ghcr.io/cyber-dojo-languages/gcc_assert
  local tagged_name
  for tagged_name in $(docker image ls --format '{{.Repository}}:{{.Tag}}' "${repository}")
  do
    if [ "${tagged_name}" != "${image_name}" ]; then
      echo "Removing superseded ${tagged_name}"
      docker image rm --force "${tagged_name}" || echo "  ${tagged_name} not removed"
    fi
  done
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# True when the last run judged all three lights, whatever their verdicts.
function all_rag_run_files_exist()
{
  local colour
  for colour in red amber green; do
    if [ ! -f "${CYBER_DOJO_RAG_RUN_FILE_PREFIX}.${colour}.json" ]; then
      return 1
    fi
  done
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Empty for every start-point whose image runs natively on any host. nasm
# assembles to x86-64 objects only (nasm -f elf64), which gcc on an arm64 host
# cannot link, so all three lights fall through to amber and the amber one
# "passes" only because amber is the fallback verdict. Emulating amd64 is what
# lets red and green be reached at all. The architecture recorded in
# durations.json marks these times as not comparable with the native ones.
function required_platform()
{
  local -r name="${1}" # eg nasm-assert
  case "${name}" in
    nasm-assert) echo linux/amd64 ;;
    *)           echo '' ;;
  esac
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function get_red_amber_green_durations()
{
  local -r name="${1}"
  local -r repo_dir="${2}"
  local -r log_dir="${MY_DIR}/../logs/${name}"
  # Start from an empty log dir so a file this run fails to produce cannot be
  # mistaken for the one a previous run left there.
  rm -rf "${log_dir}"
  mkdir -p "${log_dir}"

  # Pull image_name used in red_amber_green_test.sh before running it, to avoid
  # an implicit initial docker-pull peturbing the durations. A start-point gets
  # the variant matching this host unless required_platform names one, because
  # emulating a foreign architecture inflates the durations unevenly between
  # languages, which distorts their ranking, and ranking is what these numbers
  # are read for.
  #
  # The runner creates the language container with no --platform of its own, so
  # the variant this pull leaves in the local store is the one the test runs on.
  local -r image_name="$(jq --raw-output .image_name "${repo_dir}/start_point/manifest.json")"
  local -r platform="$(required_platform "${name}")"
  # Unquoted on purpose: empty must expand to no argument at all, and the value
  # is a literal with no spaces.
  DOCKER_CLI_HINTS=false docker pull ${platform:+--platform ${platform}} "${image_name}"

  # Which architecture the durations below were actually measured on. An image
  # published for this host runs natively; one without a matching variant runs
  # emulated, and its times are not comparable with the rest.
  local -r architecture="$(docker image inspect --format '{{.Architecture}}' "${image_name}")"

  # Now run red_amber_green_test.sh with magic env-var to capture test durations
  export CYBER_DOJO_RAG_RUN_FILE_PREFIX=/tmp/hiker_run

  # Updating every start-point in one go keeps the machine busy, so the
  # traffic-light containers get longer than the shared script's default to
  # answer their readiness check.
  export CYBER_DOJO_START_POINT_READY_TRIES=50

  # The traffic-light containers sometimes lose their readiness race on a busy
  # machine. Retrying turns that flake into a pass, rather than a false report
  # that this start-point is broken.
  local -r max_attempts=2
  local attempt=1
  local rag_status
  local colour
  while true; do
    # Clear the run files of any earlier attempt, so this attempt's results
    # cannot be read alongside them.
    for colour in red amber green; do
      rm -f "${CYBER_DOJO_RAG_RUN_FILE_PREFIX}.${colour}.json"
    done
    # tee preserves the whole attempt for later auditing. Reading PIPESTATUS on
    # the very next line is what keeps the attempt's exit status visible: tee
    # exits zero even when the run it copies failed, and any command in between
    # would overwrite PIPESTATUS.
    "$(red_amber_green_test)" "${repo_dir}" 2>&1 | tee "${log_dir}/run.attempt-${attempt}.log"
    rag_status="${PIPESTATUS[0]}"
    if [ "${rag_status}" == '0' ]; then
      break
    fi
    # A run that produced all three files got as far as judging every light, so
    # its verdicts are on disk and the checks below report them. Retrying that
    # would only repeat a real failure. A missing file means the run died early,
    # which is the flake the retry exists for.
    if all_rag_run_files_exist; then
      break
    fi
    if [ "${attempt}" == "${max_attempts}" ]; then
      stderr "${name}: red_amber_green_test.sh exited ${rag_status} on all ${max_attempts} attempts, see ${log_dir}"
      exit_non_zero
    fi
    stderr "${name}: red_amber_green_test.sh exited ${rag_status} on attempt ${attempt}, retrying"
    attempt=$((attempt + 1))
  done

  # Check each run file was created and move it out of /tmp straight away, so
  # a later start-point cannot read a file this one left behind.
  local run_file
  for colour in red amber green; do
    run_file="${CYBER_DOJO_RAG_RUN_FILE_PREFIX}.${colour}.json"
    if [ ! -f "${run_file}" ]; then
      stderr "${name}: ${run_file} does not exist, see ${log_dir}"
      exit_non_zero
    fi
    mv "${run_file}" "${log_dir}/${colour}.json"
  done
  unset CYBER_DOJO_RAG_RUN_FILE_PREFIX

  # Record, per requested light, the colour actually reached and the timeout it
  # was allowed. A duration means nothing without them. The keys come from the
  # file order below, not from the JSON: summary.colour is the colour reached,
  # so two lights reaching the same colour would collapse into one key.
  local -r results_filename="${MY_DIR}/../data/${name}/rag_results.json"
  jq --slurp '
    [["red","amber","green"], .] | transpose
    | map({(.[0]): {
        result:      .[1].summary.result,
        reached:     .[1].summary.colour,
        max_seconds: .[1].summary.max_seconds
      }}) | add' \
    "${log_dir}/red.json"   \
    "${log_dir}/amber.json" \
    "${log_dir}/green.json" \
    > "${results_filename}"
  jq . "${results_filename}"

  # A duration only means something if its light was actually reached. Stopping
  # here is what keeps a timed-out light from being recorded as a good time.
  local -r failed_lights="$(jq --raw-output \
    'to_entries | map(select(.value.result != "PASSED") | .key) | join(" ")' \
    "${results_filename}")"
  if [ -n "${failed_lights}" ]; then
    stderr "${name}: light(s) not reached: ${failed_lights}, see ${results_filename}"
    exit_non_zero
  fi

  # Every light passed, so a non-zero run means something else went wrong and
  # the durations cannot be trusted.
  if [ "${rag_status}" != '0' ]; then
    stderr "${name}: every light passed but red_amber_green_test.sh exited ${rag_status}, see ${log_dir}"
    exit_non_zero
  fi

  # Get the durations
  local -r red_duration="$(jq .summary.duration "${log_dir}/red.json")"
  local -r amber_duration="$(jq .summary.duration "${log_dir}/amber.json")"
  local -r green_duration="$(jq .summary.duration "${log_dir}/green.json")"
  local -r all="[${red_duration},${amber_duration},${green_duration}]"
  local -r mean_duration="$(jq '[.. | numbers] | add / length' <<< "${all}")"

  # Put them into a single JSON file
  local -r durations_filename="${MY_DIR}/../data/${name}/durations.json"
  jq --arg red_duration   "${red_duration}"   \
     --arg amber_duration "${amber_duration}" \
     --arg green_duration "${green_duration}" \
     --arg mean_duration  "${mean_duration}"  \
     --arg architecture   "${architecture}"   \
     '$ARGS.named' <<< '{}' > "${durations_filename}"

  jq . "${durations_filename}"
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
  local -r local_clone="${MY_DIR}/../../../cyber-dojo-start-points/shared-scripts/${name}"
  if [ -x "$(command -v ${name})" ]; then
    >&2 echo "Found ${name} on the PATH"
    echo "${name}"
  elif [ -x "${local_clone}" ]; then
    >&2 echo "Found ${name} in the local shared-scripts clone"
    echo "${local_clone}"
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
