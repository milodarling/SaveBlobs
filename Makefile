ARCHS = armv7 arm64
TARGET = iphone:clang:latest:latest

include theos/makefiles/common.mk

TWEAK_NAME = SaveBlobs
SaveBlobs_FILES = Tweak.xm
SaveBlobs_FRAMEWORKS = UIKit
SaveBlobs_LIBRARIES = activator MobileGestalt
SaveBlobs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
