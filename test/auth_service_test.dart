import 'package:flutter_test/flutter_test.dart';
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

    test('Open registration allows non-institutional personal email without restrictions', () async {
      final success = await authService.registerWithEmail(
        name: 'Community Member',
        email: 'resident@gmail.com', // Public non-institutional email
        password: 'securepassword123',
        location: 'Oakridge Apartments',
      );

      expect(success, isTrue);
      expect(authService.currentUser?.email, 'resident@gmail.com');
      expect(authService.currentUser?.name, 'Community Member');
      expect(authService.currentUser?.location, 'Oakridge Apartments');
      expect(authService.isAuthenticated, isTrue);
    });

    test('Switch demo user changes active profile in developer mode', () {
      authService.switchDemoUser('user_snehal');
      expect(authService.currentUser?.id, 'user_snehal');
      expect(authService.currentUser?.name, 'Snehal Mascarenhas');

      authService.switchDemoUser('user_abhishek');
      expect(authService.currentUser?.id, 'user_abhishek');
      expect(authService.currentUser?.name, 'Abhishek Kulbainur');
    });

    test('Sign out updates state and clears active session', () {
      authService.switchDemoUser('user_abhishek');
      expect(authService.isAuthenticated, isTrue);

      authService.signOut();
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
    });

    test('Sign in restores authentication state', () async {
      authService.signOut();
      expect(authService.isAuthenticated, isFalse);

      await authService.signInWithEmailPassword('abhishek@borrowbox.local', 'password');
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.id, 'user_abhishek');
    });
  });
}
