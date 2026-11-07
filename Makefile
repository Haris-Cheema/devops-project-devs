SRC_DIR := src
OUT_DIR := out

SOURCES := $(wildcard $(SRC_DIR)/*.md)
OUTPUTS := $(patsubst $(SRC_DIR)/%.md,$(OUT_DIR)/%.html,$(SOURCES))

.PHONY: all clean check lint test coverage ci deps build package

all: build

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

node_modules: package-lock.json
	npm ci
	@touch node_modules

deps: node_modules ## install exactly what the lock file says

$(OUT_DIR)/%.html: $(SRC_DIR)/%.md package-lock.json | $(OUT_DIR) node_modules
	@echo "  BUILD $< -> $@"
	@npm run --silent build -- $< $@

build: $(OUTPUTS)

check: ## check markdown source files exist
	@test -n "$(SOURCES)" || (echo "No .md files found in $(SRC_DIR)"; exit 1)

lint: node_modules ## static analysis: seconds, so it runs first
	npm run --silent lint

test: build ## run the test suite against what was built
	@npm test --silent

coverage: build ## the tests again, writing coverage/lcov.info for SonarQube
	@mkdir -p coverage
	node --test --experimental-test-coverage \
		--test-reporter=spec --test-reporter-destination=stdout \
		--test-reporter=lcov --test-reporter-destination=coverage/lcov.info

package: test ## produce the versioned artifact
	npm pack

clean: ## remove all generated files
	rm -rf $(OUT_DIR) coverage *.tgz

ci: clean deps check lint test package ## everything, in pipeline order
