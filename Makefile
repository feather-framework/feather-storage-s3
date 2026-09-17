SHELL=/bin/bash

baseUrl = https://raw.githubusercontent.com/BinaryBirds/github-workflows/refs/heads/main/scripts

check: symlinks language deps lint headers docc-warnings package

symlinks:
	curl -s $(baseUrl)/check-broken-symlinks.sh | bash

package:
	curl -s $(baseUrl)/check-swift-package.sh | bash

language:
	curl -s $(baseUrl)/check-unacceptable-language.sh | bash

deps:
	curl -s $(baseUrl)/check-local-swift-dependencies.sh | bash

lint:
	curl -s $(baseUrl)/run-swift-format.sh | bash

format:
	curl -s $(baseUrl)/run-swift-format.sh | bash -s -- --fix

docc-local:
	curl -s $(baseUrl)/generate-docc.sh | bash -s -- --local

run-docc:
	curl -s $(baseUrl)/run-docc-docker.sh | bash

docc-warnings:
	curl -s $(baseUrl)/check-docc-warnings.sh | bash

headers:
	curl -s $(baseUrl)/check-swift-headers.sh | bash

fix-headers:
	curl -s $(baseUrl)/check-swift-headers.sh | bash -s -- --fix

test:
	@set -e; \
	trap 'docker compose down --volumes' EXIT; \
	docker compose up -d --build --wait minio; \
	FEATHER_STORAGE_S3_TEST_ENDPOINT=http://127.0.0.1:9100 swift test --parallel

docker-test:
	@set -e; \
	trap 'docker compose down --volumes' EXIT; \
	docker compose up --build --abort-on-container-exit --exit-code-from tests tests
