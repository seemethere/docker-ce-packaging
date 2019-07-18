GO_VERSION       = latest
GO_IMAGE         = golang:$(GO_VERSION)
REF              = master
GIT_SHORT_SHA    = $(shell git rev-parse --short=7 HEAD)

CLI_REF          = $(REF)
CLI_PATH         = /go/src/github.com/docker/cli
CLI_RPM_SPEC     = SPECS/docker-ce-cli.spec

ENGINE_REF       = $(REF)
ENGINE_PATH      = /go/src/github.com/docker/docker
ENGINE_RPM_SPEC  = SPECS/docker-ce.spec

BUILD_IMAGE      = centos:7
BUILDER_IMAGE    = docker/package-builder-$(BUILD_IMAGE)-$(GIT_SHORT_SHA)
DISTRO_ID        = $$(docker run --rm -it $(BUILD_IMAGE) sh -c '. /etc/os-release; echo -n "$$ID"')
DISTRO_VERSION   = $$(docker run --rm -it $(BUILD_IMAGE) sh -c '. /etc/os-release; echo -n "$$VERSION_ID"')
BUILD_TYPE       = $$(./scripts/deb-or-rpm $(BUILD_IMAGE))

VOLUME_MOUNTS    = -v "$(CURDIR)/build/:/out"
CHOWN            = docker run --rm -v $(CURDIR):/v -w /v alpine chown
CHOWN_TO_USER    = $(CHOWN) -R $(shell id -u):$(shell id -g)

# Volume mount source directories if needed
ifdef ENGINE_DIR
	VOLUME_MOUNTS += -v $(ENGINE_DIR):$(ENGINE_PATH)
endif

ifdef CLI_DIR
	VOLUME_MOUNTS += -v $(CLI_DIR):$(CLI_PATH)
endif

ENV_VARS=
ifdef CREATE_ARCHIVE
	ENV_VARS+=-e CREATE_ARCHIVE=1
	VOLUME_MOUNTS+= -v "$(CURDIR)/archive:/archive"
endif


-include Makefile-ee

.PHONY: build
build:
	$(MAKE) $(BUILD_TYPE)

.PHONY: clean
clean:
	-$(CHOWN_TO_USER) build/
	-$(RM) -r build/

.PHONY: builder-image
builder-image:
	docker build \
		-t $(BUILDER_IMAGE) \
		-f "dockerfiles/$(BUILD_TYPE).dockerfile" \
		--build-arg GO_IMAGE="$(GO_IMAGE)" \
		--build-arg BUILD_IMAGE="$(BUILD_IMAGE)" \
		--build-arg BASE="$(DISTRO_ID)" \
		--build-arg CLI_REF="$(CLI_REF)" \
		--build-arg ENGINE_REF="$(ENGINE_REF)" \
		$(CURDIR)

.PHONY: rpm
rpm: rpm-cli rpm-engine

.PHONY: rpm-cli
rpm-cli: builder-image
	docker run --rm -it \
		$(CREATE_ARCHIVE) \
		-e SPEC_FILE=$(CLI_RPM_SPEC) \
		-e GO_SRC_PATH=$(ENGINE_PATH) \
		$(VOLUME_MOUNTS) \
		$(BUILDER_IMAGE)

.PHONY: rpm-engine
rpm-engine: builder-image
	docker run --rm -it \
		$(CREATE_ARCHIVE) \
		-e SPEC_FILE=$(ENGINE_RPM_SPEC) \
		-e GO_SRC_PATH=$(CLI_PATH) \
		$(VOLUME_MOUNTS) \
		$(BUILDER_IMAGE)
	$(CHOWN_TO_USER) build/
