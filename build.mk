# Meant to be included by the subdirectories cli/engine
VERSION?=0.0.0-dev
GO_VERSION:=1.11.3
GO_IMAGE:= docker.io/library/golang:$(GO_VERSION)
BUILDTIME=$(shell date -u -d "@$${SOURCE_DATE_EPOCH:-$$(date +%s)}" --rfc-3339 ns 2> /dev/null | sed -e 's/ /T/')

BUILD_IMAGE=ubuntu:bionic
BUILD_TYPE=$(shell ./../scripts/deb-or-rpm $(BUILD_IMAGE))
BUILD_BASE:=$(shell docker run --rm -i $(BUILD_IMAGE) sh -c '. /etc/os-release; echo $${ID}')
ifeq ($(BUILD_TYPE),)
	error("Could not determine package type from image '$(BUILD_IMAGE)'")
endif
BUILD_DOCKERFILE=$(shell readlink -e ../dockerfiles/$(BUILD_TYPE).dockerfile)
BUILD_ARGS=\
	--build-arg BUILD_IMAGE='$(BUILD_IMAGE)' \
	--build-arg GOLANG_IMAGE='$(GO_IMAGE)' \
	--build-arg BASE='$(BUILD_BASE)'

DOCKER_IMAGE_ORG=docker
DOCKER_IMAGE_NAME=$(subst :,-,$(BUILD_IMAGE))-builder
DOCKER_IMAGE_TAG=$(shell git rev-parse HEAD)
FULL_DOCKER_IMAGE=$(DOCKER_IMAGE_ORG)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

RUN_ENV_VARS=\
	-e ORIG_VERSION=$(VERSION)
RUN_VOLUME_MOUNTS=\
	-v $(shell readlink -e ../build):/out
