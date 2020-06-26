#!/bin/bash -Eeu

readonly MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TMP_DIR=$(mktemp -d /tmp/cyber-dojo.languages-start-points.build.XXXXXX)
readonly TMP_FILE=$(mktemp /tmp/cyber-dojo.languages-start-points.build.XXXXXX)
remove_tmps() { rm -rf "${TMP_DIR}" > /dev/null; rm "${TMP_FILE}" > /dev/null; }
trap remove_tmps EXIT
source "${MY_DIR}/echo_tagged_repo_urls.sh"

declare -ar URLS=(
  https://github.com/cyber-dojo-start-points/clangplusplus-googletest
  https://github.com/cyber-dojo-start-points/csharp-nunit
  https://github.com/cyber-dojo-start-points/csharp-specflow
  https://github.com/cyber-dojo-start-points/gcc-googletest
  https://github.com/cyber-dojo-start-points/gplusplus-boosttest
  https://github.com/cyber-dojo-start-points/gplusplus-catch
  https://github.com/cyber-dojo-start-points/gplusplus-googletest
  https://github.com/cyber-dojo-start-points/java-cucumberpico
  https://github.com/cyber-dojo-start-points/java-cucumberspring
  https://github.com/cyber-dojo-start-points/java-junit
  https://github.com/cyber-dojo-start-points/java-mockito
  https://github.com/cyber-dojo-start-points/java-powermockito
  https://github.com/cyber-dojo-start-points/javascript-assert
  https://github.com/cyber-dojo-start-points/javascript-assert-jquery
  https://github.com/cyber-dojo-start-points/javascript-cucumber
  https://github.com/cyber-dojo-start-points/javascript-jasmine
  https://github.com/cyber-dojo-start-points/javascript-qunit-sinon
  https://github.com/cyber-dojo-start-points/javascript-mocha-chai-sinon
  https://github.com/cyber-dojo-start-points/python-behave
  https://github.com/cyber-dojo-start-points/python-pytest
  https://github.com/cyber-dojo-start-points/python-unittest
  https://github.com/cyber-dojo-start-points/ruby-minitest
  https://github.com/cyber-dojo-start-points/ruby-rspec
  https://github.com/cyber-dojo-start-points/ruby-testunit
)

echo_tagged_git_repo_urls "${TMP_DIR}" "${TMP_FILE}" "${URLS[@]}"
cp "${TMP_FILE}" "${MY_DIR}/../start-points/git_repo_urls.common.tagged"
