# ProDine — Mobile App

Professional, production-ready Flutter mobile application for restaurants and food providers.

## Overview

ProDine is a cross-platform Flutter app that helps vendors manage menus, orders, and deliveries. This repository contains the full Flutter source code, build scripts, and a downloadable APK for quick testing.

## Quick Links

- Source: https://github.com/Mohittej12/ProDine-Mobile-App
- APK (raw): https://raw.githubusercontent.com/Mohittej12/ProDine-Mobile-App/main/app-release.apk
- Demo / Download page: (enable GitHub Pages -> `docs/`) once enabled: https://mohittej12.github.io/ProDine-Mobile-App/

## Key Features

- Menu management (CRUD for items)
- Order processing and status tracking
- Vendor authentication and role-based access
- Deep links and platform integrations (Android, iOS)

## Getting Started (Developer)

Prerequisites:

- Flutter SDK (stable) — see https://docs.flutter.dev/get-started/install
- Android SDK / Xcode (macOS) for platform builds

Clone the repo and get dependencies:

```powershell
git clone https://github.com/Mohittej12/ProDine-Mobile-App.git
cd ProDine-Mobile-App
flutter pub get
```

Run on an Android device/emulator:

```powershell
flutter run -d android
```

Build a release APK:

```powershell
flutter build apk --release
```

The repository already includes a release APK at `app-release.apk` for quick testing.

## Hosting the APK & Download Page

I added a simple download page at `docs/index.html` that links to the APK and contains a QR code for easy distribution. To publish it via GitHub Pages:

1. Go to **Settings → Pages** in your repository.
2. Choose branch: `main` and folder: `/docs`.
3. Leave **Custom domain** blank (unless you have one) and save.

The site will publish at `https://mohittej12.github.io/ProDine-Mobile-App/`. The QR code on the page points to the raw APK URL so users can download the APK directly.

Note: The APK is ~65 MB — GitHub warns about large files. For production distribution, prefer GitHub Releases, Google Play, or an external CDN.

## Contributing

- Use feature branches and open pull requests to `main`.
- Keep commits small and focused; write clear commit messages.

## License & Contact

Specify your license here (e.g., MIT) and contact information for contributors or users.

---

If you want, I can: enable GitHub Pages via the API (requires a token), move the APK to a Release, or set up Git LFS for large binaries. Tell me which you prefer.
