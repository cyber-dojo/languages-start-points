#!/usr/bin/env bash

readonly my_dir="$(cd "$(dirname "${0}")" && pwd)"
readonly script="${my_dir}/../bin/echo_shuffled_shards.sh"

test_SUCCESS_echo_shuffled_shards() { :; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# The shard count refresh.yml gets when it asks for no particular one.
test___SUCCESS_default_shard_count_is_10()
{
  echo_shuffled_shards
  assert_status_0
  assert_stderr_equals ""
  assertEquals 10 "$(shard_count)"
}

# Shuffling must not lose or repeat a start-point: the shards together are
# exactly the list, which is what makes a sharded refresh equal to a whole one.
test___SUCCESS_every_start_point_appears_exactly_once()
{
  echo_shuffled_shards
  assert_status_0
  assertEquals "$(all_start_points | sort)" "$(sharded_start_points | sort)"
}

# Every shard is within one start-point of the others, and the remainder sits
# in the leading shards.
test___SUCCESS_leading_shards_hold_the_remainder()
{
  echo_shuffled_shards
  assert_status_0
  assertEquals "$(expected_shard_sizes 10)" "$(jq --raw-output '.[].names | split(" ") | length' "${stdoutF}")"
}

# One shard is the sequential refresh, and it must still name every
# start-point rather than falling back to the empty-shard case.
test___SUCCESS_one_shard_holds_every_start_point()
{
  echo_shuffled_shards 1
  assert_status_0
  assertEquals 1 "$(shard_count)"
  assertEquals "$(all_start_points | sort)" "$(sharded_start_points | sort)"
}

# Asked for more shards than there are start-points, the surplus shards are
# dropped. An emitted empty one would run update_all_start_points.sh with no
# names, which updates every start-point.
test___SUCCESS_more_shards_than_start_points_holds_one_each()
{
  local -r total="$(all_start_points | wc -l | awk '{print $1}')"
  echo_shuffled_shards $((total + 3))
  assert_status_0
  assertEquals "${total}" "$(shard_count)"
  assertEquals "$(expected_shard_sizes "${total}")" "$(jq --raw-output '.[].names | split(" ") | length' "${stdoutF}")"
}

# A count that is not a number names itself in the diagnostic, so a mistyped
# workflow input is readable without opening the script.
test___FAILURE_shard_count_is_not_a_number()
{
  echo_shuffled_shards ten
  assert_status_not_equals 0
  assert_stderr_includes "SHARD-COUNT must be a positive integer, got 'ten'"
}

# Zero shards would emit an empty matrix, which GitHub Actions rejects with a
# message about the matrix rather than about the count.
test___FAILURE_shard_count_is_zero()
{
  echo_shuffled_shards 0
  assert_status_not_equals 0
  assert_stderr_includes "SHARD-COUNT must be a positive integer, got '0'"
}

test___SUCCESS_h_prints_help_to_stdout()
{
  echo_shuffled_shards -h
  assert_status_0
  assert_stderr_equals ""
  assert_stdout_includes "Use: ./bin/echo_shuffled_shards.sh [SHARD-COUNT]"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Runs the script under test, keeping its stdout, stderr and exit status for
# the assertions.
echo_shuffled_shards()
{
  "${script}" "$@" >${stdoutF} 2>${stderrF}
  status=$?
  echo ${status} >${statusF}
}

# Echoes how many shards the last run emitted.
shard_count()
{
  jq --raw-output 'length' "${stdoutF}"
}

# Echoes every start-point named by the last run, one per line, shards merged.
sharded_start_points()
{
  jq --raw-output '.[].names | split(" ") | .[]' "${stdoutF}"
}

# Echoes the start-points bin/all_start_points.sh declares, one per line. Read
# in a subshell because that file sets -e, which would end this test file at
# the first command a FAILURE test expects to exit non-zero.
all_start_points()
{
  bash -c "source '${my_dir}/../bin/all_start_points.sh'; printf '%s\n' \"\${ALL_START_POINTS[@]}\""
}

# Echoes the size of each of "${1}" shards, one per line, in the order the
# script emits them. Derived from the length of ALL_START_POINTS so that adding
# a start-point does not need this test editing.
expected_shard_sizes()
{
  local -r count="${1}"
  local -r total="$(all_start_points | wc -l | awk '{print $1}')"
  local -r remainder=$((total % count))
  local -a sizes=()
  local index
  for ((index = 0; index < count; index++))
  do
    if [ "${index}" -lt "${remainder}" ]; then
      sizes+=("$((total / count + 1))")
    else
      sizes+=("$((total / count))")
    fi
  done
  printf '%s\n' "${sizes[@]}"
}

echo "::${0##*/}"
. ${my_dir}/shunit2_helpers.sh
. ${my_dir}/shunit2
