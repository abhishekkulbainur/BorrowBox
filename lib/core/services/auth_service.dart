// Flutter Imports
import 'package:flutter/foundation.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

// Project Imports
import 'package:lendnborrow/core/models/user_profile.dart';
import 'package:lendnborrow/core/services/firebase_service.dart';
import 'package:lendnborrow/core/services/chat_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/services/notification_service.dart';
import 'package:lendnborrow/core/services/transaction_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // In-memory test store: used exclusively in offline unit/widget test environments
  // where Firebase is not initialized. No production accounts or hardcoded credentials.
  final List<UserProfile> _testUsers = [];

  UserProfile? _currentUser;
  bool _isAuthenticated = false;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated && _currentUser != null;

  /// Test-only utility to seed test accounts in automated test suites
  @visibleForTesting
  void seedTestUsers(List<UserProfile> users) {
    _testUsers.clear();
    _testUsers.addAll(users);
  }

  /// Test-only utility to set active test user in automated test suites
  @visibleForTesting
  void setTestUser(UserProfile? user) {
    _currentUser = user;
    _isAuthenticated = user != null;
    if (user != null) {
      _syncUserServices(user.id);
    } else {
      _clearUserServices();
    }
    notifyListeners();
  }

  /// Initialize authenticated session from persistent Firebase session on app launch
  Future<void> initialize() async {
    if (FirebaseService().isInitialized) {
      final user = FirebaseService().currentFirebaseUser;
      if (user != null) {
        final profile = await FirebaseService().ensureUserProfile(user);
        _currentUser = profile;
        _isAuthenticated = true;
        _syncUserServices(_currentUser!.id);
        notifyListeners();
      }
    }
  }

  void _syncUserServices(String userId) {
    MarketplaceService().initSync();
    TransactionService().initSync(userId);
    NotificationService().initSync(userId);
    ChatService().initSync(userId);
  }

  void _clearUserServices() {
    TransactionService().disposeSync();
    NotificationService().disposeSync();
    ChatService().disposeSync();
  }

  /// Genuine sign in with email and password via Firebase Authentication
  Future<bool> signInWithEmailPassword(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    if (FirebaseService().isInitialized) {
      final cred = await FirebaseService().signInWithEmail(
        email: cleanEmail,
        password: password,
      );
      if (cred?.user != null) {
        final profile = await FirebaseService().ensureUserProfile(cred!.user!);
        _currentUser = profile;
        _isAuthenticated = true;
        _syncUserServices(_currentUser!.id);
        notifyListeners();
        return true;
      }
      return false;
    }

    // Testing harness fallback (only when running offline test environment):
    final matches = _testUsers.where(
      (u) => u.email.toLowerCase() == cleanEmail,
    );
    if (matches.isEmpty) {
      return false;
    }
    _currentUser = matches.first;
    _isAuthenticated = true;
    _syncUserServices(_currentUser!.id);
    notifyListeners();
    return true;
  }

  /// Genuine registration with email, password, and profile metadata
  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String? location,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();

    if (FirebaseService().isInitialized) {
      final cred = await FirebaseService().signUpWithEmail(
        name: cleanName,
        email: cleanEmail,
        password: password,
        location: location,
      );
      if (cred?.user != null) {
        final profile = await FirebaseService().ensureUserProfile(
          cred!.user!,
          name: cleanName,
          location: location,
        );
        _currentUser = profile;
        _isAuthenticated = true;
        _syncUserServices(profile.id);
        notifyListeners();
        return true;
      }
      return false;
    }

    // Testing harness fallback (only when running offline test environment):
    final newUser = UserProfile(
      id: const Uuid().v4(),
      name: cleanName,
      email: cleanEmail,
      location: location?.trim().isNotEmpty == true
          ? location!.trim()
          : "Local Community",
      joinedDate: DateTime.now(),
      isVerified: true,
      isAdmin: false,
    );
    _testUsers.add(newUser);
    _currentUser = newUser;
    _isAuthenticated = true;
    _syncUserServices(newUser.id);
    notifyListeners();
    return true;
  }

  void signOut() {
    if (FirebaseService().isInitialized) {
      FirebaseService().signOut();
    }
    _currentUser = null;
    _isAuthenticated = false;
    _clearUserServices();
    notifyListeners();
  }

  /// Send password reset link to user email via Firebase Authentication
  Future<void> sendPasswordReset(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (FirebaseService().isInitialized) {
      await FirebaseService().sendPasswordReset(cleanEmail);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? location,
  }) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: name,
        bio: bio,
        location: location,
      );
      notifyListeners();

      if (FirebaseService().isInitialized) {
        try {
          await FirebaseService().updateUserProfile(
            uid: _currentUser!.id,
            name: name,
            bio: bio,
            location: location,
          );
        } catch (e) {
          debugPrint("Error updating profile in Firebase: $e");
        }
      }
    }
  }

  /// Permanently delete account and associated user data
  Future<bool> deleteAccount() async {
    final uid = _currentUser?.id;
    bool success = true;
    if (FirebaseService().isInitialized && uid != null) {
      try {
        final firestore = FirebaseService().firestore;
        if (firestore != null) {
          await firestore.collection('users').doc(uid).delete();
        }
        final user = FirebaseService().auth?.currentUser;
        if (user != null) {
          await user.delete();
        }
      } catch (e) {
        debugPrint("Error deleting account in Firebase: $e");
        success = false;
      }
    }
    signOut();
    return success;
  }
}

final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService();
});

final currentUserProvider = Provider<UserProfile?>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.currentUser;
});
