#!/usr/bin/env bash

set -ex

set -o pipefail && xcodebuild -project alt-tab-macos.xcodeproj -scheme Release -derivedDataPath DerivedData ARCHS="x86_64 arm64" CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO | scripts/xcbeautify

file "$BUILD_DIR/$XCODE_BUILD_PATH/$APP_NAME.app/Contents/MacOS/$APP_NAME"
