PROJECT  = copy-to-clipboard.xcodeproj
SCHEME   = copy-to-clipboard
BUILD_DIR = build
APP      = copy-to-clipboard.app
INSTALL  = $(HOME)/Applications
DMG      = copy-to-clipboard.dmg

.PHONY: build test install dmg clean register

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-configuration Release -derivedDataPath $(BUILD_DIR) \
		-allowProvisioningUpdates build

test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'platform=macOS'

install: build
	mkdir -p "$(INSTALL)"
	cp -R "$(BUILD_DIR)/Build/Products/Release/$(APP)" "$(INSTALL)/"
	@echo "Installed to $(INSTALL)/$(APP)"
	$(MAKE) clean

dmg: build
	rm -f "$(DMG)"
	hdiutil create -volname "Copy to Clipboard" \
		-srcfolder "$(BUILD_DIR)/Build/Products/Release/$(APP)" \
		-ov -format UDZO "$(DMG)"
	@echo "DMG created: $(DMG)"
	$(MAKE) clean

register:
	pluginkit -e use -i com.psenger.copy-to-clipboard.extension

clean:
	rm -rf $(BUILD_DIR)
