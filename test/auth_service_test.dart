import 'package:flutter_test/flutter_test.dart';
import 'package:lendnborrow/core/models/user_profile.dart';
import 'package:lendnborrow/core/services/auth_service.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
      authService.signOut(); // Ensure clean unauthenticated initial state
    });

    test('Initial user is unauthenticated by default in standard flow', () {
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
    });

    test(
      'Open registration allows non-institutional personal email without restrictions',
      () async {
        final success = await authService.registerWithEmail(
          name: 'Community Member',
          email: 'resident@gmail.com',
          password: 'securepassword123',
          location: 'Oakridge Apartments',
        );

        expect(success, isTrue);
        expect(authService.currentUser?.email, 'resident@gmail.com');
        expect(authService.currentUser?.name, 'Community Member');
        expect(authService.currentUser?.location, 'Oakridge Apartments');
        expect(authService.currentUser?.isAdmin, isFalse);
        expect(authService.isAuthenticated, isTrue);
      },
    );

    test('Sign out updates state and clears active session', () async {
      await authService.registerWithEmail(
        name: 'Active Citizen',
        email: 'citizen@example.com',
        password: 'password123',
      );
      expect(authService.isAuthenticated, isTrue);

      authService.signOut();
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
    });

    test(
      'Sign in restores authentication state for registered users',
      () async {
        authService.signOut();
        expect(authService.isAuthenticated, isFalse);

        await authService.registerWithEmail(
          name: 'Registered Member',
          email: 'member@borrowbox.test',
          password: 'password123',
        );

        authService.signOut();
        expect(authService.isAuthenticated, isFalse);

        final success = await authService.signInWithEmailPassword(
          'member@borrowbox.test',
          'password123',
        );
        expect(success, isTrue);
        expect(authService.isAuthenticated, isTrue);
        expect(authService.currentUser?.email, 'member@borrowbox.test');
        expect(authService.currentUser?.name, 'Registered Member');
      },
    );

    test(
      'Sign in fails on wrong credentials and does NOT fake login',
      () async {
        authService.signOut();
        expect(authService.isAuthenticated, isFalse);

        final success = await authService.signInWithEmailPassword(
          'nonexistent@borrowbox.test',
          'wrongpassword',
        );
        expect(success, isFalse);
        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUser, isNull);
      },
    );

    test('Update profile changes local user information', () async {
      await authService.registerWithEmail(
        name: 'Abhishek Kulbainur',
        email: 'abhishek@borrowbox.test',
        password: 'password123',
      );

      await authService.updateProfile(
        name: 'Abhishek K. Updated',
        bio: 'Updated bio for testing',
        location: 'Indiranagar, Bangalore',
      );

      expect(authService.currentUser?.name, 'Abhishek K. Updated');
      expect(authService.currentUser?.bio, 'Updated bio for testing');
      expect(authService.currentUser?.location, 'Indiranagar, Bangalore');
    });

    test(
      'sendPasswordReset handles valid email format without exception',
      () async {
        expect(
          () => authService.sendPasswordReset('user@example.com'),
          returnsNormally,
        );
      },
    );

    test('Test-only helper setTestUser sets test user and cleans up', () {
      final testAdmin = UserProfile(
        id: 'user_admin_01',
        name: 'BorrowBox System Administrator',
        email: 'admin@borrowbox.org',
        isAdmin: true,
        joinedDate: DateTime(2025, 1, 1),
      );

      authService.setTestUser(testAdmin);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.isAdmin, isTrue);
      expect(authService.currentUser?.name, 'BorrowBox System Administrator');

      authService.setTestUser(null);
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
    });

    test('Ordinary registered users are NOT granted admin access', () async {
      await authService.registerWithEmail(
        name: 'Regular Citizen',
        email: 'citizen@example.com',
        password: 'password123',
      );

      expect(authService.currentUser?.isAdmin, isFalse);
    });
  });
}
