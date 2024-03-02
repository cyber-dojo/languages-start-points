#!/usr/bin/env bash
set -Eeu

readonly MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TMP_DIR=$(mktemp -d /tmp/cyber-dojo.languages-start-points.build.XXXXXX)
readonly TMP_FILE_1=$(mktemp /tmp/cyber-dojo.languages-start-points.build.XXXXXX)
readonly TMP_FILE_2=$(mktemp /tmp/cyber-dojo.languages-start-points.build.XXXXXX)
readonly DOCKERHUB=https://hub.docker.com/v2/repositories

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function remove_tmps()
{
   rm -rf "${TMP_DIR}" > /dev/null
   rm "${TMP_FILE_1}" > /dev/null
   rm "${TMP_FILE_2}" > /dev/null
}
trap remove_tmps EXIT

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
declare -ar ALL_URLS=(
  https://github.com/cyber-dojo-start-points/bash-bats
  https://github.com/cyber-dojo-start-points/bash-shunit2
  https://github.com/cyber-dojo-start-points/bash-unit
  https://github.com/cyber-dojo-start-points/bcpl-alltestspassed
  https://github.com/cyber-dojo-start-points/chapel-assert
  https://github.com/cyber-dojo-start-points/clang-assert
  https://github.com/cyber-dojo-start-points/clang-cgreen
  https://github.com/cyber-dojo-start-points/clangplusplus-assert
  https://github.com/cyber-dojo-start-points/clangplusplus-catch
  https://github.com/cyber-dojo-start-points/clangplusplus-cgreen
  https://github.com/cyber-dojo-start-points/clangplusplus-googlemock
  https://github.com/cyber-dojo-start-points/clangplusplus-googletest
  https://github.com/cyber-dojo-start-points/clangplusplus-igloo
  https://github.com/cyber-dojo-start-points/clojure-midje
  https://github.com/cyber-dojo-start-points/clojure-test
  https://github.com/cyber-dojo-start-points/coffeescript-jasmine
  https://github.com/cyber-dojo-start-points/csharp-moq
  https://github.com/cyber-dojo-start-points/csharp-nunit
  https://github.com/cyber-dojo-start-points/csharp-specflow
  https://github.com/cyber-dojo-start-points/dee-unittest
  https://github.com/cyber-dojo-start-points/elixir-exunit
  https://github.com/cyber-dojo-start-points/erlang-eunit
  https://github.com/cyber-dojo-start-points/fortran-funit
  https://github.com/cyber-dojo-start-points/fsharp-nunit
  https://github.com/cyber-dojo-start-points/gcc-assert
  https://github.com/cyber-dojo-start-points/gcc-cgreen
  https://github.com/cyber-dojo-start-points/gcc-cpputest
  https://github.com/cyber-dojo-start-points/gcc-googletest
  https://github.com/cyber-dojo-start-points/go-convey
  https://github.com/cyber-dojo-start-points/go-testify
  https://github.com/cyber-dojo-start-points/go-testing
  https://github.com/cyber-dojo-start-points/gplusplus-assert
  https://github.com/cyber-dojo-start-points/gplusplus-boosttest
  https://github.com/cyber-dojo-start-points/gplusplus-catch
  https://github.com/cyber-dojo-start-points/gplusplus-cgreen
  https://github.com/cyber-dojo-start-points/gplusplus-cpputest
  https://github.com/cyber-dojo-start-points/gplusplus-cucumber
  https://github.com/cyber-dojo-start-points/gplusplus-googlemock
  https://github.com/cyber-dojo-start-points/gplusplus-googletest
  https://github.com/cyber-dojo-start-points/gplusplus-igloo
  https://github.com/cyber-dojo-start-points/groovy-junit
  https://github.com/cyber-dojo-start-points/groovy-spock
  https://github.com/cyber-dojo-start-points/haskell-hunit
  https://github.com/cyber-dojo-start-points/java-approval
  https://github.com/cyber-dojo-start-points/java-cucumberpico
  https://github.com/cyber-dojo-start-points/java-cucumberspring
  https://github.com/cyber-dojo-start-points/java-jmock
  https://github.com/cyber-dojo-start-points/java-junit
  https://github.com/cyber-dojo-start-points/java-mockito
  https://github.com/cyber-dojo-start-points/java-powermockito
  https://github.com/cyber-dojo-start-points/java-sqlite
  https://github.com/cyber-dojo-start-points/javascript-assert
  https://github.com/cyber-dojo-start-points/javascript-assert-jquery
  https://github.com/cyber-dojo-start-points/javascript-cucumber
  https://github.com/cyber-dojo-start-points/javascript-jasmine
  https://github.com/cyber-dojo-start-points/javascript-jest
  https://github.com/cyber-dojo-start-points/javascript-mocha-chai-sinon
  https://github.com/cyber-dojo-start-points/javascript-qunit-sinon
  https://github.com/cyber-dojo-start-points/julia-test
  https://github.com/cyber-dojo-start-points/jq-approvals
  https://github.com/cyber-dojo-start-points/kotlin-test
  https://github.com/cyber-dojo-start-points/nasm-assert
  https://github.com/cyber-dojo-start-points/pascal-assert
  https://github.com/cyber-dojo-start-points/perl-testsimple
  https://github.com/cyber-dojo-start-points/php-unit
  https://github.com/cyber-dojo-start-points/prolog-plunit
  https://github.com/cyber-dojo-start-points/python-approval-pytest
  https://github.com/cyber-dojo-start-points/python-approval-unittest
  https://github.com/cyber-dojo-start-points/python-assert
  https://github.com/cyber-dojo-start-points/python-behave
  https://github.com/cyber-dojo-start-points/python-pytest
  https://github.com/cyber-dojo-start-points/python-unittest
  https://github.com/cyber-dojo-start-points/r-runit
  https://github.com/cyber-dojo-start-points/rescript-jest  
  https://github.com/cyber-dojo-start-points/ruby-approval
  https://github.com/cyber-dojo-start-points/ruby-cucumber
  https://github.com/cyber-dojo-start-points/ruby-minitest
  https://github.com/cyber-dojo-start-points/ruby-rspec
  https://github.com/cyber-dojo-start-points/ruby-testunit
  https://github.com/cyber-dojo-start-points/rust-test
  https://github.com/cyber-dojo-start-points/swift-swordfish
  https://github.com/cyber-dojo-start-points/swift-xctest
  https://github.com/cyber-dojo-start-points/typescript-jest
  https://github.com/cyber-dojo-start-points/vhdl-assert
  https://github.com/cyber-dojo-start-points/visual-basic-nunit
  https://github.com/cyber-dojo-start-points/zig-test
)

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function process_all_urls()
{
  for i in "${!ALL_URLS[@]}"
  do
    local url="${ALL_URLS[$i]}"            # https://github.com/cyber-dojo-start-points/csharp-nunit
    local repo_dir="${TMP_DIR}/${i}"
    git clone "${url}" "${repo_dir}" > /dev/null 2>&1
    get_tagged_repo_url "${repo_dir}"
    get_compressed_image_size "${repo_dir}"
  done
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function get_tagged_repo_url()
{
  local -r repo_dir="${1}"
  local -r sha="$(cd "${repo_dir}" && git rev-parse HEAD)"
  local -r tag=${sha:0:7}
  echo "${tag}@${url}" | tee -a "${TMP_FILE_1}"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function get_compressed_image_size()
{
  local -r repo_dir="${1}"

  local image_name=$(cat "${repo_dir}/start_point/manifest.json" | jq --raw-output '.image_name') # cyberdojofoundation/csharp_nunit:32503c4
  local untagged="$(echo ${image_name} | awk -F: '{print $(NF-1)}')" # cyberdojofoundation/csharp_nunit
  local tag="$(echo ${image_name} | awk -F: '{print $(NF)}')"        # 32503c4

  local size=$(curl --silent ${DOCKERHUB}/${untagged}/tags/${tag} | jq '.full_size') # 227987976
  local human=$(human_size "${size}")                                                # 217.42 MiB
  echo "${size} ${image_name} ${human}" | tee -a "${TMP_FILE_2}"
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
    echo "$i$d ${S[$s]}"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
process_all_urls
cp "${TMP_FILE_1}" "${MY_DIR}/../git_repo_urls.tagged"
sort -n -r "${TMP_FILE_2}" > "${MY_DIR}/../compressed.image_sizes.sorted"
