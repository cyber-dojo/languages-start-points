#!/usr/bin/env bash
set -Eeu

MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default location of the local cyber-dojo-start-points checkouts, relative to
# this repo (languages-start-points/bin -> ../../../cyber-dojo-start-points).
readonly DEFAULT_START_POINTS_DIR="${MY_DIR}/../../../cyber-dojo-start-points"

# Set by parse_args.
START_POINTS_DIR="${DEFAULT_START_POINTS_DIR}"
SINCE=""
MODE="repoints"   # repoints | branches

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Prints usage help to stdout and is shown for -h/--help.
function show_help()
{
    local -r MY_NAME=$(basename "${BASH_SOURCE[0]}")
    cat <<- EOF

    Use: ./bin/${MY_NAME} [--help] [--branches] [--since YYYY-MM-DD] [START_POINTS_DIR]

    Audits the LOCAL cyber-dojo-start-points checkouts. Purely local git
    inspection: no network, no registry auth, no ghcr.io rate-limit traps.

    Modes:

    (default) image repoints
      Reports every start point whose start_point/manifest.json image_name
      has been repointed at ghcr.io, NEWEST REPOINT FIRST, with the commit
      that did it and the previous (DockerHub) image_name it replaced. The
      repoint DATE is the signal: a fresh repoint is the prime suspect for
      breaking 'make all_start_points' with "manifest unknown" (the GHCR
      image has not actually been published yet). The previous image_name
      is the value to revert to (the DockerHub image production still runs).

    --branches  workflow / default-branch mismatch
      Reports every start point whose .github/workflows/main.yml only fires
      on a push branch that is NOT the repo's default branch. That workflow
      can never run (e.g. it triggers on 'main' but the repo is still on
      'master' - a half-finished migration). Default branch is read from
      origin/HEAD, falling back to the checked-out branch, so run after a
      'git fetch' for accurate results.

    Arguments:
      START_POINTS_DIR  Parent dir of the start-point repo checkouts.
                        Default: ${DEFAULT_START_POINTS_DIR}

    Options:
      --branches         Run the workflow/default-branch mismatch audit.
      --since YYYY-MM-DD  (repoints mode) Only show repoints on/after this date.
      -h, --help         Show this help

    Examples:
      \$ ./bin/${MY_NAME} --since 2026-06-01
      \$ ./bin/${MY_NAME} --branches

EOF
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Parses CLI args, setting the START_POINTS_DIR, SINCE and MODE globals.
function parse_args()
{
  while [ $# -gt 0 ]; do
    case "${1}" in
      '-h' | '--help')
        show_help
        exit 0
        ;;
      '--branches')
        MODE="branches"
        ;;
      '--since')
        shift
        [ $# -gt 0 ] || { show_help; >&2 echo "error: --since needs a YYYY-MM-DD value"; exit 1; }
        SINCE="${1}"
        ;;
      '--since='*)
        SINCE="${1#--since=}"
        ;;
      '-'*)
        show_help
        >&2 echo "error: unknown option '${1}'"
        exit 1
        ;;
      *)
        START_POINTS_DIR="${1}"
        ;;
    esac
    shift
  done

  if [ -n "${SINCE}" ] && ! [[ "${SINCE}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    show_help
    >&2 echo "error: --since must be YYYY-MM-DD, got '${SINCE}'"
    exit 1
  fi
  if [ ! -d "${START_POINTS_DIR}" ]; then
    show_help
    >&2 echo "error: start-points dir not found: ${START_POINTS_DIR}"
    exit 1
  fi
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Echoes the most recent commit that changed image_name to ghcr.io in
# one start-point repo, as "<iso-date><TAB><short-sha> <date> <subject>".
# The leading ISO date is a sort key; the rest is for display.
function repoint_commit()
{
  local -r repo="${1}"
  git -C "${repo}" log -1 --format='%cI%x09%h %ci %s' \
    -S 'ghcr.io' -- start_point/manifest.json 2>/dev/null
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Echoes the image_name line that the ghcr.io value replaced (the most
# recent removed image_name in the repoint diff), i.e. the revert target.
function previous_image_name()
{
  local -r repo="${1}"
  git -C "${repo}" log -p -S 'ghcr.io' -- start_point/manifest.json 2>/dev/null \
    | grep -m1 -- '^-.*"image_name"' \
    | sed 's/^-[[:space:]]*//'
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Echoes the repo's default branch: origin/HEAD if known, else the
# currently checked-out branch.
function default_branch()
{
  local -r repo="${1}"
  local db
  db="$(git -C "${repo}" symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null)"
  db="${db#refs/remotes/origin/}"
  [ -n "${db}" ] || db="$(git -C "${repo}" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  echo "${db}"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Echoes the branch names in the FIRST 'branches:' list of a workflow
# file (the push trigger in these repos), one per line. Empty output
# means no branch filter, i.e. the workflow runs on all pushed branches.
function workflow_push_branches()
{
  local -r workflow="${1}"
  awk '
    /branches:/ { grab = 1; next }
    grab && /^[[:space:]]*-/ {
      b = $0
      sub(/^[[:space:]]*-[[:space:]]*/, "", b)
      gsub(/["'\'' ]/, "", b)
      if (b != "") print b
      next
    }
    grab && /[^[:space:]]/ { exit }
  ' "${workflow}"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Audits every start-point checkout, optionally filtered by --since,
# and prints a block per ghcr.io repoint sorted newest-first.
function audit_repointed_images()
{
  local rows=""

  for repo in "${START_POINTS_DIR}"/*/; do
    local manifest="${repo}start_point/manifest.json"
    [ -f "${manifest}" ] || continue

    local current
    current="$(jq --raw-output '.image_name // empty' "${manifest}" 2>/dev/null)"
    case "${current}" in
      ghcr.io/*) ;;
      *) continue ;;
    esac

    local info sortkey display
    info="$(repoint_commit "${repo}")"
    sortkey="${info%%$'\t'*}"
    display="${info#*$'\t'}"

    if [ -n "${SINCE}" ] && [[ "${sortkey:0:10}" < "${SINCE}" ]]; then
      continue
    fi

    rows+="${sortkey}"$'\t'"$(basename "${repo}")"$'\t'"${current}"$'\t'"${display}"$'\t'"$(previous_image_name "${repo}")"$'\n'
  done

  local count=0
  while IFS=$'\t' read -r sortkey name current display was; do
    [ -z "${name}" ] && continue
    printf '%s\n    now:     %s\n    repoint: %s\n    was:     %s\n' \
      "${name}" "${current}" "${display}" "${was}"
    count=$((count + 1))
  done < <(printf '%s' "${rows}" | sort --reverse)

  echo
  if [ -n "${SINCE}" ]; then
    echo "${count} start point(s) repointed at ghcr.io since ${SINCE}"
  else
    echo "${count} start point(s) repointed at ghcr.io"
  fi
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Audits every start-point checkout and prints a block per repo whose
# main.yml push trigger can never match its default branch.
function audit_branch_state()
{
  local count=0

  for repo in "${START_POINTS_DIR}"/*/; do
    local workflow="${repo}.github/workflows/main.yml"
    [ -f "${workflow}" ] || continue

    local branches
    branches="$(workflow_push_branches "${workflow}")"
    # No branch filter -> runs on every push -> no mismatch possible.
    [ -n "${branches}" ] || continue

    local db
    db="$(default_branch "${repo}")"
    if ! grep --quiet --line-regexp --fixed-strings "${db}" <<< "${branches}"; then
      printf '%s\n    default branch:   %s\n    main.yml fires on: %s\n' \
        "$(basename "${repo}")" \
        "${db}" \
        "$(tr '\n' ' ' <<< "${branches}")"
      count=$((count + 1))
    fi
  done

  echo
  echo "${count} start point(s) with a main.yml that cannot fire on its default branch"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "${0}" = "${BASH_SOURCE[0]}" ]; then
  parse_args "$@"
  case "${MODE}" in
    branches) audit_branch_state ;;
    *)        audit_repointed_images ;;
  esac
fi
