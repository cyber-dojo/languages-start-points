#!/usr/bin/env bash
set -Eeu

readonly my_dir="$(cd "$(dirname "${0}")" && pwd)"

echo
for test_file in ${my_dir}/test_*; do
  ${test_file}
done
