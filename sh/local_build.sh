#!/bin/bash
set -e

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"
readonly CDL_DIR="$(cd "${ROOT_DIR}" && cd ../../cyber-dojo-languages && pwd )"
readonly SCRIPT_NAME=${ROOT_DIR}/../commander/cyber-dojo

export SHA_VALUE=$(cd "${ROOT_DIR}" && git rev-parse HEAD)
export CYBER_DOJO_LANGUAGES_PORT=4524

IMAGE_NAME=cyberdojo/languages-start-points-small:latest

${SCRIPT_NAME} start-point create \
  ${IMAGE_NAME} \
    --languages \
      file://${CDL_DIR}/gcc-assert      \
      file://${CDL_DIR}/python-unittest \
      file://${CDL_DIR}/ruby-minitest
