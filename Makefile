TMP_DIR := .tmp
RANDOMIZED_TESTS_DIR := $(TMP_DIR)/tests/randomized/app
RANDOMIZED_TESTS_SRC_DIR := $(RANDOMIZED_TESTS_DIR)/src

$(TMP_DIR):
	@mkdir -p .tmp
	@git clone --single-branch --branch master git@github.com:DataDog/dd-trace-php.git $(TMP_DIR)

update: $(TMP_DIR)
	@echo "Updating to latest master"
	@git -C $(TMP_DIR) pull

clean:
	@rm -rf $(TMP_DIR)

clean_sources:
	@rm -rf src composer.lock

update_sources: update clean_sources
	@echo "Refreshing src folder"
	@cp -r $(RANDOMIZED_TESTS_SRC_DIR) .

composer_%: update_sources
	@echo "Generating composer.json for PHP $(*)"
	@export REQUIREMENTS='$(shell cat $(RANDOMIZED_TESTS_DIR)/composer-$(*).json | jq '.require')' \
		&& cat composer.json | \
			sed 's@{}@'"$$REQUIREMENTS"'@' | \
			jq . > composer.tmp.json \
		&& mv composer.tmp.json composer.json \
		&& rm -f composer.tmp.json

release_%: composer_%
ifndef VERSION
$(error 'VERSION is not set. Invoke with VERSION=x.y')
endif
	@echo "Tagging $(*).$(VERSION)"
	@git checkout -b 'release/$(*)/$(VERSION)'
	@git add --all
	@git commit -m 'bump version $(*).$(VERSION)'
	@git tag 'v$(*).$(VERSION)'
	@git push -u origin release/$(*)/$(VERSION)
	@git push origin 'v$(*).$(VERSION)'
	@git checkout main

release: release_8.0 release_7.4 release_7.3 release_7.2 release_7.1 release_7.0 release_5.6 release_5.5 release_5.4
