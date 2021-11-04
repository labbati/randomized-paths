TMP_DIR := .tmp
TMP_DDTRACE := $(TMP_DIR)/dd-trace-php
TMP_RELEASE := $(TMP_DIR)/release
RANDOMIZED_TESTS_DIR := $(TMP_DDTRACE)/tests/randomized/app
RANDOMIZED_TESTS_SRC_DIR := $(RANDOMIZED_TESTS_DIR)/src

$(TMP_DDTRACE):
	@mkdir -p .tmp
	@git clone --single-branch --branch master git@github.com:DataDog/dd-trace-php.git $(TMP_DDTRACE)

$(TMP_RELEASE):
	@mkdir -p .tmp
	@git clone --single-branch --branch main git@github.com:labbati/randomized-paths.git $(TMP_RELEASE)

$(TMP_DIR): $(TMP_DDTRACE) $(TMP_RELEASE)

clean:
	@rm -rf $(TMP_DIR)

update_src: $(TMP_DDTRACE)
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: Empty VERSION. Set to VERSION=x.y"; \
		exit 1; \
	fi
	rm -rf src
	cp -r $(RANDOMIZED_TESTS_SRC_DIR) .
	git add --all
	git commit -m 'Release $(VERSION)'
	git push

composer_%: $(TMP_DIR)
	@echo "Generating composer.json for PHP $(*)"
	@export REQUIREMENTS='$(shell cat $(RANDOMIZED_TESTS_DIR)/composer-$(*).json | jq '.require')' \
		&& cat composer.json | \
			sed 's@{}@'"$$REQUIREMENTS"'@' | \
			jq . > $(TMP_RELEASE)/composer.json

release_%: composer_%
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: Empty VERSION. Set to VERSION=x.y"; \
		exit 1; \
	fi
	@echo "Tagging $(*).$(VERSION)"
	@git -C $(TMP_RELEASE) checkout -b 'release/$(*)/$(VERSION)'
	@git -C $(TMP_RELEASE) add --all
	@git -C $(TMP_RELEASE) commit -m 'bump version $(*).$(VERSION)'
	@git -C $(TMP_RELEASE) tag 'v$(*).$(VERSION)'
	@git -C $(TMP_RELEASE) push origin 'v$(*).$(VERSION)'
	@git -C $(TMP_RELEASE) checkout main

release: clean update_src release_8.0 release_7.4 release_7.3 release_7.2 release_7.1 release_7.0 release_5.6 release_5.5 release_5.4
