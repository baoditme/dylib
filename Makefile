ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SpyDylib
SpyDylib_FILES = Tweak.xm
SpyDylib_CFLAGS = -fobjc-arc -Wno-everything
SpyDylib_FRAMEWORKS = Foundation UIKit
SpyDylib_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
