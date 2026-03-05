
SHORT_SHA := $(shell git rev-parse HEAD | head -c7)
IMAGE_NAME := cyberdojo/languages-start-points:${SHORT_SHA}

.PHONY: update_all_start_points image concat_all_start_points snyk-container snyk-code

all_start_points:
	${PWD}/bin/update_all_start_points.sh
	${PWD}/bin/concat_all_start_points.sh

concat_all_start_points:
	${PWD}/bin/concat_all_start_points.sh

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

