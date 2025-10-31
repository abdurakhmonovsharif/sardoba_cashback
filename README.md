# Sardoba Restaurant App UI Kit

Sardoba is a Flutter UI starter for restaurant brands who want to launch a
branch-based mobile experience fast. The kit ships with branch catalogs, menu
exploration per location, dynamic promotions, and a cashback rewards flow that
keeps diners engaged without having to build the core UX from scratch.

## Highlights
- Branch directory with location details powered by Yandex MapKit
- Menu layouts scoped per branch, including rich imagery and pricing states
- Cashback wallet module for earning, tracking, and redeeming rewards
- Campaign banners and promo callouts that surface timely offers
- Skeleton loading states, light/dark theming, and localization scaffolding
- Fully responsive Flutter UI components for Android and iOS

## Tech Stack
- Flutter 3.5+ and Dart 3
- `flutter_svg` for vector assets and iconography
- `shared_preferences` for local caching and session state
- `yandex_mapkit` for map views and branch positioning
- `form_field_validator`, `crypto`, `url_launcher`, and `.env` driven configs

## Project Structure
- `lib/screens` – page layouts such as branch lists, menus, auth, and loyalty
- `lib/components` – reusable widgets (cards, headers, progress indicators)
- `lib/models` – data models for branches, menu items, and loyalty balances
- `lib/services` – integrations and helpers (API, storage, localization)
- `assets/` – illustrations, icons, and branding resources bundled in the app

## Getting Started
1. Install Flutter 3.5 or newer and the associated platform toolchains.
2. Clone the repository and fetch packages:
   ```bash
   flutter pub get
   ```
3. Configure environment variables if required by your integrations by updating
   the `.env` file at the project root.
4. Launch the app:
   ```bash
   flutter run
   ```

Run `flutter test` to execute widget or unit tests located in the `test/`
directory.

## Customization Tips
- Update the color system and typography in `lib/theme.dart` to match branding.
- Seed demo content and loyalty scenarios via `lib/demo_data.dart`.
- Extend localization strings in `lib/app_localizations.dart` and regenerate
  translations as needed.

## Screenshots
Add your own mockups or device captures to the `assets/branding/` directory and
reference them here once available.

## License
Provide license details or usage terms here if you are distributing the kit
beyond internal teams.
# sardoba_cashback
