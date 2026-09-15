#!/bin/sh
# Pushes the screenshots in AppStore/screenshots to App Store Connect.
#
# Needs an App Store Connect API key with the App Manager role. Keep the .p8 outside this
# repo — it is a credential, and .gitignore does not cover it.
#
#   ASC_KEY=/path/to/AuthKey.p8 ASC_KEY_ID=XXXXXXXXXX ASC_ISSUER_ID=xxxx-xxxx \
#       Tools/push-screenshots.sh
#
# Re-running is safe: each set is emptied first, so the listing order always matches the
# filenames on disk. Nothing here submits the app for review.
set -e
root=$(cd "$(dirname "$0")/.." && pwd)
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT
swiftc -O -swift-version 5 \
    -target arm64-apple-macos14.0 \
    -o "$build/push-screenshots" \
    "$root/Tools/ASC/Client.swift" \
    "$root/Tools/Screenshots/main.swift"
"$build/push-screenshots" "$root"
