#!/bin/bash

# upload-dsyms.sh
# Cosmo Trader
#
# Script to upload dSYM files to Firebase Crashlytics for symbolication.
# This script should be run as a build phase or after archive builds.
#
# Usage:
#   ./upload-dsyms.sh
#   ./upload-dsyms.sh /path/to/archive.xcarchive
#
# Setup in Xcode:
# 1. Go to Build Phases
# 2. Add a new "Run Script" phase
# 3. Move it AFTER "Embed Frameworks"
# 4. Paste the script below (or reference this file)
#
# For release builds, add this as a post-archive action:
# 1. Edit Scheme > Archive > Post-actions
# 2. Add "New Run Script Action"
# 3. Paste: ${SRCROOT}/Scripts/upload-dsyms.sh

set -e

echo "=========================================="
echo "Firebase Crashlytics dSYM Upload Script"
echo "=========================================="

# Configuration
GOOGLE_SERVICE_PLIST="${SRCROOT}/Cosmo Trader/GoogleService-Info.plist"
FIREBASE_CRASHLYTICS_SCRIPT="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"

# Alternative path if using CocoaPods
if [ ! -f "$FIREBASE_CRASHLYTICS_SCRIPT" ]; then
    FIREBASE_CRASHLYTICS_SCRIPT="${PODS_ROOT}/FirebaseCrashlytics/run"
fi

# Alternative path for downloaded SDK
if [ ! -f "$FIREBASE_CRASHLYTICS_SCRIPT" ]; then
    FIREBASE_CRASHLYTICS_SCRIPT="${SRCROOT}/Frameworks/FirebaseCrashlytics/run"
fi

# Check if GoogleService-Info.plist exists
if [ ! -f "$GOOGLE_SERVICE_PLIST" ]; then
    echo "⚠️  Warning: GoogleService-Info.plist not found at:"
    echo "   $GOOGLE_SERVICE_PLIST"
    echo "   Crashlytics dSYM upload skipped."
    echo "   Please add GoogleService-Info.plist from Firebase Console."
    exit 0
fi

# Check if we're in a CI environment without Firebase
if [ "$CI" = "true" ] && [ ! -f "$FIREBASE_CRASHLYTICS_SCRIPT" ]; then
    echo "⚠️  CI environment detected without Firebase SDK."
    echo "   Skipping dSYM upload."
    exit 0
fi

# Check for archive path argument
ARCHIVE_PATH="$1"

# If no archive specified, try to find dSYMs in build directory
if [ -z "$ARCHIVE_PATH" ]; then
    echo "Looking for dSYMs in build directory..."

    if [ -d "${DWARF_DSYM_FOLDER_PATH}" ]; then
        DSYM_PATH="${DWARF_DSYM_FOLDER_PATH}"
        echo "Found dSYM folder: $DSYM_PATH"
    else
        echo "⚠️  No dSYM folder found in build directory."
        echo "   This is normal for Debug builds."
        exit 0
    fi
else
    # Extract dSYMs from archive
    echo "Archive path: $ARCHIVE_PATH"
    DSYM_PATH="${ARCHIVE_PATH}/dSYMs"

    if [ ! -d "$DSYM_PATH" ]; then
        echo "❌ Error: dSYMs folder not found in archive"
        exit 1
    fi
fi

echo ""
echo "Configuration:"
echo "  GoogleService-Info.plist: $GOOGLE_SERVICE_PLIST"
echo "  dSYM Path: $DSYM_PATH"
echo ""

# Check if Firebase Crashlytics script exists
if [ ! -f "$FIREBASE_CRASHLYTICS_SCRIPT" ]; then
    echo "⚠️  Firebase Crashlytics upload script not found."
    echo "   Attempting to use firebase-tools CLI instead..."

    # Check if firebase CLI is available
    if command -v firebase &> /dev/null; then
        echo "Using firebase CLI for dSYM upload..."

        # Get Google App ID from plist
        GOOGLE_APP_ID=$(/usr/libexec/PlistBuddy -c "Print :GOOGLE_APP_ID" "$GOOGLE_SERVICE_PLIST")

        if [ -z "$GOOGLE_APP_ID" ]; then
            echo "❌ Error: Could not read GOOGLE_APP_ID from GoogleService-Info.plist"
            exit 1
        fi

        echo "Google App ID: $GOOGLE_APP_ID"

        # Upload dSYMs using firebase CLI
        firebase crashlytics:symbols:upload \
            --app="$GOOGLE_APP_ID" \
            "$DSYM_PATH"

        echo ""
        echo "✅ dSYM upload completed successfully!"
    else
        echo "❌ Error: Neither Firebase SDK script nor firebase CLI found."
        echo "   Please install firebase-tools: npm install -g firebase-tools"
        echo "   Or ensure Firebase SDK is properly integrated."
        exit 1
    fi
else
    echo "Using Firebase Crashlytics upload script..."

    # Run Firebase Crashlytics upload script
    "$FIREBASE_CRASHLYTICS_SCRIPT" \
        -gsp "$GOOGLE_SERVICE_PLIST" \
        -p ios \
        "$DSYM_PATH"

    echo ""
    echo "✅ dSYM upload completed successfully!"
fi

echo ""
echo "=========================================="
echo "Upload Complete"
echo "=========================================="
