# Cosmo Trader Build Scripts

This directory contains scripts for managing app versioning and build processes.

## Overview

| Script | Purpose |
|--------|---------|
| `increment_build.sh` | Auto-increments build number on Release builds |
| `version_bump.sh` | Semantic versioning for major/minor/patch updates |
| `upload-dsyms.sh` | Uploads dSYM files to Crashlytics |
| `verify_no_secrets.sh` | Verifies Release app/archive/export payloads do not contain local secrets/config/docs |

## Versioning System

Cosmo Trader follows [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH (Build)
  │     │     │      └── Incremented automatically on each Release build
  │     │     └────────── Bug fixes, small tweaks
  │     └──────────────── New features, non-breaking changes
  └────────────────────── Breaking changes, major releases
```

**Examples:**
- `1.0 (1)` → Initial release
- `1.0 (42)` → 42nd build of version 1.0
- `1.1 (1)` → New feature release, build reset to 1
- `2.0 (1)` → Major release with breaking changes

## increment_build.sh

Automatically increments the build number for Release builds and generates build metadata.

### Setup in Xcode

1. Select your target in Xcode
2. Go to **Build Phases**
3. Click **+** → **New Run Script Phase**
4. Name it "Increment Build Number"
5. **Move it BEFORE "Compile Sources"**
6. Add the script:

```bash
"${SRCROOT}/Scripts/increment_build.sh"
```

### What It Does

1. **On Release builds:**
   - Increments `CURRENT_PROJECT_VERSION` in project.pbxproj
   - Generates `BuildInfo.generated.swift` with build metadata

2. **On Debug builds:**
   - Skips build increment (for faster iteration)
   - Still generates `BuildInfo.generated.swift` (without increment)

3. **Generated metadata includes:**
   - Build timestamp
   - Git commit hash
   - Git branch name
   - Build configuration

### Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `SKIP_BUILD_INCREMENT` | `0` | Set to `1` to skip increment entirely |
| `INCREMENT_ON_DEBUG` | `0` | Set to `1` to also increment on Debug builds |

### Example Output

```
[Build] Release build detected - will increment build number
[Build] Current version: 1.0 (42)
[Build] Build number incremented: 42 → 43
[Build] Generated BuildInfo.generated.swift
[Build] Build: 1.0 (43)
[Build] Timestamp: 2024-01-15 10:30:00
[Build] Git: main@abc1234
```

## version_bump.sh

Manual semantic versioning script for major/minor/patch releases.

### Usage

```bash
# Show current version
./Scripts/version_bump.sh current

# Bump patch version (1.0.0 → 1.0.1)
./Scripts/version_bump.sh patch

# Bump minor version (1.0.0 → 1.1.0)
./Scripts/version_bump.sh minor

# Bump major version (1.0.0 → 2.0.0)
./Scripts/version_bump.sh major

# Set specific version
./Scripts/version_bump.sh set 2.0.0
```

### Options

| Option | Description |
|--------|-------------|
| `--no-tag` | Skip git tag creation |
| `--no-commit` | Skip git commit |
| `--push` | Push tags to remote after creation |
| `--dry-run` | Preview changes without applying |

### What It Does

1. Updates `MARKETING_VERSION` in project.pbxproj
2. Resets `CURRENT_PROJECT_VERSION` to 1
3. Creates a git commit (optional)
4. Creates an annotated git tag (optional)
5. Pushes tags to remote (optional)

### Example: Release Workflow

```bash
# 1. Preview the change
./Scripts/version_bump.sh minor --dry-run

# 2. Bump version and create tag
./Scripts/version_bump.sh minor

# 3. Or bump and push in one step
./Scripts/version_bump.sh minor --push
```

### Git Tags

Tags are created in the format `v{VERSION}`:
- `v1.0` → Version 1.0
- `v1.1` → Version 1.1
- `v2.0` → Version 2.0

## BuildInfo

The app exposes version information through `BuildInfo`:

```swift
// Version info
BuildInfo.version        // "1.0"
BuildInfo.build          // "42"
BuildInfo.fullVersion    // "1.0 (42)"
BuildInfo.displayVersion // "v1.0"

// Build metadata (from generated file)
BuildInfo.buildTimestamp // "2024-01-15 10:30:00"
BuildInfo.gitCommit      // "abc1234"
BuildInfo.gitBranch      // "main"

// Environment
BuildInfo.isDebug        // true/false
BuildInfo.isRelease      // true/false
BuildInfo.isTestFlight   // true/false
BuildInfo.environment    // .development/.staging/.production
```

## Release Checklist

### For a New Release

1. **Ensure all changes are committed**
   ```bash
   git status  # Should be clean
   ```

2. **Run tests**
   ```bash
   xcodebuild test -scheme "Cosmo Trader" -destination "platform=iOS Simulator,name=iPhone 15"
   ```

3. **Bump version**
   ```bash
   # For new features
   ./Scripts/version_bump.sh minor

   # For bug fixes only
   ./Scripts/version_bump.sh patch

   # For breaking changes
   ./Scripts/version_bump.sh major
   ```

4. **Build Release**
   ```bash
   # Build will auto-increment build number
   xcodebuild -scheme "Cosmo Trader" -configuration Release
   ```

5. **Validate the release artifact**
   ```bash
   ./Scripts/verify_no_secrets.sh /path/to/Cosmo\ Trader.xcarchive
   # or, after export:
   ./Scripts/verify_no_secrets.sh /path/to/Cosmo\ Trader.ipa
   ```

   The verifier guards against accidental app-bundled secrets, local config,
   templates, private keys/certs, and documentation. A signed iOS archive or
   exported IPA may normally contain `embedded.mobileprovision` at the root of
   the signed `.app`; that signing payload is allowed. Provisioning profiles in
   copied resources or any other nonstandard location still fail validation.

6. **Push tags**
   ```bash
   git push origin main --tags
   ```

7. **Archive for App Store**
   - Product → Archive in Xcode
   - Run `verify_no_secrets.sh` against the final archive/export
   - Upload to App Store Connect

### Version Numbering Guidelines

| Change Type | Version Bump | Example |
|-------------|--------------|---------|
| Bug fix | Patch | 1.0.0 → 1.0.1 |
| New feature | Minor | 1.0.0 → 1.1.0 |
| Breaking change | Major | 1.0.0 → 2.0.0 |
| UI polish | Patch | 1.0.0 → 1.0.1 |
| Performance improvement | Patch | 1.0.0 → 1.0.1 |
| API change (breaking) | Major | 1.0.0 → 2.0.0 |
| New subscription tier | Minor | 1.0.0 → 1.1.0 |

## Troubleshooting

### Build number not incrementing

1. Check script is in Build Phases
2. Ensure it runs BEFORE Compile Sources
3. Verify you're building Release configuration
4. Check script has execute permission:
   ```bash
   chmod +x Scripts/increment_build.sh
   ```

### Generated file not updating

1. Clean build folder (Cmd+Shift+K)
2. Rebuild project
3. Check `Configuration/BuildInfo.generated.swift` exists

### Git tag already exists

```bash
# Delete local tag
git tag -d v1.0

# Delete remote tag (if pushed)
git push origin :refs/tags/v1.0

# Re-run version bump
./Scripts/version_bump.sh set 1.0
```

### version_bump.sh not finding project file

Ensure you run from the correct directory:
```bash
cd "Cosmo Trader"
./Scripts/version_bump.sh current
```
