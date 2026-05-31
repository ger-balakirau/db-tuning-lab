SHELL := /usr/bin/env bash

.PHONY: test lint list validate-one

test: lint
	./scripts/test-structure.sh

lint:
	bash -n scripts/test-structure.sh
	find engines -name validate.sh -print0 | xargs -0 -n1 bash -n

list:
	find engines -mindepth 3 -maxdepth 3 -type d -path '*/versions/*' | sort

validate-one:
	@test -n "$$TARGET" || { echo "Usage: make validate-one TARGET=engines/mysql/versions/8.4"; exit 2; }
	cd "$$TARGET/tools" && ./validate.sh
