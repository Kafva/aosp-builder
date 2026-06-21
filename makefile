include config.mk

SHELL = /bin/bash
.SHELLFLAGS = -ec

ifeq ($(shell uname),Darwin)
CONTAINER_BUILD = container build
CONTAINER_RUN = container run
else
CONTAINER_BUILD = docker buildx build
CONTAINER_RUN = docker run
endif

CONTAINER_MNT = /src

OUT = $(CURDIR)/out
BUILD = $(CURDIR)/build
AOSP = $(BUILD)/$(TARGET)-$(AOSP_BRANCH)
REPO = $(BUILD)/git-repo/repo

## Macros ######################################################################
define run
	$(CONTAINER_BUILD) \
		--build-arg BUILDER_UID=$(shell id -u) \
		--build-arg BUILDER_GID=$(shell id -g) \
		-t aosp-builder $(CURDIR) && \
	$(CONTAINER_RUN) -it -u $(shell id -u):$(shell id -g) --rm \
		-e TARGET=$(TARGET) \
		--mount type=bind,src=$(CURDIR),target=$(CONTAINER_MNT) \
		aosp-builder:latest /bin/bash -c "${1}";
endef

define aosp_run
	cd $(AOSP) && . build/envsetup.sh && lunch $(AOSP_TARGET) && ${1}
endef

## Targets #####################################################################
.PHONY: _build build

$(REPO):
	git clone https://gerrit.googlesource.com/git-repo $(@D)
	chmod a+x $@

$(AOSP)/.repo: $(REPO)
	mkdir -p $(@D)
	cd $(@D) && $(REPO) init -u $(AOSP_MANIFEST_URL) -b $(AOSP_BRANCH)

_source: $(AOSP)/.synced
$(AOSP)/.synced: $(AOSP)/.repo
	cd $(AOSP) && $(REPO) sync -j1 \
		--force-sync \
		--force-checkout \
		--force-remove-dirty \
		--fail-fast \
		--auto-gc
	@touch $@

_build:
	$(call aosp_run,m -j $(shell nproc) 2>&1 | tee build-$(shell date '+%Y-%m-%d-%H-%M').log)
	$(call aosp_run,m emu_img_zip)
	cp $(AOSP)/out/target/product/emu64*/sdk-repo-linux-system-images.zip $(OUT)/

## Docker wrappers #############################################################
source:
	$(call run,make _source)

build:
	$(call run,make _build)

shell:
	$(call run,bash)
