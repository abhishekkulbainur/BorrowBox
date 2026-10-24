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

## 🔒 Privacy & Offline Guarantees

BorrowBox is designed around privacy and local data ownership.

- **No accounts required.**
- **No data tracking or analytics.**
- **No advertisements.**
- **No telemetry.**
- **No Google Play Services or Firebase dependency.**
- **No internet permission or network dependency.**
- **Local data storage:** Records remain on the device.
- **User-controlled backups:** Data leaves the device only when you explicitly export a backup.
- **No hidden background jobs or remote configuration.**

The application is intended to function fully offline, without relying on cloud services.

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Mobile application framework |
| Dart | Primary programming language |
| Flutter Riverpod | State management |
| SQLite / sqflite | Local database and persistent records |
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
   git clone <YOUR_REPOSITORY_URL>
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

Replace `<YOUR_REPOSITORY_URL>` with the actual Git repository URL. If your repository uses a different directory name, navigate to that directory instead.

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

## 🤝 Contributing

Contributions are welcome, especially translations, accessibility improvements, bug fixes, and usability enhancements.

- **Issues:** Report bugs, suggest features, or help with existing issues.
- **Code:** Keep pull requests focused and follow the project's existing coding style.
- **Testing:** Run relevant checks and tests before submitting changes.
- **Documentation:** Help improve setup instructions and clarify application behavior.

Please discuss substantial changes before submitting a large pull request.

## 👥 Authors & Project Owners

**Abhishek Kulbainur**  
Developer & Project Owner

**Snehal Mascarenhas**  
Co-Developer & Project Owner

BorrowBox is developed collaboratively by Abhishek Kulbainur and Snehal Mascarenhas, with a shared focus on simplicity, privacy, and offline-first software.
<p align="center">

**BORROWBOX**  
*Share More. Own Less.*

Designed and developed by **Abhishek Kulbainur & Snehal Mascarenhas**

</p>
