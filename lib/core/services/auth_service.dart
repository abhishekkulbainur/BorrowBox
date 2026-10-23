// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

// Project Imports
import 'package:lendnborrow/core/models/user_profile.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static final List<UserProfile> _demoUsers = [
    UserProfile(
      id: "user_abhishek",
      name: "Abhishek Kulbainur",
      email: "abhishek@borrowbox.local",
      avatarUrl: null,
      bio: "Sharing tools, electronics, and technical gear. Believer in circular community reuse.",
      location: "Bangalore, India",
      rating: 4.9,
      reviewCount: 14,
      completedLoans: 22,
      joinedDate: DateTime(2025, 2, 10),
      isVerified: true,
    ),
    UserProfile(
      id: "user_snehal",
      name: "Snehal Mascarenhas",
      email: "snehal@borrowbox.local",
      avatarUrl: null,
      bio: "Creative designer, book lover, and outdoor camper. Happy to lend and share useful gear!",
      location: "Bangalore, India",
      rating: 5.0,
      reviewCount: 9,
      completedLoans: 16,
      joinedDate: DateTime(2025, 3, 1),
      isVerified: true,
    ),
  ];

  // Default: unauthenticated in standard production flow
  UserProfile? _currentUser;
  bool _isAuthenticated = false;
  bool _isDevMode = true; // Enables quick test switcher for evaluation

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated && _currentUser != null;
  bool get isDevMode => _isDevMode;
  List<UserProfile> get demoUsers => List.unmodifiable(_demoUsers);

  void setDevMode(bool enabled) {
    _isDevMode = enabled;
    notifyListeners();
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cleanEmail = email.trim().toLowerCase();
    
    // Look up in existing registered/demo accounts or create authenticated session
    final matched = _demoUsers.firstWhere(
      (u) => u.email.toLowerCase() == cleanEmail,
      orElse: () => UserProfile(
        id: const Uuid().v4(),
        name: email.split('@')[0],
        email: cleanEmail,
        joinedDate: DateTime.now(),
      ),
    );
    _currentUser = matched;
    _isAuthenticated = true;
    notifyListeners();
    return true;
  }

  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String? location,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newUser = UserProfile(
      id: const Uuid().v4(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      location: location?.trim().isNotEmpty == true ? location!.trim() : "Local Community",
      joinedDate: DateTime.now(),
      isVerified: true,
    );
    _demoUsers.add(newUser);
    _currentUser = newUser;
    _isAuthenticated = true;
    notifyListeners();
    return true;
  }

  // Developer & Evaluation Mode Only: Quickly switch active profile
  void switchDemoUser(String userId) {
    final user = _demoUsers.firstWhere(
      (u) => u.id == userId,
      orElse: () => _demoUsers[0],
    );
    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  void signOut() {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? bio,
    String? location,
  }) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: name,
        bio: bio,
        location: location,
      );
      notifyListeners();
    }
  }
}

final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService();
});

final currentUserProvider = Provider<UserProfile?>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.currentUser;
});
