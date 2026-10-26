// Flutter Imports
import "package:flutter/material.dart";

// Package Imports
import "package:flutter_riverpod/flutter_riverpod.dart";

// Project Imports
import "package:lendnborrow/core/services/auth_service.dart";
import "package:lendnborrow/core/widgets/app_logo.dart";
import "package:lendnborrow/feature/admin/admin_dashboard_screen.dart";
import "package:lendnborrow/feature/settings/ex_import_setting.dart";
import "package:lendnborrow/feature/settings/language_setting.dart";
import "package:lendnborrow/feature/settings/theme_setting.dart";
import "package:lendnborrow/l10n/app_localizations.dart";

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String path = "/settings";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final auth = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.settings_screen_title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Preferences
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  "App Preferences",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Card(
                elevation: 0.5,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(60),
                  ),
                ),
                child: const Column(
                  children: [
                    LanguageSetting(),
                    Divider(height: 1),
                    ThemeSetting(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 2: Data & Privacy
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  localizations.export_import,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Card(
                elevation: 0.5,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(60),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: ExImportSetting(),
                ),
              ),
              const SizedBox(height: 24),

              // Section 3: Administrator Operations (Only shown if authenticated and server-authorized as admin)
              if (auth.isAuthenticated &&
                  auth.currentUser?.isAdmin == true) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                  child: Text(
                    "Administrator Operations",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Card(
                  elevation: 0.5,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withAlpha(60),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings,
                      color: Color(0xFF00E5FF),
                    ),
                    title: const Text("Admin Command Operations"),
                    subtitle: const Text(
                      "Open system console & moderation dashboard",
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pushNamed(AdminDashboardScreen.path);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Section 4: About BorrowBox
              Center(
                child: Column(
                  children: [
                    const AppLogo(size: 72, borderRadius: 14),
                    const SizedBox(height: 10),
                    Text(
                      "BorrowBox",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Share More. Own Less.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Created by Abhishek Kulbainur & Snehal Mascarenhas",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
