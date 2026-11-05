PROJECT := AgenticDeveloperHubSDK.xcodeproj
SCHEME ?= AgenticDeveloperHubSDKAll
CONFIGURATION ?= Debug
DESTINATION ?= platform=macOS,arch=arm64
DERIVED_DATA := $(HOME)/Library/Developer/Xcode/DerivedData/AgenticDeveloperHubSDK-managed

XCODEBUILD := xcodebuild \
	-project $(PROJECT) \
	-scheme $(SCHEME) \
	-configuration $(CONFIGURATION) \
	-destination '$(DESTINATION)' \
	-derivedDataPath $(DERIVED_DATA)

.PHONY: build test clean print-derived-data

build:
	$(XCODEBUILD) build

test:
	$(XCODEBUILD) test

clean:
	$(XCODEBUILD) clean
	rm -rf $(DERIVED_DATA)

print-derived-data:
	@echo $(DERIVED_DATA)
