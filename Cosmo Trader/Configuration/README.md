# Environment Configuration

Cosmo Trader uses xcconfig files for environment-specific configuration. This allows different settings for development, staging, and production builds.

## Quick Setup

1. Copy the secrets template:
   ```bash
   cd "Cosmo Trader/Configuration"
   cp Secrets.xcconfig.sample Secrets.xcconfig
   ```

2. Edit `Secrets.xcconfig` with your API keys:
   ```
   FINNHUB_API_KEY = your_key_here
   MIXPANEL_TOKEN = your_token_here
   ```

3. Build and run with the appropriate scheme.

## Environments

| Environment | Scheme | Bundle ID Suffix | Features |
|-------------|--------|------------------|----------|
| Development | Cosmo Trader Debug | `.dev` | Debug UI, Mock Data, Verbose Logging |
| Staging | Cosmo Trader Staging | `.staging` | Debug UI, Verbose Logging |
| Production | Cosmo Trader Release | (none) | Analytics, Crash Reporting |

## File Structure

```
Configuration/
├── Base.xcconfig          # Shared settings
├── Debug.xcconfig         # Development build settings
├── Staging.xcconfig       # Staging/QA build settings
├── Release.xcconfig       # Production build settings
├── Secrets.xcconfig       # Your API keys (gitignored)
└── Secrets.xcconfig.sample # Template for API keys
```

## How It Works

### xcconfig Hierarchy

```
Debug.xcconfig
    └── #include "Base.xcconfig"
    └── #include? "Secrets.xcconfig"  (optional - won't fail if missing)
```

### Info.plist Integration

Values from xcconfig files are passed to the app via Info.plist:

```xml
<key>APP_ENVIRONMENT</key>
<string>$(APP_ENVIRONMENT)</string>
<key>FINNHUB_API_KEY</key>
<string>$(FINNHUB_API_KEY)</string>
```

### Swift Access

```swift
// Get current environment
let env = AppEnvironment.current  // .development, .staging, .production

// Get API keys
let key = APIConfig.finnhubKey

// Check feature flags
if APIConfig.showDebugUI {
    // Show debug features
}
```

## API Keys

### Finnhub (Stock Quotes)
1. Sign up at https://finnhub.io
2. Get your free API key from the dashboard
3. Add to `Secrets.xcconfig`:
   ```
   FINNHUB_API_KEY = your_key_here
   ```

### Mixpanel (Analytics)
1. Sign up at https://mixpanel.com
2. Create a project and get the token
3. Add to `Secrets.xcconfig`:
   ```
   MIXPANEL_TOKEN = your_token_here
   ```

## Environment-Specific Keys

For separate keys per environment:

```
# Secrets.xcconfig

# Development keys
FINNHUB_API_KEY = dev_key_here
MIXPANEL_TOKEN = dev_token_here

# Staging keys (uncomment if using)
# FINNHUB_API_KEY_STAGING = staging_key_here
# MIXPANEL_TOKEN_STAGING = staging_token_here

# Production keys (uncomment if using)
# FINNHUB_API_KEY_PRODUCTION = prod_key_here
# MIXPANEL_TOKEN_PRODUCTION = prod_token_here
```

## Feature Flags

Feature availability by environment:

| Feature | Development | Staging | Production |
|---------|-------------|---------|------------|
| Analytics | Off | Off | On |
| Crash Reporting | Off | Off | On |
| Debug UI | On | On | Off |
| Mock Data | On | Off | Off |
| Verbose Logging | On | On | Off |

Access in code:
```swift
APIConfig.analyticsEnabled      // true in production
APIConfig.crashReportingEnabled // true in production
APIConfig.showDebugUI           // true in dev/staging
APIConfig.useMockData           // true in development
APIConfig.verboseLogging        // true in dev/staging
```

## Debug Environment Indicator

In non-production builds, an environment badge appears showing "DEV" or "STG":

```swift
// Add to any view
MyView()
    .environmentIndicator()

// Or use directly
EnvironmentBadge()
```

## Xcode Project Setup

To use xcconfig files with your Xcode project:

1. Open Project Settings
2. Select your target
3. Under "Configurations", set:
   - Debug → `Debug.xcconfig`
   - Release → `Release.xcconfig`
4. Create additional configurations for Staging if needed

## Security Notes

- `Secrets.xcconfig` is in `.gitignore` - never commit it
- `Secrets.plist` is also gitignored for legacy support
- Use different API keys for each environment
- Production keys should only exist on CI/CD systems

## Troubleshooting

### API keys not loading
1. Verify `Secrets.xcconfig` exists in Configuration folder
2. Check xcconfig syntax (no quotes around values)
3. Clean build folder (Cmd+Shift+K)
4. Verify Info.plist has the variable references

### Wrong environment showing
1. Check which scheme you're using
2. Verify xcconfig is linked in project settings
3. Clean and rebuild

### Build fails with missing file
The `#include?` directive makes Secrets.xcconfig optional. If you see errors about missing files, check that Base.xcconfig exists.
