#!/bin/bash

# $ cyber-dojo start-point build --language=<name> <url>...
# Work in Progress.
# See start-points-base  branch=build-option
# See commander          branch=build-option

# NB: context dir is docker volume mounted (so not /tmp)
CONTEXT_DIR=/Users/jonjagger/tmp-start-point-build
mkdir ${CONTEXT_DIR}

URL_INDEX=${1:-0}
LTF_GIT_URL=${2:-https://github.com/cyber-dojo-languages/ruby-testunit}

# 1. clone the repo
cd ${CONTEXT_DIR}
git clone "${LTF_GIT_URL}" "${URL_INDEX}"

# 2. get the image_name from start_point/manifest.json
LTF_DIR="${CONTEXT_DIR}/${URL_INDEX}"
IMAGE_NAME=$(docker run --rm --volume ${LTF_DIR}:/data:ro cyberdojofoundation/image_namer)

# 3. ensure we have the latest
docker pull ${IMAGE_NAME}

# 4. get the commit SHA from the image's env-var
SHA_ENV_VAR=$(docker run --rm "${IMAGE_NAME}" bash -c 'env | grep SHA=')
SHA="${SHA_ENV_VAR:4}"
TAG="${SHA:0:7}"

# 5. ensure the tagged image exists
docker pull ${IMAGE_NAME}:${TAG}

# 6. checkout the start_point's commit SHA
cd "${LTF_DIR}"
git reset --hard HEAD
git checkout "${SHA}" # detached head warning

# 7. remove unwanted files
rm -rf docker
rm -rf .git

# 8. Save SHA info so http start-point service can append
#    the TAG to image_name when serving manifests.
echo -e "${URL_INDEX} \t ${SHA} \t ${LTF_GIT_URL}" >> ${CONTEXT_DIR}/build_shas
