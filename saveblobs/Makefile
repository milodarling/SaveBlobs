include theos/makefiles/common.mk

BUNDLE_NAME = SaveBlobs
SaveBlobs_FILES = MDSBRootListController.m
SaveBlobs_INSTALL_PATH = /Library/PreferenceBundles
SaveBlobs_FRAMEWORKS = UIKit
SaveBlobs_PRIVATE_FRAMEWORKS = Preferences
SaveBlobs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SaveBlobs.plist$(ECHO_END)
