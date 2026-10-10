# BannerOffset (com.sonic125.banneroffset)
# Rootless Theos tweak. Build on Ubuntu 22.04 (see setup-ubuntu.sh / build.sh).

# Target iOS 15.0+ (rootless jailbreaks: palera1n / Dopamine / ElleKit).
# The SDK version must match a folder in $THEOS/sdks (setup-ubuntu.sh installs iPhoneOS14.5.sdk).
TARGET := iphone:clang:14.5:15.0
ARCHS := arm64 arm64e

# Must be set BEFORE including common.mk so packages install under /var/jb.
THEOS_PACKAGE_SCHEME := rootless

INSTALL_TARGET_PROCESSES := SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := BannerOffset
BannerOffset_FILES := Tweak.x
BannerOffset_CFLAGS := -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
