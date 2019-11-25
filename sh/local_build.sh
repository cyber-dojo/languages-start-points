#!/bin/bash
set -e

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"
readonly CDL_DIR="$(cd "${ROOT_DIR}" && cd ../../cyber-dojo-languages && pwd )"
readonly SHA_VALUE=$(cd "${ROOT_DIR}" && git rev-parse HEAD)
readonly SCRIPT_NAME=${ROOT_DIR}/../commander/cyber-dojo

SHA="${SHA_VALUE}" \
   ${SCRIPT_NAME} start-point create \
    cyberdojo/languages-start-points-small:latest \
      --languages \
        file://${CDL_DIR}/gcc-assert      \
        file://${CDL_DIR}/python-unittest \
        file://${CDL_DIR}/ruby-minitest
