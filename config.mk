SYNC_JOBS ?= 1
BUILD_JOBS ?= 8

AOSP_ARCH ?= $(shell uname -m)

ifeq ($(TARGET),aosp)
AOSP_VERSION = 17
AOSP_BRANCH = android-$(AOSP_VERSION).0.0_r1
AOSP_TARGET = sdk_phone64_$(AOSP_ARCH)-trunk_staging-eng
AOSP_MANIFEST_URL = https://android.googlesource.com/platform/manifest

else ifeq ($(TARGET),grapheneos)
AOSP_VERSION = 16
AOSP_BRANCH = $(AOSP_VERSION)-qpr2
AOSP_TARGET = sdk_phone64_$(AOSP_ARCH)-cur-userdebug
AOSP_MANIFEST_URL = https://github.com/GrapheneOS/platform_manifest.git

else
$(error Unsupported TARGET)
endif

# Tag name to use when creating a new release.
TAG ?= $(shell date '+%Y.%m.%d')
