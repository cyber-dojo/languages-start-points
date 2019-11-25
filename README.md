
[![CircleCI](https://circleci.com/gh/cyber-dojo/languages.svg?style=svg)](https://circleci.com/gh/cyber-dojo/languages)

Specifies the start-points used to create the languages start-point images
* [cyberdojo/languages-all](https://hub.docker.com/r/cyberdojo/languages-all)
* [cyberdojo/languages-common](https://hub.docker.com/r/cyberdojo/languages-common)
* [cyberdojo/languages-small](https://hub.docker.com/r/cyberdojo/languages-small)

```bash
#!/bin/bash
set -e

GITHUB_ORG=https://raw.githubusercontent.com/cyber-dojo
LANGUAGES_LIST="${GITHUB_ORG}/languages-start-points/master/url_list"
SCRIPT=cyber-dojo
curl -O --silent --fail "${GITHUB_ORG}/commander/master/${SCRIPT}"
chmod 700 ./${SCRIPT}

IMAGE_NAME=cyberdojo/languages-all
./${SCRIPT} start-point create \
   "${IMAGE_NAME}" \
      --languages \
        $(curl --silent --fail "${LANGUAGES_LIST}/all")

IMAGE_NAME=cyberdojo/languages-common
./${SCRIPT} start-point create \
   "${IMAGE_NAME}"\
      --languages \
        $(curl --silent --fail "${LANGUAGES_LIST}/common")

IMAGE_NAME=cyberdojo/languages-small
./${SCRIPT} start-point create \
   "${IMAGE_NAME}" \
      --languages \
        $(curl --silent --fail "${LANGUAGES_LIST}/small")
```

![cyber-dojo.org home page](https://github.com/cyber-dojo/cyber-dojo/blob/master/shared/home_page_snapshot.png)
