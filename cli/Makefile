CLI_DIR=$(shell go env GOPATH)/src/github.com/docker/cli

COMMON_FILES=cli/debian

include ../build.mk
-include Makefile-ee

# Include our common files for the CLI
BUILD_ARGS+=--build-arg COMMON_FILES=$(COMMON_FILES)

../sources/cli.tgz: | $(CLI_DIR)
	mkdir -p $(@D)
	docker run --rm -i -w /v \
		-v $(CLI_DIR):/cli \
		-v $(CURDIR)/$(@D):/v \
		alpine \
		tar -C / -c -z -f /v/$(@F) cli

build: ../sources/cli.tgz
	DOCKER_BUILDKIT=1 docker build \
		-t $(FULL_DOCKER_IMAGE)-cli \
		-f $(BUILD_DOCKERFILE) \
		$(BUILD_ARGS) \
		../
	# TODO: fill out env variables, etc
	docker run --rm -i \
		$(RUN_ENV_VARS) \
		$(FULL_DOCKER_IMAGE)-cli
