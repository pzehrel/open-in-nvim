APP_NAME := OpenInNvim
APP_DISPLAY_NAME := Open-In-Nvim
EXTENSION_NAME := OpenInNvimFinderSync
BUILD_DIR := build
APP_DIR := $(BUILD_DIR)/$(APP_DISPLAY_NAME).app
CONTENTS_DIR := $(APP_DIR)/Contents
MACOS_DIR := $(CONTENTS_DIR)/MacOS
RESOURCES_DIR := $(CONTENTS_DIR)/Resources
PLUGINS_DIR := $(CONTENTS_DIR)/PlugIns
EXTENSION_DIR := $(PLUGINS_DIR)/$(EXTENSION_NAME).appex
EXTENSION_CONTENTS_DIR := $(EXTENSION_DIR)/Contents
EXTENSION_MACOS_DIR := $(EXTENSION_CONTENTS_DIR)/MacOS
INSTALL_DIR ?= /Applications
INSTALLED_APP := $(INSTALL_DIR)/$(APP_DISPLAY_NAME).app

.PHONY: all build clean install

all: build

build:
	mkdir -p "$(MACOS_DIR)" "$(RESOURCES_DIR)" "$(EXTENSION_MACOS_DIR)"
	CLANG_MODULE_CACHE_PATH="$(CURDIR)/$(BUILD_DIR)/ModuleCache" swiftc -O -framework AppKit Sources/OpenInNvim/main.swift -o "$(MACOS_DIR)/$(APP_NAME)"
	CLANG_MODULE_CACHE_PATH="$(CURDIR)/$(BUILD_DIR)/ModuleCache" swiftc -O -application-extension -module-name $(EXTENSION_NAME) -framework AppKit -framework FinderSync Sources/OpenInNvimFinderSync/FinderSync.swift -o "$(EXTENSION_MACOS_DIR)/$(EXTENSION_NAME)"
	cp Packaging/Info.plist "$(CONTENTS_DIR)/Info.plist"
	cp Packaging/FinderSyncInfo.plist "$(EXTENSION_CONTENTS_DIR)/Info.plist"
	cp Resources/open-in-nvim.sh "$(RESOURCES_DIR)/open-in-nvim.sh"
	chmod +x "$(RESOURCES_DIR)/open-in-nvim.sh"
	chmod +x "$(EXTENSION_MACOS_DIR)/$(EXTENSION_NAME)"
	/usr/bin/codesign --force --deep --sign - "$(APP_DIR)"

install: build
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(HOME)/Applications/在 nvim 中打开.app"
	rm -rf "$(HOME)/Applications/$(APP_DISPLAY_NAME).app"
	rm -rf "$(INSTALLED_APP)"
	cp -R "$(APP_DIR)" "$(INSTALLED_APP)"
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$(INSTALLED_APP)"
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R "$(INSTALL_DIR)"
	-/usr/bin/pluginkit -r "$(INSTALLED_APP)/Contents/PlugIns/$(EXTENSION_NAME).appex"
	-/usr/bin/pluginkit -a "$(INSTALLED_APP)/Contents/PlugIns/$(EXTENSION_NAME).appex"

clean:
	rm -rf "$(BUILD_DIR)"
