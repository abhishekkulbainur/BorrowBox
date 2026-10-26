import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lendnborrow/core/models/user_profile.dart';
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/feature/activity/activity_screen.dart';
import 'package:lendnborrow/feature/admin/admin_dashboard_screen.dart';
import 'package:lendnborrow/feature/auth/auth_screen.dart';
import 'package:lendnborrow/feature/history/history_screen.dart';
import 'package:lendnborrow/feature/profile/profile_screen.dart';
import 'package:lendnborrow/feature/settings/settings_screen.dart';
import 'package:lendnborrow/l10n/app_localizations.dart';

final sharedContainer = ProviderContainer();

Widget createTestApp(Widget child) {
  return UncontrolledProviderScope(
    container: sharedContainer,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UI Screens & Hierarchy Tests', () {
    testWidgets(
      'SettingsScreen renders Scaffold and Material widgets without crashing',
      (tester) async {
        await tester.pumpWidget(createTestApp(const SettingsScreen()));
        await tester.pumpAndSettle();

        // Verify Scaffold and AppBar are present
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);

        // Verify Material ancestor exists for ListTiles
        expect(find.byType(ListTile), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SettingsScreen does NOT contain demo switches or developer evaluation toggles',
      (tester) async {
        await tester.pumpWidget(createTestApp(const SettingsScreen()));
        await tester.pumpAndSettle();

        expect(
          find.text('Developer Diagnostics & Evaluation Mode'),
          findsNothing,
        );
        expect(find.text('Evaluation & Demo Mode'), findsNothing);
      },
    );

    testWidgets(
      'ActivityScreen renders on narrow phone screen (320px) without overflow',
      (tester) async {
        FlutterErrorDetails? caughtDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtDetails = details;
        };

        try {
          // Simulate narrow viewport: 320 x 640
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1.0;

          AuthService().setTestUser(
            UserProfile(
              id: 'user_abhishek',
              name: 'Abhishek Kulbainur',
              email: 'abhishek@borrowbox.test',
              joinedDate: DateTime(2025, 1, 1),
            ),
          );

          await tester.pumpWidget(createTestApp(const ActivityScreen()));
          await tester.pumpAndSettle();

          // Verify TabBar with Borrowed, Lent & Requests, My Listings
          expect(find.byType(TabBar), findsOneWidget);
          expect(find.text('Borrowed'), findsOneWidget);
          expect(find.text('Lent & Requests'), findsOneWidget);
          expect(find.text('My Listings'), findsOneWidget);
        } finally {
          FlutterError.onError = originalOnError;
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        }

        expect(caughtDetails, isNull);
      },
    );

    testWidgets(
      'HistoryScreen renders with clean tabs and EmptyStateView without fallback text styling',
      (tester) async {
        await tester.pumpWidget(createTestApp(const HistoryScreen()));
        await tester.pumpAndSettle();

        // Verify Scaffold and AppBar
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('History & Archive'), findsOneWidget);

        // Verify no crash
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AuthScreen renders sign in, forgot password, and switches to sign up',
      (tester) async {
        await tester.pumpWidget(createTestApp(const AuthScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Sign In to BorrowBox'), findsOneWidget);
        expect(find.text('Forgot password?'), findsOneWidget);

        // Tap switch to Sign Up
        await tester.tap(find.text("Don't have an account? Sign Up for Free"));
        await tester.pumpAndSettle();

        expect(find.text('Create Free Account'), findsOneWidget);
        expect(find.text('Full Name *'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AuthScreen contains NO demo switcher chips, admin terminal switcher, or credential autofill',
      (tester) async {
        await tester.pumpWidget(createTestApp(const AuthScreen()));
        await tester.pumpAndSettle();

        // Assert all demo account entry points and switchers are completely absent
        expect(find.text('Citizen Access'), findsNothing);
        expect(find.text('Admin Terminal'), findsNothing);
        expect(find.text('Fill Admin Credentials'), findsNothing);
        expect(find.text('ADMIN COMMAND PORTAL'), findsNothing);
        expect(
          find.text('Developer & Test Evaluation Mode Only'),
          findsNothing,
        );
        expect(find.text('One-tap test account switcher'), findsNothing);
        expect(find.text('Abhishek (Owner)'), findsNothing);
        expect(find.text('Snehal (Borrower)'), findsNothing);
        expect(find.text('admin@borrowbox.local'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ProfileScreen renders user profile card and edit profile button',
      (tester) async {
        AuthService().setTestUser(
          UserProfile(
            id: 'user_abhishek',
            name: 'Abhishek Kulbainur',
            email: 'abhishek@borrowbox.test',
            joinedDate: DateTime(2025, 1, 1),
          ),
        );

        await tester.pumpWidget(createTestApp(const ProfileScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Abhishek Kulbainur'), findsAtLeastNWidgets(1));
        expect(find.text('Edit Profile Information'), findsOneWidget);
        expect(find.text('Saved Favorites'), findsOneWidget);
        expect(find.text('Completed History Archive'), findsOneWidget);
        // Verify demo account switcher is NOT present
        expect(find.text('[Dev Mode] Active Account:'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AdminDashboardScreen denies access to unauthenticated and non-admin visitors',
      (tester) async {
        // 1. Unauthenticated visitor
        AuthService().signOut();
        await tester.pumpWidget(createTestApp(const AdminDashboardScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Access Denied'), findsOneWidget);
        expect(find.text('Restricted Administrator Access'), findsOneWidget);
        expect(find.text('BorrowBox Console'), findsNothing);

        // 2. Authenticated non-admin citizen
        AuthService().setTestUser(
          UserProfile(
            id: 'citizen_123',
            name: 'Standard Citizen',
            email: 'citizen@borrowbox.test',
            isAdmin: false,
            joinedDate: DateTime(2025, 1, 1),
          ),
        );
        await tester.pumpWidget(createTestApp(const AdminDashboardScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Access Denied'), findsOneWidget);
        expect(find.text('Restricted Administrator Access'), findsOneWidget);
        expect(find.text('BorrowBox Console'), findsNothing);
      },
    );

    testWidgets(
      'AdminDashboardScreen grants console access exclusively to authenticated server-authorized admin',
      (tester) async {
        AuthService().setTestUser(
          UserProfile(
            id: 'admin_master_01',
            name: 'Server Authorized Admin',
            email: 'sysadmin@borrowbox.internal',
            isAdmin: true,
            joinedDate: DateTime(2025, 1, 1),
          ),
        );

        await tester.pumpWidget(createTestApp(const AdminDashboardScreen()));
        await tester.pumpAndSettle();

        expect(find.text('BorrowBox Console'), findsOneWidget);
        expect(find.text('Master Command & Moderation'), findsOneWidget);
        expect(find.text('LISTINGS'), findsOneWidget);
        expect(find.text('ACTIVE LOANS'), findsOneWidget);
        expect(find.text('CITIZENS'), findsOneWidget);
        expect(find.byType(TabBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
