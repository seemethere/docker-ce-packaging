SHELL:=/bin/bash

SOURCE_TGZS=cli.tgz engine.tgz

clean:
	$(RM) -r sources

sources/engine.tgz: | $(ENGINE_DIR)
	mkdir -p $(@D)
	docker run --rm -i -w /v \
		-v $(CLI_DIR):/docker \
		-v $(CURDIR)/$(@D):/v \
		alpine \
		tar -C / -c -z -f /v/$(@F) docker

build:
	$(MAKE) -C cli build
	$(MAKE) -C engine build
