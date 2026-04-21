.PHONY: build build-prod test run run-prod app install-app open-app release-archive publish-check clean

SWIFT ?= swift

build:
	$(SWIFT) build
	@echo "Executable built at .build/debug/arstdhneio"

build-prod:
	$(SWIFT) build --configuration release --product arstdhneio

test:
	$(SWIFT) test --parallel

run: build
	.build/debug/arstdhneio

run-prod: build-prod
	.build/release/arstdhneio

app:
	./scripts/build-app.sh

install-app: app
	./scripts/install-app.sh

open-app: app
	open dist/arstdhneio.app

release-archive: app
	./scripts/package-release.sh

publish-check:
	$(SWIFT) build
	./scripts/build-app.sh

clean:
	$(SWIFT) package clean
