TMP_DIR := .tmp
RANDOMIZED_TESTS_DIR := $(TMP_DIR)/tests/randomized/app
RANDOMIZED_TESTS_SRC_DIR := $(RANDOMIZED_TESTS_DIR)/src
RELEASE_DATE_FRAGMENT := $(shell date -u '+%y%m%d%H%M%S')

$(TMP_DIR):
	@mkdir -p .tmp
	@git clone --single-branch --branch master git@github.com:DataDog/dd-trace-php.git $(TMP_DIR)

update: $(TMP_DIR)
	@echo "Updating to latest master"
	@git -C $(TMP_DIR) pull

clean:
	@rm -rf $(TMP_DIR)

clean_sources:
	@rm -rf src composer.json composer.lock

update_sources: update clean_sources
	@echo "Refreshing src folder"
	@cp -r $(RANDOMIZED_TESTS_SRC_DIR) .

composer_%: update_sources
	@echo "Generating composer.json for PHP $(*)"
	@export REQUIREMENTS='$(shell cat $(RANDOMIZED_TESTS_DIR)/composer-$(*).json | jq '.require')'; \
		cat composer.template.json | \
			sed 's@"automatically_substituted_here_at_build_time"@'"$$REQUIREMENTS"'@' | \
			jq > composer.json

release_%: composer_%
	@echo "Tagging $(*).$(RELEASE_DATE_FRAGMENT)"
	@git checkout -b 'release/$(*)/$(RELEASE_DATE_FRAGMENT)'
	@git add --all
	@git commit -m 'bump version $(*).$(RELEASE_DATE_FRAGMENT)'
	@git tag 'v$(*).$(RELEASE_DATE_FRAGMENT)'
	@git push -u origin release/$(*)/$(RELEASE_DATE_FRAGMENT)
	@git push tag 'v$(*).$(RELEASE_DATE_FRAGMENT)'
	@git checkout main

release: release_8.0 release_7.4 release_7.3 release_7.2 release_7.1 release_7.0 release_5.6 release_5.5, release_5.4
