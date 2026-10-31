// Flutter Imports
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

// Package Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/legacy.dart';

// Project Imports
import 'package:lendnborrow/core/models/app_notification.dart';
import 'package:lendnborrow/core/models/borrow_request.dart';
import 'package:lendnborrow/core/models/listing_image.dart';
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/models/review.dart';
import 'package:lendnborrow/core/models/user_profile.dart';
import 'package:lendnborrow/firebase_options.dart';

final firebaseServiceProvider = ChangeNotifierProvider<FirebaseService>((ref) {
  return FirebaseService();
});

class FirebaseService extends ChangeNotifier {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  FirebaseAuth? get auth => _isInitialized ? FirebaseAuth.instance : null;
  FirebaseFirestore? get firestore =>
      _isInitialized ? FirebaseFirestore.instance : null;
  FirebaseStorage? get storage =>
      _isInitialized ? FirebaseStorage.instance : null;

  /// Initialize Firebase with options
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      developer.log(
        "Firebase initialized successfully.",
        name: "FirebaseService",
      );
      notifyListeners();
      return true;
    } catch (e) {
      developer.log(
        "Firebase initialization deferred: $e\n(Running in local/offline mode until valid credentials are provided)",
        name: "FirebaseService",
      );
      _isInitialized = false;
      return false;
    }
  }

  // ===========================================================================
  // AUTHENTICATION
  // ===========================================================================

  User? get currentFirebaseUser => _isInitialized ? auth?.currentUser : null;

  Stream<User?> get authStateChanges =>
      _isInitialized ? auth!.authStateChanges() : const Stream.empty();

  /// Sign Up with Email & Password in Firebase Auth + create Firestore profile doc
  Future<UserCredential?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? location,
  }) async {
    if (!_isInitialized) return null;

    UserCredential? credential;
    try {
      credential = await auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // If email is already in use, check if user is completing a previously interrupted registration
      if (e.code == 'email-already-in-use') {
        try {
          credential = await auth!.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
        } catch (_) {
          // Password did not match; rethrow original email-already-in-use error
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    final user = credential.user;
    if (user != null) {
      try {
        await user.updateDisplayName(name.trim());
      } catch (e) {
        developer.log("DisplayName update error: $e", name: "FirebaseService");
      }

      // Ensure profile document exists in Firestore
      await ensureUserProfile(
        user,
        name: name.trim(),
        location: location?.trim(),
      );
    }

    notifyListeners();
    return credential;
  }

  /// Sign In with Email & Password in Firebase Auth
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) return null;

    final credential = await auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    notifyListeners();
    return credential;
  }

  /// Sign Out
  Future<void> signOut() async {
    if (!_isInitialized) return;
    await auth!.signOut();
    notifyListeners();
  }

  /// Send Password Reset Email via Firebase Auth
  Future<void> sendPasswordReset(String email) async {
    if (!_isInitialized) return;
    await auth!.sendPasswordResetEmail(email: email.trim());
  }

  /// Update User Profile document in Firestore
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? bio,
    String? location,
  }) async {
    if (!_isInitialized) return;

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) updates['name'] = name.trim();
    if (bio != null) updates['bio'] = bio.trim();
    if (location != null) updates['location'] = location.trim();

    await firestore!
        .collection('users')
        .doc(uid)
        .set(updates, SetOptions(merge: true));
    notifyListeners();
  }

  /// Fetch User Profile from Firestore
  Future<UserProfile?> getUserProfile(String uid) async {
    if (!_isInitialized) return null;

    final doc = await firestore!.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    return UserProfile(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'],
      bio: data['bio'] ?? '',
      location: data['location'] ?? 'Local Community',
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      completedLoans: (data['completedLoans'] as num?)?.toInt() ?? 0,
      joinedDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? true,
      isAdmin: data['isAdmin'] as bool? ?? false,
    );
  }

  /// Self-healing profile hydration: Ensures users/{uid} document exists in Firestore
  Future<UserProfile> ensureUserProfile(
    User user, {
    String? name,
    String? location,
  }) async {
    final docRef = firestore!.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return UserProfile(
        id: doc.id,
        name:
            data['name'] ?? user.displayName ?? user.email?.split('@')[0] ?? '',
        email: data['email'] ?? user.email ?? '',
        avatarUrl: data['avatarUrl'],
        bio: data['bio'] ?? '',
        location: data['location'] ?? 'Local Community',
        rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
        reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
        completedLoans: (data['completedLoans'] as num?)?.toInt() ?? 0,
        joinedDate:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isVerified: data['isVerified'] ?? true,
        isAdmin: data['isAdmin'] as bool? ?? false,
      );
    }

    final cleanName = name?.trim().isNotEmpty == true
        ? name!.trim()
        : (user.displayName ?? user.email?.split('@')[0] ?? 'Community Member');
    final cleanLoc = location?.trim().isNotEmpty == true
        ? location!.trim()
        : 'Local Community';

    // Server-side authorization standard: New users default to normal citizen privileges.
    // Administrative rights must be explicitly assigned on server/database records.
    const bool isUserAdmin = false;

    final profileData = {
      'id': user.uid,
      'name': cleanName,
      'email': user.email ?? '',
      'avatarUrl': null,
      'bio': '',
      'location': cleanLoc,
      'rating': 5.0,
      'reviewCount': 0,
      'completedLoans': 0,
      'isVerified': true,
      'isAdmin': isUserAdmin,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(profileData, SetOptions(merge: true));

    return UserProfile(
      id: user.uid,
      name: cleanName,
      email: user.email ?? '',
      location: cleanLoc,
      joinedDate: DateTime.now(),
      isVerified: true,
      isAdmin: isUserAdmin,
    );
  }

  // ===========================================================================
  // FIRESTORE: ITEMS & LISTINGS
  // ===========================================================================

  /// Stream of active marketplace items from Firestore
  Stream<List<MarketplaceItem>> streamItems() {
    if (!_isInitialized) return const Stream.empty();

    return firestore!
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final d = doc.data();

            final rawImagesMeta = d['imagesMeta'];
            List<ListingImage>? parsedImagesMeta;
            if (rawImagesMeta is List) {
              parsedImagesMeta = rawImagesMeta
                  .asMap()
                  .entries
                  .map((e) => ListingImage.fromMap(
                        Map<String, dynamic>.from(e.value as Map),
                        fallbackOrder: e.key,
                        fallbackCover: e.key == 0,
                      ))
                  .toList();
            }

            final List<String> parsedUrls = List<String>.from(
              d['imageUrls'] ?? parsedImagesMeta?.map((img) => img.secureUrl) ?? [],
            );

            return MarketplaceItem(
              id: doc.id,
              ownerId: d['ownerId'] ?? '',
              ownerName: d['ownerName'] ?? 'Community Member',
              ownerRating: (d['ownerRating'] as num?)?.toDouble() ?? 5.0,
              title: d['title'] ?? '',
              description: d['description'] ?? '',
              category: ItemCategory.values.firstWhere(
                (c) => c.name == d['category'],
                orElse: () => ItemCategory.other,
              ),
              condition: ItemCondition.values.firstWhere(
                (c) => c.name == d['condition'],
                orElse: () => ItemCondition.good,
              ),
              pickupLocation: d['pickupLocation'] ?? '',
              maxDurationDays: (d['maxDurationDays'] as num?)?.toInt() ?? 7,
              depositAmount: (d['depositAmount'] as num?)?.toDouble(),
              availability: ItemAvailability.values.firstWhere(
                (a) => a.name == d['availability'],
                orElse: () => ItemAvailability.available,
              ),
              imageUrls: parsedUrls,
              imagesMeta: parsedImagesMeta,
              terms: d['terms'],
              createdAt:
                  (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              communityName: d['communityName'],
              favoriteCount: (d['favoriteCount'] as num?)?.toInt() ?? 0,
            );
          }).toList();
        });
  }

  /// Create a new item listing in Firestore
  Future<String?> createItem(MarketplaceItem item) async {
    if (!_isInitialized) return null;

    final docRef = await firestore!.collection('items').add({
      'ownerId': item.ownerId,
      'ownerName': item.ownerName,
      'ownerRating': item.ownerRating,
      'title': item.title,
      'description': item.description,
      'category': item.category.name,
      'condition': item.condition.name,
      'pickupLocation': item.pickupLocation,
      'maxDurationDays': item.maxDurationDays,
      'depositAmount': item.depositAmount,
      'availability': item.availability.name,
      'imageUrls': item.imageUrls,
      if (item.imagesMeta != null)
        'imagesMeta': item.imagesMeta!.map((img) => img.toMap()).toList(),
      'terms': item.terms,
      'communityName': item.communityName,
      'favoriteCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Delete an item listing in Firestore
  Future<void> deleteItem(String itemId) async {
    if (!_isInitialized) return;
    await firestore!.collection('items').doc(itemId).delete();
  }

  /// Update an item listing in Firestore
  Future<void> updateItemListing(MarketplaceItem item) async {
    if (!_isInitialized) return;
    await firestore!.collection('items').doc(item.id).update({
      'title': item.title,
      'description': item.description,
      'category': item.category.name,
      'condition': item.condition.name,
      'pickupLocation': item.pickupLocation,
      'maxDurationDays': item.maxDurationDays,
      'depositAmount': item.depositAmount,
      'availability': item.availability.name,
      'imageUrls': item.imageUrls,
      if (item.imagesMeta != null)
        'imagesMeta': item.imagesMeta!.map((img) => img.toMap()).toList(),
      'terms': item.terms,
      'isActive': item.isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===========================================================================
  // FIRESTORE: BORROW TRANSACTIONS & HANDOVERS
  // ===========================================================================

  /// Stream of user's active/historical borrow requests
  Stream<List<BorrowRequest>> streamBorrowRequests(String userId) {
    if (!_isInitialized || userId.isEmpty) return const Stream.empty();

    return firestore!
        .collection('borrow_requests')
        .where(
          Filter.or(
            Filter('borrowerId', isEqualTo: userId),
            Filter('ownerId', isEqualTo: userId),
          ),
        )
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final d = doc.data();
            return BorrowRequest(
              id: doc.id,
              listingId: d['listingId'] ?? '',
              itemTitle: d['itemTitle'] ?? '',
              borrowerId: d['borrowerId'] ?? '',
              borrowerName: d['borrowerName'] ?? 'Community Borrower',
              ownerId: d['ownerId'] ?? '',
              ownerName: d['ownerName'] ?? 'Community Owner',
              requestDate:
                  (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              startDate:
                  (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              endDate:
                  (d['endDate'] as Timestamp?)?.toDate() ??
                  DateTime.now().add(const Duration(days: 3)),
              status: RequestStatus.values.firstWhere(
                (s) => s.name == d['status'],
                orElse: () => RequestStatus.pending,
              ),
              message: d['message'],
              handoverQrToken: d['handoverQrToken'],
              returnQrToken: d['returnQrToken'],
              notes: d['notes'],
              depositAmount: (d['depositAmount'] as num?)?.toDouble(),
            );
          }).toList();
        });
  }

  /// Create a new borrow request
  Future<String?> createBorrowRequest(BorrowRequest req) async {
    if (!_isInitialized) return null;

    final docRef = await firestore!.collection('borrow_requests').add({
      'listingId': req.listingId,
      'itemTitle': req.itemTitle,
      'borrowerId': req.borrowerId,
      'borrowerName': req.borrowerName,
      'ownerId': req.ownerId,
      'ownerName': req.ownerName,
      'startDate': Timestamp.fromDate(req.startDate),
      'endDate': Timestamp.fromDate(req.endDate),
      'status': req.status.name,
      'message': req.message,
      'handoverQrToken': req.handoverQrToken,
      'returnQrToken': req.returnQrToken,
      'notes': req.notes,
      'depositAmount': req.depositAmount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Notify owner
    await firestore!.collection('notifications').add({
      'userId': req.ownerId,
      'title': 'New Borrow Request',
      'message': '${req.borrowerName} requested to borrow "${req.itemTitle}".',
      'type': 'borrowRequest',
      'isRead': false,
      'referenceId': docRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Concurrency-Safe: Approve request (ensures item is not already reserved/borrowed)
  Future<void> approveRequest(String requestId, String handoverToken) async {
    if (!_isInitialized) return;

    final reqRef = firestore!.collection('borrow_requests').doc(requestId);

    await firestore!.runTransaction((transaction) async {
      final reqSnapshot = await transaction.get(reqRef);
      if (!reqSnapshot.exists) {
        throw StateError("Borrow request no longer exists.");
      }

      final reqData = reqSnapshot.data()!;
      final currentStatus = reqData['status'];
      if (currentStatus != RequestStatus.pending.name) {
        throw StateError("Request is not pending (status: $currentStatus).");
      }

      final listingId = reqData['listingId'] as String?;
      final borrowerId = reqData['borrowerId'] as String?;

      if (listingId != null && listingId.isNotEmpty) {
        final itemRef = firestore!.collection('items').doc(listingId);
        final itemSnapshot = await transaction.get(itemRef);
        if (itemSnapshot.exists) {
          final itemData = itemSnapshot.data()!;
          final availability = itemData['availability'];
          if (availability != ItemAvailability.available.name) {
            throw StateError(
              "Item is currently $availability and cannot be reserved for another borrower.",
            );
          }
          transaction.update(itemRef, {
            'availability': ItemAvailability.reserved.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      transaction.update(reqRef, {
        'status': RequestStatus.handoverPending.name,
        'handoverQrToken': handoverToken,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (borrowerId != null) {
        final notifRef = firestore!.collection('notifications').doc();
        transaction.set(notifRef, {
          'userId': borrowerId,
          'title': 'Borrow Request Approved',
          'message':
              'Your request was approved! Coordinate physical handover with the owner.',
          'type': 'requestApproved',
          'isRead': false,
          'referenceId': requestId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Reject request
  Future<void> rejectRequest(String requestId, {String? reason}) async {
    if (!_isInitialized) return;

    final reqRef = firestore!.collection('borrow_requests').doc(requestId);
    final reqSnapshot = await reqRef.get();
    if (!reqSnapshot.exists) return;

    final data = reqSnapshot.data()!;
    final borrowerId = data['borrowerId'];
    final itemTitle = data['itemTitle'] ?? 'item';

    final batch = firestore!.batch();
    batch.update(reqRef, {
      'status': RequestStatus.rejected.name,
      'notes': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (borrowerId != null) {
      final notifRef = firestore!.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': borrowerId,
        'title': 'Borrow Request Declined',
        'message': 'Your request for "$itemTitle" was declined by the owner.',
        'type': 'requestRejected',
        'isRead': false,
        'referenceId': requestId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Initiate return (generates secure return token)
  Future<void> initiateReturn(String requestId, String returnToken) async {
    if (!_isInitialized) return;

    final reqRef = firestore!.collection('borrow_requests').doc(requestId);
    final reqSnapshot = await reqRef.get();
    if (!reqSnapshot.exists) return;

    final data = reqSnapshot.data()!;
    final ownerId = data['ownerId'];
    final itemTitle = data['itemTitle'] ?? 'item';

    final batch = firestore!.batch();
    batch.update(reqRef, {
      'status': RequestStatus.returnPending.name,
      'returnQrToken': returnToken,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (ownerId != null) {
      final notifRef = firestore!.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': ownerId,
        'title': 'Item Return Initiated',
        'message':
            'Borrower has initiated the return for "$itemTitle". Scan the QR to verify return.',
        'type': 'returnInitiated',
        'isRead': false,
        'referenceId': requestId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Confirm physical handover via QR token scan
  Future<bool> confirmHandover(
    String requestId,
    String token,
    String scannerId,
  ) async {
    if (!_isInitialized) return false;

    final reqRef = firestore!.collection('borrow_requests').doc(requestId);
    final doc = await reqRef.get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    if (data['handoverQrToken'] != token) return false;

    final batch = firestore!.batch();

    batch.update(reqRef, {
      'status': RequestStatus.active.name,
      'handoverQrToken': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final listingId = data['listingId'];
    if (listingId != null) {
      batch.update(firestore!.collection('items').doc(listingId), {
        'availability': ItemAvailability.borrowed.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return true;
  }

  /// Confirm return of borrowed item
  Future<bool> confirmReturn(
    String requestId,
    String token,
    String ownerId,
  ) async {
    if (!_isInitialized) return false;

    final reqRef = firestore!.collection('borrow_requests').doc(requestId);
    final doc = await reqRef.get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    if (data['ownerId'] != ownerId) return false;

    final batch = firestore!.batch();

    batch.update(reqRef, {
      'status': RequestStatus.returned.name,
      'returnQrToken': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final listingId = data['listingId'];
    if (listingId != null) {
      batch.update(firestore!.collection('items').doc(listingId), {
        'availability': ItemAvailability.available.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Increment completed loans on profiles
    final borrowerId = data['borrowerId'];
    if (borrowerId != null) {
      batch.update(firestore!.collection('users').doc(borrowerId), {
        'completedLoans': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.update(firestore!.collection('users').doc(ownerId), {
      'completedLoans': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return true;
  }

  /// Cancel a pending or approved borrow request
  Future<void> cancelRequest(String requestId, String listingId) async {
    if (!_isInitialized) return;

    final batch = firestore!.batch();
    batch.update(firestore!.collection('borrow_requests').doc(requestId), {
      'status': RequestStatus.cancelled.name,
      'handoverQrToken': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (listingId.isNotEmpty) {
      batch.update(firestore!.collection('items').doc(listingId), {
        'availability': ItemAvailability.available.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ===========================================================================
  // FIRESTORE: REVIEWS & REPUTATION
  // ===========================================================================

  /// Create a new peer review and update user's reputation score
  Future<void> createReview({
    required String transactionId,
    required String reviewerId,
    required String reviewerName,
    String? reviewerAvatarUrl,
    required String targetUserId,
    required double rating,
    required String comment,
    required String itemTitle,
  }) async {
    if (!_isInitialized) return;

    final reviewRef = firestore!.collection('reviews').doc();
    final batch = firestore!.batch();

    batch.set(reviewRef, {
      'transactionId': transactionId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerAvatarUrl': reviewerAvatarUrl,
      'targetUserId': targetUserId,
      'rating': rating,
      'comment': comment,
      'itemTitle': itemTitle,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final userRef = firestore!.collection('users').doc(targetUserId);
    final userDoc = await userRef.get();
    if (userDoc.exists && userDoc.data() != null) {
      final currentRating =
          (userDoc.data()!['rating'] as num?)?.toDouble() ?? 5.0;
      final currentCount =
          (userDoc.data()!['reviewCount'] as num?)?.toInt() ?? 0;
      final newCount = currentCount + 1;
      final newRating =
          ((currentRating * currentCount) + rating) / newCount;

      batch.update(userRef, {
        'rating': double.parse(newRating.toStringAsFixed(1)),
        'reviewCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Stream reviews left for a specific user
  Stream<List<Review>> streamReviewsForUser(String userId) {
    if (!_isInitialized || userId.isEmpty) return const Stream.empty();

    return firestore!
        .collection('reviews')
        .where('targetUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final d = doc.data();
        return Review(
          id: doc.id,
          transactionId: d['transactionId'] ?? '',
          reviewerId: d['reviewerId'] ?? '',
          reviewerName: d['reviewerName'] ?? 'Peer',
          reviewerAvatarUrl: d['reviewerAvatarUrl'],
          targetUserId: d['targetUserId'] ?? '',
          rating: (d['rating'] as num?)?.toDouble() ?? 5.0,
          comment: d['comment'] ?? '',
          createdAt:
              (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          itemTitle: d['itemTitle'] ?? 'Shared Item',
        );
      }).toList();
    });
  }

  // ===========================================================================
  // FIRESTORE: NOTIFICATIONS
  // ===========================================================================

  Stream<List<AppNotification>> streamNotifications(String userId) {
    if (!_isInitialized || userId.isEmpty) return const Stream.empty();

    return firestore!
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final d = doc.data();
            return AppNotification(
              id: doc.id,
              userId: d['userId'] ?? '',
              title: d['title'] ?? '',
              message: d['message'] ?? '',
              type: NotificationType.values.firstWhere(
                (t) => t.name == d['type'],
                orElse: () => NotificationType.borrowRequest,
              ),
              createdAt:
                  (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isRead: d['isRead'] ?? false,
              referenceId: d['referenceId'],
            );
          }).toList();
        });
  }

  Future<void> markNotificationAsRead(String id) async {
    if (!_isInitialized) return;
    await firestore!.collection('notifications').doc(id).update({
      'isRead': true,
    });
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    if (!_isInitialized || userId.isEmpty) return;
    final docs = await firestore!
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    if (docs.docs.isEmpty) return;
    final batch = firestore!.batch();
    for (var doc in docs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ===========================================================================
  // FIRESTORE: ADMIN COMMAND CENTER OVERSIGHT & TELEMETRY
  // ===========================================================================

  /// Stream all borrow requests across the entire community for admin auditing
  Stream<List<BorrowRequest>> streamAllBorrowRequestsAdmin() {
    if (!_isInitialized) return const Stream.empty();

    return firestore!.collection('borrow_requests').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final d = doc.data();
        return BorrowRequest(
          id: doc.id,
          listingId: d['listingId'] ?? '',
          itemTitle: d['itemTitle'] ?? '',
          borrowerId: d['borrowerId'] ?? '',
          borrowerName: d['borrowerName'] ?? 'Community Borrower',
          ownerId: d['ownerId'] ?? '',
          ownerName: d['ownerName'] ?? 'Community Owner',
          requestDate:
              (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endDate:
              (d['endDate'] as Timestamp?)?.toDate() ??
              DateTime.now().add(const Duration(days: 3)),
          status: RequestStatus.values.firstWhere(
            (s) => s.name == d['status'],
            orElse: () => RequestStatus.pending,
          ),
          message: d['message'],
          handoverQrToken: d['handoverQrToken'],
          returnQrToken: d['returnQrToken'],
          notes: d['notes'],
          depositAmount: (d['depositAmount'] as num?)?.toDouble(),
        );
      }).toList();
    });
  }

  /// Stream all registered community citizens for admin directory
  Stream<List<UserProfile>> streamAllUsersAdmin() {
    if (!_isInitialized) return const Stream.empty();

    return firestore!.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserProfile(
          id: doc.id,
          name: data['name'] ?? 'Citizen',
          email: data['email'] ?? '',
          avatarUrl: data['avatarUrl'],
          bio: data['bio'] ?? '',
          location: data['location'] ?? 'Community',
          rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
          reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
          completedLoans: (data['completedLoans'] as num?)?.toInt() ?? 0,
          joinedDate:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isVerified: data['isVerified'] ?? true,
          isAdmin: data['isAdmin'] as bool? ?? false,
        );
      }).toList();
    });
  }

  /// Ping Cloud Firestore and measure true roundtrip latency in milliseconds
  Future<int> pingFirestoreLatency() async {
    if (!_isInitialized) return -1;

    final stopwatch = Stopwatch()..start();
    try {
      await firestore!.collection('_telemetry').doc('latency_ping').set({
        'pingedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      stopwatch.stop();
      return -1;
    }
  }

  /// Admin toggle user verification status
  Future<void> adminToggleUserVerification(
    String userId,
    bool isVerified,
  ) async {
    if (!_isInitialized) return;
    await firestore!.collection('users').doc(userId).update({
      'isVerified': isVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin override: Force-complete a stuck loan or resolve dispute
  Future<void> adminForceCompleteRequest(
    String requestId,
    String? listingId,
  ) async {
    if (!_isInitialized) return;

    final batch = firestore!.batch();
    batch.update(firestore!.collection('borrow_requests').doc(requestId), {
      'status': RequestStatus.returned.name,
      'notes': '[ADMIN RESOLVED] Loan closed by System Administrator.',
      'handoverQrToken': FieldValue.delete(),
      'returnQrToken': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (listingId != null && listingId.isNotEmpty) {
      batch.update(firestore!.collection('items').doc(listingId), {
        'availability': ItemAvailability.available.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
