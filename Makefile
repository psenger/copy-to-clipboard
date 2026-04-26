PROJECT  = copy-to-clipboard.xcodeproj
SCHEME   = copy-to-clipboard
BUILD_DIR = build
APP      = copy-to-clipboard.app
INSTALL  = $(HOME)/Applications

.PHONY: build test install clean

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-configuration Release -derivedDataPath $(BUILD_DIR) build

test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'platform=macOS'

install: build
	mkdir -p "$(INSTALL)"
	cp -R "$(BUILD_DIR)/Build/Products/Release/$(APP)" "$(INSTALL)/"
	codesign --sign - "$(INSTALL)/$(APP)"
	@echo ""
	@echo "Installed to $(INSTALL)/$(APP)"
	@echo "Right-click the app in Finder and choose Open once to clear Gatekeeper."

clean:
	rm -rf $(BUILD_DIR)
