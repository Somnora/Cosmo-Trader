#!/bin/bash

# verify_no_secrets.sh
# Scans a Release archive, exported .ipa, or built app bundle to ensure no
# local secrets/config/sample/docs are included.
# Usage: ./verify_no_secrets.sh [path_to_xcarchive_ipa_or_app_bundle]
#
# Policy: signed iOS apps may legitimately contain an app-root
# embedded.mobileprovision created by the signing/export process. This script
# allows only that normal signing payload and still fails on provisioning
# profiles copied into resources, archives, source-like folders, or any other
# nonstandard location.
#
# When wired as an Xcode "Run Script" phase, pass:
#   "${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
# Only prints filenames, never file contents.

set -u

INPUT_PATH="${1:-${ARCHIVE_PATH:-}}"
APP_PATH=""
SCAN_ROOT=""
TEMP_DIR=""

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

find_app_in_archive() {
    archive_path="$1"
    find "$archive_path/Products/Applications" -maxdepth 1 -name "*.app" -type d -print 2>/dev/null | head -n 1
}

find_app_in_ipa_payload() {
    payload_path="$1"
    find "$payload_path/Payload" -maxdepth 1 -name "*.app" -type d -print 2>/dev/null | head -n 1
}

find_latest_archive_app() {
    find "${PROJECT_DIR:-.}" "../build" "build" -name "*.xcarchive" -type d -print 2>/dev/null \
        | while IFS= read -r archive_path; do
            app_path=$(find_app_in_archive "$archive_path")
            if [ -n "$app_path" ]; then
                printf '%s\n' "$app_path"
            fi
        done \
        | head -n 1
}

case "$INPUT_PATH" in
    *.xcarchive)
        if [ ! -d "$INPUT_PATH" ]; then
            echo "error: archive path does not exist: $INPUT_PATH" >&2
            exit 1
        fi
        APP_PATH=$(find_app_in_archive "$INPUT_PATH")
        SCAN_ROOT="$INPUT_PATH"
        ;;
    *.ipa)
        if [ ! -f "$INPUT_PATH" ]; then
            echo "error: ipa path does not exist: $INPUT_PATH" >&2
            exit 1
        fi
        TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/verify-no-secrets.XXXXXX")
        if ! unzip -q "$INPUT_PATH" -d "$TEMP_DIR"; then
            echo "error: failed to unzip ipa: $INPUT_PATH" >&2
            exit 1
        fi
        APP_PATH=$(find_app_in_ipa_payload "$TEMP_DIR")
        SCAN_ROOT="$TEMP_DIR"
        ;;
    *.app)
        APP_PATH="$INPUT_PATH"
        SCAN_ROOT="$INPUT_PATH"
        ;;
    "")
        if [ -n "${TARGET_BUILD_DIR:-}" ] && [ -n "${WRAPPER_NAME:-}" ] && [ -d "${TARGET_BUILD_DIR}/${WRAPPER_NAME}" ]; then
            APP_PATH="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
            SCAN_ROOT="$APP_PATH"
        else
            APP_PATH=$(find_latest_archive_app)
            if [ -n "$APP_PATH" ]; then
                SCAN_ROOT="$APP_PATH"
            fi
        fi
        ;;
    *)
        if [ -d "$INPUT_PATH" ]; then
            APP_PATH=$(find "$INPUT_PATH" -name "*.app" -type d -print 2>/dev/null | head -n 1)
            SCAN_ROOT="$INPUT_PATH"
        fi
        ;;
esac

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "error: verify_no_secrets.sh could not find an .app bundle to scan." >&2
    echo "Usage: $0 /path/to/Cosmo\\ Trader.xcarchive" >&2
    echo "   or: $0 /path/to/Cosmo\\ Trader.app" >&2
    echo "   or: $0 /path/to/Cosmo\\ Trader.ipa" >&2
    exit 1
fi

if [ -z "$SCAN_ROOT" ] || [ ! -d "$SCAN_ROOT" ]; then
    SCAN_ROOT="$APP_PATH"
fi

echo "verify_no_secrets: scanning app bundle: $APP_PATH"
echo "verify_no_secrets: provisioning policy allows only app-root embedded.mobileprovision"

ISSUES=0

# Filenames that must never ship inside the bundle, anywhere in the tree.
# NOTE: Secrets.plist is intentionally NOT here. The app calls Finnhub
# directly from the client, so its client API key is inherently shipped in
# the bundle and is read at runtime from the bundled Secrets.plist
# (CosmoConfig). check_bundled_secrets_plist below allows that file ONLY if
# it contains solely client-safe runtime keys — any server credential still
# fails the build.
FORBIDDEN_NAMES=(
    ".DS_Store"
    "Secrets-template.plist"
    "Secrets.xcconfig"
    "Secrets.xcconfig.sample"
    "Base.xcconfig"
    "Debug.xcconfig"
    "Staging.xcconfig"
    "Release.xcconfig"
    "GoogleService-Info.plist.sample"
    "GoogleService-Info_CT.plist"
    "ExportOptions.plist"
    "README.md"
    "AppStoreMetadata.md"
    "SDKIntegration.md"
    "Screenshots.md"
)

for name in "${FORBIDDEN_NAMES[@]}"; do
    matches=$(find "$APP_PATH" -name "$name" -print 2>/dev/null)
    if [ -n "$matches" ]; then
        echo "FAILED: $name found in bundle:"
        echo "$matches" | sed 's/^/  /'
        ISSUES=1
    fi
done

check_find_expr() {
    label="$1"
    shift
    matches=$(find "$APP_PATH" "$@" -print 2>/dev/null)
    if [ -n "$matches" ]; then
        echo "FAILED: $label present in app bundle:"
        echo "$matches" | sed 's/^/  /'
        ISSUES=1
    fi
}

check_find_expr ".xcconfig file(s)" -type f -name "*.xcconfig"
check_find_expr "*.sample file(s)" -type f -name "*.sample"
check_find_expr "documentation file(s)" -type f \( -name "*.md" -o -name "*.markdown" -o -name "*.doc" -o -name "*.docx" \)
check_find_expr "local environment file(s)" -type f \( -name ".env" -o -name ".env.*" -o -name "*.env" \)
check_find_expr "private key/certificate file(s)" -type f \( -name "*.p8" -o -name "*.p12" -o -name "*.cer" -o -name "*.key" -o -name "*.pem" \)
check_find_expr "documentation directory" -type d \( -name "Documentation" -o -name "Docs" -o -name "docs" \)
check_find_expr "__MACOSX directory" -type d -name "__MACOSX"

# A client Finnhub key must ship (direct client API calls), so the bundled
# Secrets.plist is allowed — but ONLY if every key it carries is on the
# client-safe allowlist. A server credential (e.g. a backend API key) added
# to Secrets.plist must never reach a shipped bundle. Prints key NAMES only,
# never values.
check_bundled_secrets_plist() {
    plist=$(find "$APP_PATH" -name "Secrets.plist" -type f -print 2>/dev/null | head -n 1)
    if [ -z "$plist" ]; then
        return
    fi

    allowed_keys=" FINNHUB_API_KEY BACKEND_BASE_URL "
    # Depth-agnostic: plutil -p prints every dictionary key at every nesting
    # level as "KeyName" => …, so a server secret hidden inside a nested
    # dict is still caught (a top-level-only scan would miss it). Fails
    # closed — any key not on the allowlist, at any depth, blocks the build.
    keys=$(plutil -p "$plist" 2>/dev/null \
        | grep -oE '"[A-Za-z_][A-Za-z0-9_]*" =>' \
        | sed -E 's/" =>$//; s/^"//')

    bad_keys=""
    while IFS= read -r k; do
        [ -z "$k" ] && continue
        case "$allowed_keys" in
            *" $k "*) ;;
            *) bad_keys="${bad_keys}${k} " ;;
        esac
    done <<EOF
$keys
EOF

    if [ -n "$bad_keys" ]; then
        echo "FAILED: bundled Secrets.plist carries non-allowlisted key(s): ${bad_keys}"
        echo "  Only client-safe runtime keys may ship in Secrets.plist:${allowed_keys}"
        echo "  A server credential must never be bundled. Remove it or move it server-side."
        ISSUES=1
    else
        echo "OK: bundled Secrets.plist carries only client-safe runtime keys."
    fi
}

check_provisioning_profiles() {
    allowed_profile="${APP_PATH%/}/embedded.mobileprovision"
    matches=$(find "$SCAN_ROOT" -type f \( -name "*.mobileprovision" -o -name "*.provisionprofile" \) -print 2>/dev/null)
    if [ -z "$matches" ]; then
        return
    fi

    unsafe_matches=""
    while IFS= read -r profile_path; do
        if [ "$profile_path" = "$allowed_profile" ]; then
            continue
        fi
        unsafe_matches="${unsafe_matches}${profile_path}
"
    done <<EOF
$matches
EOF

    if [ -n "$unsafe_matches" ]; then
        echo "FAILED: provisioning profile(s) outside normal signed app location:"
        printf '%s' "$unsafe_matches" | sed '/^$/d; s/^/  /'
        echo "Allowed location: $allowed_profile"
        ISSUES=1
    elif [ -f "$allowed_profile" ]; then
        echo "OK: allowed signing payload present: $allowed_profile"
    fi
}

check_provisioning_profiles
check_bundled_secrets_plist

if [ "$ISSUES" -eq 0 ]; then
    echo "OK: no forbidden secrets/config/sample/docs found in bundle."
else
    echo "FAILURE: forbidden release payload files found. Do NOT distribute this build." >&2
    echo "Action: remove target membership in Xcode or update file-system-synchronized membership exceptions." >&2
fi

exit "$ISSUES"
