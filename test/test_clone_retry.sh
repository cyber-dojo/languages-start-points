#!/usr/bin/env bash

readonly my_dir="$(cd "$(dirname "${0}")" && pwd)"
readonly script="${my_dir}/../bin/update_one_start_point.sh"

test_SUCCESS_update_one_start_point_clone() { :; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# The clone reaches github.com, so a start-point that is perfectly fine can
# still fail to clone. Trying again is what keeps one flaky clone from costing
# a whole refresh.
test___FAILURE_a_failing_clone_is_retried()
{
  update_one_start_point_with_failing_clone
  assertEquals 2 "$(clone_attempts)"
}

# git exits 128, which is also how a shell reports death by signal number 0.
# The caller looping over every start-point reads a status of 128 or more as a
# signal and stops the whole run, so a clone that cannot succeed has to report
# itself as one ordinary bad start-point instead.
test___FAILURE_repeated_clone_failure_does_not_exit_128()
{
  update_one_start_point_with_failing_clone
  assert_status_equals 42
}

test___FAILURE_repeated_clone_failure_names_the_start_point()
{
  update_one_start_point_with_failing_clone
  assert_stderr_includes "some-start-point"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Runs the script under test with a git on the PATH whose clone always fails
# the way the real one does, recording one line per attempt. Stubbed rather
# than pointed at a missing repo so the test needs no network and always fails
# the same way.
update_one_start_point_with_failing_clone()
{
  local -r bin_dir="${SHUNIT_TMPDIR}/failing-git"
  attemptsF="${SHUNIT_TMPDIR}/clone-attempts"
  rm -rf "${bin_dir}"
  mkdir -p "${bin_dir}"
  rm -f "${attemptsF}"
  touch "${attemptsF}"
  {
    echo '#!/usr/bin/env bash'
    echo "echo \"\${@}\" >> \"${attemptsF}\""
    echo 'exit 128'
  } > "${bin_dir}/git"
  chmod +x "${bin_dir}/git"
  PATH="${bin_dir}:${PATH}" "${script}" some-start-point >${stdoutF} 2>${stderrF}
  status=$?
  echo ${status} >${statusF}
}

# Echoes how many times the stubbed git was asked to clone.
clone_attempts()
{
  grep --count '^clone' "${attemptsF}"
}

echo "::${0##*/}"
. ${my_dir}/shunit2_helpers.sh
. ${my_dir}/shunit2
