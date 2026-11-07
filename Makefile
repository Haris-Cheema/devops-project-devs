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

deps: node_modules

$(OUT_DIR)/%.html: $(SRC_DIR)/%.md package-lock.json | $(OUT_DIR) node_modules
	@echo "  BUILD $< -> $@"
	@npm run --silent build -- $< $@

build: $(OUTPUTS)

check:
	@test -n "$(SOURCES)" || (echo "No .md files found in $(SRC_DIR)"; exit 1)

lint: node_modules
	npm run lint

test: build
	@npm test --silent

coverage: build
	@mkdir -p coverage
	@node --test --experimental-test-coverage \
		--test-reporter=spec --test-reporter-destination=stdout \
		--test-reporter=lcov --test-reporter-destination=coverage/lcov.info

package: test
	npm pack

clean:
	rm -rf $(OUT_DIR) coverage *.tgz

ci: clean deps check lint test package
