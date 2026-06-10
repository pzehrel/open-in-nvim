APP_NAME := OpenInNvim
APP_DISPLAY_NAME := 在 nvim 中打开
BUILD_DIR := build
APP_DIR := $(BUILD_DIR)/$(APP_DISPLAY_NAME).app
CONTENTS_DIR := $(APP_DIR)/Contents
MACOS_DIR := $(CONTENTS_DIR)/MacOS
RESOURCES_DIR := $(CONTENTS_DIR)/Resources

.PHONY: all build clean install

all: build

build:
	mkdir -p "$(MACOS_DIR)" "$(RESOURCES_DIR)"
	CLANG_MODULE_CACHE_PATH="$(CURDIR)/$(BUILD_DIR)/ModuleCache" swiftc -O -framework AppKit Sources/OpenInNvim/main.swift -o "$(MACOS_DIR)/$(APP_NAME)"
	cp Packaging/Info.plist "$(CONTENTS_DIR)/Info.plist"
	cp Resources/open-in-nvim.sh "$(RESOURCES_DIR)/open-in-nvim.sh"
	chmod +x "$(RESOURCES_DIR)/open-in-nvim.sh"

install: build
	mkdir -p "$(HOME)/Applications"
	rm -rf "$(HOME)/Applications/$(APP_DISPLAY_NAME).app"
	cp -R "$(APP_DIR)" "$(HOME)/Applications/$(APP_DISPLAY_NAME).app"
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$(HOME)/Applications/$(APP_DISPLAY_NAME).app"
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R "$(HOME)/Applications"

clean:
	rm -rf "$(BUILD_DIR)"
