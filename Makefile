SHELL := /usr/bin/env bash
PROFILE ?= 1gb
CURRENT_TARGETS := engines/mysql/versions/8.4 engines/mariadb/versions/11.4 engines/postgresql/versions/17

.PHONY: test lint list validate-one validate-current validate-matrix

test: lint
	./scripts/test-structure.sh

lint:
	bash -n scripts/*.sh
	find engines -name validate.sh -print0 | xargs -0 -n1 bash -n
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck scripts/*.sh $$(find engines -name validate.sh -type f | sort); \
	else \
		echo "shellcheck not found; skipping shellcheck"; \
	fi

list:
	find engines -mindepth 3 -maxdepth 3 -type d -path '*/versions/*' | sort

validate-one:
	@test -n "$$TARGET" || { echo "Usage: make validate-one TARGET=engines/mysql/versions/8.4 [PROFILE=1gb]"; exit 2; }
	PROFILE="$(PROFILE)" "$$TARGET/tools/validate.sh"

validate-current:
	@for target in $(CURRENT_TARGETS); do \
		$(MAKE) --no-print-directory validate-one TARGET="$$target" PROFILE="$(PROFILE)" || exit $$?; \
	done

validate-matrix:
	@for profile in 1gb 2gb 4gb 8gb; do \
		for target in $(CURRENT_TARGETS); do \
			$(MAKE) --no-print-directory validate-one TARGET="$$target" PROFILE="$$profile" || exit $$?; \
		done; \
	done
