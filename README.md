# BorrowBox — Share More. Own Less.

A minimal, privacy-focused, offline-first Flutter application for tracking items you lend and borrow. Record who borrowed what, manage returns, attach optional photos, and maintain a simple lending history — all without accounts, cloud synchronization, advertisements, or tracking.

## ✨ Features

- **Home Dashboard:** Quick overview of borrowed items, lent items, and lending history.
- **Item Management:** Add and edit items with notes and relevant details.
- **Return Tracking:** Mark items as returned and preserve their history.
- **Optional Photos:** Take photos or select them from the gallery. Photos are stored in the local database.
- **Local Database:** Keep personal lending records on your device.
- **Backup & Restore:** Export and import database backups through Files or Downloads.
- **Settings:** Manage application preferences.
- **Theme Support:** Choose Dark, Light, or System theme.
- **Offline-First:** Designed to work without an internet connection.

## 🎯 Why BorrowBox?

Many lending-tracker applications can feel outdated, cluttered, or unnecessarily restrictive. Some introduce advertisements, paywalls for basic features, or tracking mechanisms that users do not need.

BorrowBox aims to provide a simpler alternative:

- A modern, user-friendly interface.
- Essential lending and borrowing features without unnecessary complexity.
- No advertisements interrupting core workflows.
- No unnecessary telemetry or tracking.
- Private, locally stored records.
- A straightforward experience focused on lending management.

**Our philosophy:** Your lending records belong to you.

## 🔒 Privacy & Offline-First Guarantees

BorrowBox is designed around user privacy and resilient local data ownership.

- **Offline-First:** Core records are stored locally on your device in SQLite.
- **Optional Cloud Sync:** Powered by Firebase Authentication, Cloud Firestore, and Firebase Storage for real-time backup and multi-device access when connected.
- **No Advertisements or Third-Party Ad Trackers.**
- **User-Controlled Backups:** Export and import local SQLite backups through Android's Storage Access Framework.
- **Secure Release Builds:** Production APKs are signed with APK Signature Scheme v2 & v3, targeting Android 15 (API 35) with broad backward compatibility (Android 7.0+ / API 24).

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Mobile application framework |
| Dart | Primary programming language |
| Flutter Riverpod | State management |
| Google Firebase | Cloud backend & real-time synchronization |
| Firebase Authentication | Secure user sign-up and authentication |
| Cloud Firestore | NoSQL cloud database for items, requests, & events |
| Firebase Storage | Image and media asset storage |
| SQLite / sqflite | Local database and persistent offline cache |
| Kotlin | Native Android integration |
| Flutter MethodChannel | Communication between Flutter and native Android code |
| Android Storage Access Framework (SAF) | Database backup and restore |
| image_picker | Camera and gallery image selection |
| flutter_image_compress | Image compression |
| Flutter localization / ARB | Language and localization support |

## 🏗️ Architecture Overview

BorrowBox follows an offline-first architecture:

1. **Presentation Layer:** Flutter screens and user interface.
2. **State Management:** Riverpod manages application state.
3. **Application Logic:** Handles item management, lending records, returns, and history.
4. **Local Persistence:** SQLite stores personal lending records and associated local data.
5. **Native Android Integration:** Kotlin and Flutter MethodChannel support database export and restore through Android's Storage Access Framework.

All personal lending records are managed locally. The application does not depend on a cloud backend for its core functionality.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK compatible with the project
- Android Studio or Visual Studio Code
- Android SDK and an emulator or physical Android device

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/abhishekkulbainur/BorrowBox.git
   ```

2. Navigate to the project directory:

   ```bash
   cd BorrowBox
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run the application:

   ```bash
   flutter run
   ```

## 📱 Building Release APK

To generate a production-ready, signed release APK:

1. Configure keystore properties in `android/key.properties` (see `android/key.properties.example` for reference):
   ```properties
   storePassword=<YOUR_STORE_PASSWORD>
   keyPassword=<YOUR_KEY_PASSWORD>
   keyAlias=<YOUR_KEY_ALIAS>
   storeFile=<PATH_TO_KEYSTORE_FILE>
   ```

2. Build the release APK:
   ```bash
   flutter build apk --release
   ```

3. The generated release APK will be located at:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

> **Note on Device Installation:** If you previously had a debug build installed on your device (e.g. from `flutter run`), uninstall it before installing the signed release APK, as Android enforces cryptographic signature consistency for package updates.

## 📦 Backup & Restore

BorrowBox supports user-initiated database export and import.

- Export a backup to a location selected by the user.
- Keep a backup in Files or Downloads.
- Restore records from a previously exported backup.

**Important:** Keep backup files secure. Anyone with access to an unprotected backup may be able to access its contents.

## 🌍 Localization

BorrowBox uses ARB localization files with Flutter's localization tooling.

To contribute a translation:

1. Use `l10n/app_en.arb` as the source for translation keys and messages.
2. Create a language file, such as `l10n/app_de.arb` or `l10n/app_es.arb`.
3. Translate the message values while preserving the existing keys.
4. Run the application or localization generator to produce the required localization classes.
5. Add the locale to `supportedLocales` in `MaterialApp` if necessary.

Contributions for additional languages and accessibility improvements are welcome.

## 👥 Authors & Project Owners

**Abhishek Kulbainur**  
Developer & Project Owner

**Snehal Mascarenhas**  
Co-Developer & Project Owner

BorrowBox is developed collaboratively by Abhishek Kulbainur and Snehal Mascarenhas, with a shared focus on simplicity, privacy, and offline-first software.
<p align="center">

</p>
