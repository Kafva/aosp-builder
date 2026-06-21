AOSP_ARCH ?= $(shell uname -m)

ifeq ($(TARGET),aosp)
AOSP_VERSION = 17
AOSP_API = 37
AOSP_BRANCH = android-$(AOSP_VERSION).0.0_r1
AOSP_TARGET = sdk_phone64_$(AOSP_ARCH)-trunk_staging-userdebug
AOSP_MANIFEST_URL = https://android.googlesource.com/platform/manifest

else ifeq ($(TARGET),grapheneos)
AOSP_VERSION = 16
AOSP_API = 36
AOSP_BRANCH = $(AOSP_VERSION)-qpr2
AOSP_TARGET = sdk_phone64_$(AOSP_ARCH)-cur-userdebug
AOSP_MANIFEST_URL = https://github.com/GrapheneOS/platform_manifest.git

else
$(error Unsupported TARGET)
endif
