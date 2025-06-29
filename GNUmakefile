include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = GhostBSDAppStore
VERSION = 1.0

GhostBSDAppStore_OBJC_FILES = \
	main.m \
	AppDelegate.m \
	Package.m \
	PackageManager.m \
	PackageDetailWindow.m \
	CategoryWindow.m \
	PasswordPanel.m \
	SudoManager.m \
	NetworkManager.m \
	ErrorRecoveryPanel.m

GhostBSDAppStore_HEADER_FILES = \
	AppDelegate.h \
	Package.h \
	PackageManager.h \
	PackageDetailWindow.h \
	CategoryWindow.h \
	PasswordPanel.h \
	SudoManager.h \
	NetworkManager.h \
	ErrorRecoveryPanel.h \
	ConfigurationManager.h

GhostBSDAppStore_RESOURCE_FILES = \
	Resources/placeholder.png

# Additional compiler flags
ADDITIONAL_OBJCFLAGS += -Wall -Wextra -Wno-unused-parameter
ADDITIONAL_LDFLAGS += 

# Link with AppKit and Foundation
GhostBSDAppStore_GUI_LIBS += -lgnustep-gui -lgnustep-base

include $(GNUSTEP_MAKEFILES)/application.make
