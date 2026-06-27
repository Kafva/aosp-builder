include config.mk

.PHONY: _build build

SHELL = /bin/bash
.SHELLFLAGS = -ec -o pipefail

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
EMU_PRODUCT = emu64$(shell grep -o '^[a-z]' <<< $(AOSP_ARCH))

## Macros ######################################################################
define run
	$(CONTAINER_BUILD) \
		--build-arg BUILDER_UID=$(shell id -u) \
		--build-arg BUILDER_GID=$(shell id -g) \
		-t aosp-builder $(CURDIR) && \
	$(CONTAINER_RUN) -it -u $(shell id -u):$(shell id -g) --rm \
		-e TARGET=$(TARGET) \
		-e AOSP_ARCH=$(AOSP_ARCH) \
		--mount type=bind,src=$(CURDIR),target=$(CONTAINER_MNT) \
		aosp-builder:latest /bin/bash -c "${1}";
endef

define aosp_run
	. envsetup.sh && cd $(AOSP) && . build/envsetup.sh && lunch $(AOSP_TARGET) && ${1}
endef

## Targets #####################################################################
$(REPO):
	git clone https://gerrit.googlesource.com/git-repo $(@D)
	chmod a+x $@

$(AOSP)/.repo: $(REPO)
	mkdir -p $(@D)
	cd $(@D) && $(REPO) init -u $(AOSP_MANIFEST_URL) -b $(AOSP_BRANCH)

_sync: $(AOSP)/.repo
	cd $(AOSP) && $(REPO) sync -j $(SYNC_JOBS) \
		--force-sync \
		--force-checkout \
		--force-remove-dirty \
		--fail-fast \
		--auto-gc

_build:
	$(call aosp_run,m -j $(BUILD_JOBS) 2>&1 | tee build-$(shell date '+%Y-%m-%d-%H-%M').log)
ifneq ($(findstring sdk_,$(AOSP_TARGET)),)
	$(call aosp_run,m emu_img_zip)
	./scripts/package_images.sh \
		-i $(AOSP)/out/target/product/$(EMU_PRODUCT)/sdk-repo-linux-system-images.zip \
		-o $(OUT)/$(TARGET)-$(AOSP_BRANCH)-$(AOSP_ARCH)-system-images.tar.xz
endif

_shell:
	$(call aosp_run,bash)

_patch:
	./scripts/patch.sh $(AOSP)

_unpatch:
	cd $(AOSP) && repo forall -c git reset --hard HEAD

release:
	git tag -f $(TAG)
	git remote add gh git@github.com:Kafva/aosp-builder.git 2> /dev/null || :
	git push -d gh $(TAG) 2> /dev/null || :
	git push gh $(TAG)
	git push -d origin $(TAG) 2> /dev/null || :
	git push origin $(TAG)
	@# Make sure release has been created server side
	sleep 10
	gh release create --notes-from-tag --title $(TAG) $(TAG) $(wildcard out/*.tar.xz)

## Docker wrappers #############################################################
sync:
	$(call run,make _sync)

patch:
	$(call run,make _patch)

unpatch:
	$(call run,make _unpatch)

build:
	$(call run,make _build)

shell:
	$(call run,make _shell)
