// Flutter Imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package Imports
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project Imports
import 'package:lendnborrow/core/cfg/themes.dart';
import 'package:lendnborrow/core/provider/settings_service_provider.dart';
import 'package:lendnborrow/feature/activity/activity_screen.dart';
import 'package:lendnborrow/feature/admin/admin_dashboard_screen.dart';
import 'package:lendnborrow/feature/auth/auth_screen.dart';
import 'package:lendnborrow/feature/borrowed/borrowed_screen.dart';
import 'package:lendnborrow/feature/communities/communities_screen.dart';
import 'package:lendnborrow/feature/explore/explore_screen.dart';
import 'package:lendnborrow/feature/history/history_screen.dart';
import 'package:lendnborrow/feature/home/home_screen.dart';
import 'package:lendnborrow/feature/lent/lent_screen.dart';
import 'package:lendnborrow/feature/notifications/notifications_screen.dart';
import 'package:lendnborrow/feature/profile/profile_screen.dart';
import 'package:lendnborrow/feature/settings/settings_screen.dart';
import 'package:lendnborrow/l10n/app_localizations.dart';
import 'package:lendnborrow/main_screen.dart';

import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/firebase_service.dart';

import 'package:lendnborrow/feature/chat/conversations_screen.dart';
import 'package:lendnborrow/feature/wishlist/wishlist_screen.dart';
import 'package:lendnborrow/feature/support/support_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );

  // Initialize Firebase (safely handles local fallback if credentials aren't configured yet)
  await FirebaseService().initialize();
  await AuthService().initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var settingsAsync = ref.watch(settingsServiceNotifierProvider);

    return settingsAsync.when(
      data: (settings) => MaterialApp(
        title: "BorrowBox : Share More. Own Less.",
        themeMode: settings.themeMode,
        theme: light,
        darkTheme: dark,
        locale: settings.locale,
        supportedLocales: const [Locale("en", ""), Locale("de", "")],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routes: {
          HomeScreen.path: (context) => const MainScreen(child: HomeScreen()),
          ExploreScreen.path: (context) =>
              const MainScreen(child: ExploreScreen()),
          ActivityScreen.path: (context) =>
              const MainScreen(child: ActivityScreen()),
          CommunitiesScreen.path: (context) =>
              const MainScreen(child: CommunitiesScreen()),
          ProfileScreen.path: (context) =>
              const MainScreen(child: ProfileScreen()),
          BorrowedScreen.path: (context) => const BorrowedScreen(),
          LentScreen.path: (context) => const LentScreen(),
          HistoryScreen.path: (context) => const HistoryScreen(),
          SettingsScreen.path: (context) => const SettingsScreen(),
          NotificationsScreen.path: (context) => const NotificationsScreen(),
          AuthScreen.path: (context) => const AuthScreen(),
          AdminDashboardScreen.path: (context) => const AdminDashboardScreen(),
          ConversationsScreen.path: (context) => const ConversationsScreen(),
          WishlistScreen.path: (context) => const WishlistScreen(),
          SupportScreen.path: (context) => const SupportScreen(),
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => const MainScreen(child: HomeScreen()),
        ),
      ),
      loading: () => Center(child: const CircularProgressIndicator()),
      error: (e, st) => Center(child: Text("Error: $e")),
    );
  }
}
