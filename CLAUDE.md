# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sardoba is a Flutter restaurant application providing a branch-based mobile experience with location-aware features, menu exploration, cashback rewards, and promotional campaigns. The app supports multi-branch operations with Yandex MapKit integration for branch discovery.

**Tech Stack:**
- Flutter 3.5+ / Dart 3.5+
- `yandex_mapkit` for maps and geolocation
- `shared_preferences` for local persistence
- `dio` for HTTP requests
- `crypto` for PIN hashing
- `flutter_svg` for vector assets

## Common Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app (default device)
flutter run

# Run on specific device
flutter run -d <device-id>

# Run tests
flutter test

# Run linter
flutter analyze

# Build release APK (Android)
flutter build apk --release

# Build release IPA (iOS)
flutter build ios --release

# Generate launcher icons
flutter pub run flutter_launcher_icons

# Clean build artifacts
flutter clean
```

## Architecture

### Application Bootstrap Flow

1. **main.dart**: Entry point initializes `AuthStorage`, resolves start destination based on authentication state
2. **Routing Logic**:
   - No user → `OnboardingScreen`
   - Has user + PIN set → `PinLockScreen` → `EntryPoint`
   - Has user, no PIN → `EntryPoint` directly
3. **Token Refresh**: On launch, attempts to sync profile with backend using stored tokens; falls back to token refresh if 401 encountered

### Core Navigation Structure

**EntryPoint** (`lib/entry_point.dart`) is the main authenticated container with bottom navigation:
- Tab 0: `HomeScreen` - promotions, news, loyalty summary
- Tab 1: `CatalogScreen` - branch-scoped menu
- Tab 2: `LocationsScreen` - branch directory with map
- Tab 3: `ProfileScreen` - user settings, cashback history
- Center FAB: `QrScreen` - QR code display for in-store scanning

Use `EntryPoint.selectTab(context, index)` to programmatically switch tabs from child screens.

### State Management Patterns

**Global Singletons:**
- `AuthStorage.instance` - persistence layer for accounts, tokens, PIN
- `AppLanguage.instance` - locale state (Russian/Uzbek), notifies listeners on change
- `BranchState.instance` - manages 4 hardcoded branches, active branch selection
- `CatalogStorage.instance` - caches menu data per branch
- `FavoriteProducts.instance` - tracks favorited product IDs
- `NotificationPreferences.instance` - stores notification settings

**Service Layer:**
- `AuthService` - OAuth-style token management, profile fetch/update, photo upload
  - Base URL: `http://185.217.131.110:8000`
  - Throws `AuthUnauthorizedException` on 401 (trigger re-auth or refresh)
  - Throws `AuthServiceException` for other errors
- `CatalogService` / `CatalogRepository` - fetches menu for specific `storeId`
- `CashbackService` - retrieves cashback transactions
- `NewsService` - loads promotional banners
- `NotificationService` - manages in-app notifications

All services use Dio, should be `.dispose()`d after use.

### Authentication & Session Management

**Account Model** (`lib/models/account.dart`):
- Stored as JSON list in SharedPreferences
- Primary key is normalized phone (digits only with `+` prefix)
- Contains: `id`, `name`, `phone`, `cashbackBalance`, `loyalty`, `dateOfBirth`, `profilePhotoUrl`, `referralCode`, `waiterId`

**Token Flow:**
1. User enters phone → backend sends OTP
2. `AuthService.verifyOtp()` returns `AuthSession` with tokens
3. Save via `AuthStorage.saveAuthTokens()` and `upsertAccount()`
4. On 401 errors, call `AuthStorage.refreshTokens()` which uses refresh token
5. If refresh fails, call `AppNavigator.forceLogout()` to reset to onboarding

**PIN Security:**
- PINs are SHA-256 hashed before storage
- `AuthStorage.savePin(pin)` / `verifyPin(pin)` / `clearPin()`
- PIN gates entry after splash if user is authenticated

### Branch Management

**BranchState** (`lib/services/branch_state.dart`):
- 4 branches hardcoded: Geofizika, Gijdivon, Severniy, MK-5
- Each has `id`, `storeId` (for catalog API), localized addresses, `Point` coordinates
- `selectBranch(branch)` / `selectBranchById(id)` switches active branch
- Catalog screens filter by `BranchState.instance.activeBranch.storeId`

### Localization

**AppLocalizations** (`lib/app_localizations.dart`):
- Custom implementation (not ARB-based)
- Supports Russian (`ru`) and Uzbek (`uz`)
- Access via `AppLocalizations.of(context).translate(key)`
- Language switcher uses `AppLanguage.instance.setLocale(AppLocale.uz)`

**Localized Fields:**
- Branch addresses: `branch.localizedAddresses[AppLanguage.instance.locale]`
- Product names/descriptions: handle via model `localizedName`/`localizedDescription` fields

## Code Patterns & Conventions

### Theme & Styling
- Primary color: `#22A45D` (green)
- Defined in `lib/constants.dart`: `primaryColor`, `bodyTextColor`, `titleColor`
- Use `kDefaultOutlineInputBorder`, `kButtonTextStyle` for consistency
- Bottom nav uses glassmorphic blur effect (`BackdropFilter`)

### Widget Naming
- Prefix private widgets with `_` (e.g., `_NavItem`, `_AnimatedQrButton`)
- Screen classes end in `Screen` (e.g., `HomeScreen`, `ProfileScreen`)
- Service classes end in `Service` or `Storage`

### Error Handling
- Wrap API calls in try-catch, distinguish `AuthUnauthorizedException` from generic errors
- Show user-friendly error messages via `ScaffoldMessenger.of(context).showSnackBar()`
- Log unexpected errors for debugging but never expose raw exceptions to UI

### Data Persistence
- Use `AuthStorage` methods, not direct SharedPreferences access
- Phone numbers normalized before storage (digits + `+` prefix)
- JSON serialization via `toJson()` / `fromJson()` in models

## Testing

- Widget tests: `flutter test`
- Default test file: `test/widget_test.dart` (currently minimal)
- No integration tests configured yet

## Platform-Specific Notes

**Android:**
- `AndroidManifest.xml` configured for location permissions (Yandex Maps)
- Check `android/app/src/main/AndroidManifest.xml` for required permissions

**iOS:**
- `Info.plist` requires location usage descriptions
- Podfile uses CocoaPods for dependency management
- Run `cd ios && pod install` after adding native dependencies

**Yandex MapKit:**
- Requires API key (usually set in platform manifests or via initialization)
- Branch coordinates use `Point(latitude:, longitude:)`

## Important Considerations

- **API Base URL**: Hardcoded in `AuthService._defaultBaseUrl`, may need environment variable for staging/prod
- **Branch Data**: Currently hardcoded in `BranchState`, future versions should fetch from API
- **Token Refresh**: Automatic on 401 in `main.dart` startup, but screens must handle refresh failures
- **PIN Reset**: No "forgot PIN" flow; users must reinstall to reset
- **Profile Photos**: Uploaded via multipart form data to `/api/v1/files/profile-photo`
- **Cashback**: Tied to loyalty tiers; fetch via `AuthService.fetchProfileWithToken()` which embeds cashback data
