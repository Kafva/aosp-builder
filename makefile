
AOSP_VERSION = 17
AOSP_API = 37
AOSP_BRANCH = android-$(AOSP_VERSION).0.0_r1
AOSP_ARCH ?= $(shell uname -m)
AOSP_TARGET = sdk_phone64_$(AOSP_ARCH)-cur-userdebug
AOSP_MANIFEST_URL = https://android.googlesource.com/platform/manifest

REPO = $(BUILD)/git-repo/repo

AVD = Android-$(AOSP_API)
AOSP_DIR = $(BUILD)/$(AOSP_BRANCH)

CONTAINER_MNT = /src

ifeq ($(shell uname),Darwin)
CONTAINER_BUILD = container build
CONTAINER_RUN = container run
else
CONTAINER_BUILD = docker buildx build
CONTAINER_RUN = docker run
endif

BUILD = $(CURDIR)/build
AOSP = $(BUILD)/$(AOSP_BRANCH)
OUT = $(CURDIR)/out

# $1: Command line to execute
define run
	$(CONTAINER_BUILD) \
		--build-arg BUILDER_UID=$(shell id -u) \
		--build-arg BUILDER_GID=$(shell id -g) \
		-t aosp-builder $(CURDIR) && \
	$(CONTAINER_RUN) -it -u $(shell id -u):$(shell id -g) --rm \
		--mount type=bind,src=$(CURDIR),target=$(CONTAINER_MNT) \
		aosp-builder:latest /bin/bash -c "${1}";
endef

# $1: Command to run
define aosp_run
	cd $(AOSP) && source build/envsetup.sh && lunch $(AOSP_TARGET) && ${1}
endef

################################################################################

$(REPO):
	git clone https://gerrit.googlesource.com/git-repo $@

$(AOSP)/.repo: $(REPO)
	mkdir -p $(@D)
	cd $(@D) && $(REPO) init -u $(AOSP_MANIFEST_URL) -b $(AOSP_BRANCH)

_source: $(AOSP)/.synced
$(AOSP)/.synced: $(AOSP)/.repo
	$(REPO) sync -j1 \
		--force-sync \
		--force-checkout \
		--force-remove-dirty \
		--fail-fast \
		--auto-gc
	@touch $@

_build: $(AOSP)/.synced
	$(call aosp_run,m -j $(shell nproc) 2>&1 | tee build-$(shell date '+%Y-%m-%d-%H-%M').log)
	$(call aosp_run,m emu_img_zip)
	cp $(AOSP)/out/target/product/emu64*/sdk-repo-linux-system-images.zip $(OUT)/

################################################################################

shell:
	$(call run,bash)

source:
	$(call run,make _source)

build:
	$(call run,make _build)
