.PHONY: build test run clean

build:
	swift build
	@echo "Executable built at .build/debug/arstdhneio"

build-prod:
	swift build --configuration release --product arstdhneio

test:
	swift test --parallel

run: build
	.build/debug/arstdhneio

run-prod: build-prod
	.build/release/arstdhneio

clean:
	swift package clean
