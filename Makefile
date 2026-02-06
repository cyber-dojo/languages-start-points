
SHORT_SHA := $(shell git rev-parse HEAD | head -c7)
IMAGE_NAME := cyberdojo/languages-start-points:${SHORT_SHA}

.PHONY: update_image_lists image snyk-container snyk-code

update_image_lists:
	${PWD}/bin/update_image_lists.sh

image:
	${PWD}/bin/build_test_tag.sh

snyk-container: 
	snyk container test ${IMAGE_NAME} \
		--sarif \
		--sarif-file-output=snyk.container.scan.json \
        --policy-path=.snyk

snyk-code:
	snyk code test \
		--sarif \
		--sarif-file-output=snyk.code.scan.json \
        --policy-path=.snyk

