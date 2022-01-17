ifneq (, $(BUILDX_BIN))
	export BUILDX_CMD = $(BUILDX_BIN)
else ifneq (, $(shell docker buildx version))
	export BUILDX_CMD = docker buildx
else ifneq (, $(shell which buildx))
	export BUILDX_CMD = $(which buildx)
else
	$(error "Buildx is required: https://github.com/docker/buildx#installing")
endif

CHANNEL ?= mainline

image:
	CHANNEL=$(CHANNEL) $(BUILDX_CMD) bake

vendor:
	$(eval $@_TMP_OUT := $(shell mktemp -d -t dockerfile-output.XXXXXXXXXX))
	$(BUILDX_CMD) bake --set "*.output=$($@_TMP_OUT)" vendor
	rm -rf ./vendor
	cp -R "$($@_TMP_OUT)"/out/* .
	rm -rf $($@_TMP_OUT)/*

mod-outdated:
	$(BUILDX_CMD) bake mod-outdated

validate: lint test test-parser validate-vendor

lint:
	$(BUILDX_CMD) bake lint

test:
	./hack/test integration

validate-vendor:
	$(BUILDX_CMD) bake validate-vendor

test-parser:
	$(BUILDX_CMD) bake \
		--file ./parser/docker-bake.hcl \
		--set *.context=./parser \
		--set *.output=./parser/coverage \
		test

.PHONY: image vendor mod-outdated validate lint test validate-vendor test-parser
