import 'dart:async';

// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

// Project Imports
import 'package:lendnborrow/core/models/app_notification.dart';
import 'package:lendnborrow/core/models/borrow_request.dart';
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/models/review.dart';
import 'package:lendnborrow/core/services/firebase_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/services/notification_service.dart';

class TransactionService extends ChangeNotifier {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal() {
    _initSeedTransactions();
  }

  final List<BorrowRequest> _transactions = [];
  final List<Review> _reviews = [];
  StreamSubscription<List<BorrowRequest>>? _txSubscription;

  void initSync(String userId) {
    if (!FirebaseService().isInitialized || userId.isEmpty) return;
    _txSubscription?.cancel();
    _txSubscription = FirebaseService()
        .streamBorrowRequests(userId)
        .listen(
          (firestoreTxs) {
            if (firestoreTxs.isNotEmpty) {
              _transactions.clear();
              _transactions.addAll(firestoreTxs);
              notifyListeners();
            }
          },
          onError: (e) {
            debugPrint("Transaction sync error: $e");
          },
        );
  }

  void disposeSync() {
    _txSubscription?.cancel();
    _txSubscription = null;
  }

  List<BorrowRequest> get allTransactions => List.unmodifiable(_transactions);
  List<Review> get allReviews => List.unmodifiable(_reviews);

  void _initSeedTransactions() {
    _transactions.addAll([
      // 1. An incoming pending request for Abhishek from Snehal
      BorrowRequest(
        id: "req_seed_01",
        listingId: "item_drill_02",
        itemTitle: "Bosch 18V Cordless Drill & Screwdriver Kit",
        borrowerId: "user_snehal",
        borrowerName: "Snehal Mascarenhas",
        ownerId: "user_abhishek",
        ownerName: "Abhishek Kulbainur",
        requestDate: DateTime.now().subtract(const Duration(hours: 3)),
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        status: RequestStatus.pending,
        message:
            "Hi Abhishek! I need to install a few bookshelf brackets in my room this weekend. Would love to borrow your drill!",
        depositAmount: 500,
      ),
      // 2. An active loan currently borrowed by Abhishek from Snehal
      BorrowRequest(
        id: "req_seed_02",
        listingId: "item_calc_01",
        itemTitle: "Casio fx-991EX ClassWiz Scientific Calculator",
        borrowerId: "user_abhishek",
        borrowerName: "Abhishek Kulbainur",
        ownerId: "user_snehal",
        ownerName: "Snehal Mascarenhas",
        requestDate: DateTime.now().subtract(const Duration(days: 2)),
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        status: RequestStatus.active,
        message: "Need this for my simulation practical exam.",
        handoverQrToken: null, // Invalidated after successful handover
      ),
      // 3. A completed past return
      BorrowRequest(
        id: "req_seed_03",
        listingId: "item_tent_03",
        itemTitle: "Quechua 3-Person Waterproof Camping Tent",
        borrowerId: "user_abhishek",
        borrowerName: "Abhishek Kulbainur",
        ownerId: "user_snehal",
        ownerName: "Snehal Mascarenhas",
        requestDate: DateTime.now().subtract(const Duration(days: 14)),
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 6)),
        status: RequestStatus.returned,
        message: "Weekend camping trip to Nandi Hills.",
        handoverQrToken: null,
        returnQrToken: null,
        notes: "Returned clean and dry on schedule.",
      ),
    ]);

    _reviews.addAll([
      Review(
        id: "rev_seed_01",
        transactionId: "req_seed_03",
        reviewerId: "user_snehal",
        reviewerName: "Snehal Mascarenhas",
        targetUserId: "user_abhishek",
        rating: 5.0,
        comment:
            "Abhishek returned the camping tent in immaculate condition, right on time. Highly recommended borrower!",
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        itemTitle: "Quechua 3-Person Waterproof Camping Tent",
      ),
    ]);
  }

  // Queries
  List<BorrowRequest> getMyBorrowed(String userId) {
    if (userId.isEmpty) return [];
    return _transactions.where((t) => t.borrowerId == userId).toList();
  }

  List<BorrowRequest> getMyLent(String userId) {
    if (userId.isEmpty) return [];
    return _transactions.where((t) => t.ownerId == userId).toList();
  }

  List<BorrowRequest> getActiveBorrows(String userId) {
    if (userId.isEmpty) return [];
    return _transactions
        .where(
          (t) =>
              t.borrowerId == userId &&
              (t.status == RequestStatus.active ||
                  t.status == RequestStatus.handoverPending ||
                  t.status == RequestStatus.returnPending),
        )
        .toList();
  }

  List<BorrowRequest> getActiveLoans(String userId) {
    if (userId.isEmpty) return [];
    return _transactions
        .where(
          (t) =>
              t.ownerId == userId &&
              (t.status == RequestStatus.active ||
                  t.status == RequestStatus.handoverPending ||
                  t.status == RequestStatus.returnPending),
        )
        .toList();
  }

  List<BorrowRequest> getIncomingPendingRequests(String ownerId) {
    if (ownerId.isEmpty) return [];
    return _transactions
        .where((t) => t.ownerId == ownerId && t.status == RequestStatus.pending)
        .toList();
  }

  List<BorrowRequest> getOutgoingPendingRequests(String borrowerId) {
    if (borrowerId.isEmpty) return [];
    return _transactions
        .where(
          (t) =>
              t.borrowerId == borrowerId && t.status == RequestStatus.pending,
        )
        .toList();
  }

  List<BorrowRequest> getHistory(String userId) {
    if (userId.isEmpty) return [];
    return _transactions
        .where(
          (t) =>
              (t.borrowerId == userId || t.ownerId == userId) &&
              (t.status == RequestStatus.returned ||
                  t.status == RequestStatus.cancelled ||
                  t.status == RequestStatus.rejected),
        )
        .toList();
  }

  BorrowRequest? getRequestById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // ============================================================================
  // SECURE TRANSACTION ACTIONS (Validated State Machine & Access Control)
  // ============================================================================

  // 1. Submit borrow request
  Future<BorrowRequest> createBorrowRequest({
    required MarketplaceItem item,
    required String borrowerId,
    required String borrowerName,
    required DateTime startDate,
    required DateTime endDate,
    String? message,
  }) async {
    // SECURITY: Users cannot borrow their own listed items
    if (borrowerId == item.ownerId) {
      throw ArgumentError(
        "Unauthorized: You cannot borrow an item that you already own.",
      );
    }

    if (endDate.isBefore(startDate)) {
      throw ArgumentError(
        "Invalid date range: End date cannot precede start date.",
      );
    }

    // Task 10: Concurrency guard - prevent borrowing an already reserved/borrowed item
    if (item.availability != ItemAvailability.available) {
      throw ArgumentError(
        "Item is currently not available for borrowing (${item.availability.name}).",
      );
    }

    final newRequest = BorrowRequest(
      id: const Uuid().v4(),
      listingId: item.id,
      itemTitle: item.title,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      ownerId: item.ownerId,
      ownerName: item.ownerName,
      requestDate: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      status: RequestStatus.pending,
      message: message,
      depositAmount: item.depositAmount,
    );

    _transactions.insert(0, newRequest);

    // Notify item owner locally
    NotificationService().addNotification(
      AppNotification(
        id: const Uuid().v4(),
        userId: item.ownerId,
        title: "New Borrow Request",
        message: "$borrowerName requested to borrow '${item.title}'.",
        type: NotificationType.borrowRequest,
        createdAt: DateTime.now(),
        referenceId: newRequest.id,
      ),
    );

    notifyListeners();

    if (FirebaseService().isInitialized) {
      try {
        final docId = await FirebaseService().createBorrowRequest(newRequest);
        if (docId != null && docId.isNotEmpty) {
          final index = _transactions.indexWhere((t) => t.id == newRequest.id);
          if (index != -1) {
            _transactions[index] = _transactions[index].copyWith(id: docId);
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint("Error creating borrow request in Firebase: $e");
      }
    }

    return newRequest;
  }

  // 2. Owner approves request
  bool approveRequest(String requestId, {String? actorId}) {
    final index = _transactions.indexWhere((t) => t.id == requestId);
    if (index == -1) return false;

    final tx = _transactions[index];

    // SECURITY: Only listing owner can approve; borrower cannot self-approve
    if (actorId != null && tx.ownerId != actorId) {
      return false;
    }
    if (actorId != null && tx.borrowerId == actorId) {
      return false;
    }

    // Must be in pending state
    if (tx.status != RequestStatus.pending) return false;

    final token =
        "BB-HANDOVER-${const Uuid().v4().substring(0, 8).toUpperCase()}";
    _transactions[index] = tx.copyWith(
      status: RequestStatus.handoverPending,
      handoverQrToken: token,
    );

    // Reserve item in marketplace
    MarketplaceService().updateAvailability(
      tx.listingId,
      ItemAvailability.reserved,
    );

    // Notify borrower
    NotificationService().addNotification(
      AppNotification(
        id: const Uuid().v4(),
        userId: tx.borrowerId,
        title: "Borrow Request Approved!",
        message:
            "Your request for '${tx.itemTitle}' was approved by ${tx.ownerName}. QR handover code is ready.",
        type: NotificationType.requestApproved,
        createdAt: DateTime.now(),
        referenceId: tx.id,
      ),
    );

    notifyListeners();

    if (FirebaseService().isInitialized) {
      FirebaseService().approveRequest(requestId, token).catchError((e) {
        debugPrint("Error approving request in Firebase: $e");
        // Rollback optimistic state if failed
        _transactions[index] = tx;
        notifyListeners();
      });
    }

    return true;
  }

  // 3. Owner declines request
  bool rejectRequest(String requestId, {String? actorId, String? reason}) {
    final index = _transactions.indexWhere((t) => t.id == requestId);
    if (index == -1) return false;

    final tx = _transactions[index];

    // SECURITY: Only listing owner can reject
    if (actorId != null && tx.ownerId != actorId) {
      return false;
    }

    if (tx.status != RequestStatus.pending) return false;

    _transactions[index] = tx.copyWith(
      status: RequestStatus.rejected,
      notes: reason,
    );

    // Notify borrower
    NotificationService().addNotification(
      AppNotification(
        id: const Uuid().v4(),
        userId: tx.borrowerId,
        title: "Borrow Request Declined",
        message:
            "Your request for '${tx.itemTitle}' was declined by the owner.",
        type: NotificationType.requestRejected,
        createdAt: DateTime.now(),
        referenceId: tx.id,
      ),
    );

    notifyListeners();

    if (FirebaseService().isInitialized) {
      FirebaseService().rejectRequest(requestId, reason: reason).catchError((
        e,
      ) {
        debugPrint("Error rejecting request in Firebase: $e");
      });
    }

    return true;
  }

  // 3b. Cancel Request (Borrower cancels request before handover)
  bool cancelRequest(String requestId, [String? actorId]) {
    final index = _transactions.indexWhere((t) => t.id == requestId);
    if (index == -1) return false;

    final tx = _transactions[index];

    // SECURITY: Only borrower can cancel, or owner if not yet active
    if (actorId != null && tx.borrowerId != actorId && tx.ownerId != actorId) {
      return false;
    }

    if (tx.status != RequestStatus.pending &&
        tx.status != RequestStatus.handoverPending) {
      return false;
    }

    _transactions[index] = tx.copyWith(
      status: RequestStatus.cancelled,
      clearHandoverToken: true,
    );

    // Revert item availability back to available if it was reserved
    MarketplaceService().updateAvailability(
      tx.listingId,
      ItemAvailability.available,
    );

    // Notify owner if borrower cancelled
    if (actorId == tx.borrowerId) {
      NotificationService().addNotification(
        AppNotification(
          id: const Uuid().v4(),
          userId: tx.ownerId,
          title: "Borrow Request Cancelled",
          message:
              "${tx.borrowerName} cancelled their request for '${tx.itemTitle}'.",
          type: NotificationType.requestRejected,
          createdAt: DateTime.now(),
          referenceId: tx.id,
        ),
      );
    }

    notifyListeners();

    if (FirebaseService().isInitialized) {
      FirebaseService().cancelRequest(requestId, tx.listingId).catchError((e) {
        debugPrint("Error cancelling request in Firebase: $e");
      });
    }

    return true;
  }

  // 4. Confirm Handover (transitions to active & burns the single-use token)
  bool confirmHandover(
    String requestId,
    String scannedToken, {
    String? scannerUserId,
  }) {
    final index = _transactions.indexWhere((t) => t.id == requestId);
    if (index == -1) return false;

    final tx = _transactions[index];

    // Status check
    if (tx.status != RequestStatus.handoverPending) return false;

    // SECURITY: Scanner must be an authorized participant (borrower or owner)
    if (scannerUserId != null &&
        scannerUserId != tx.borrowerId &&
        scannerUserId != tx.ownerId) {
      return false;
    }

    // Exact token match required (no wildcards)
    if (tx.handoverQrToken == null || tx.handoverQrToken != scannedToken) {
      return false;
    }

    // Invalidate token on use to prevent replay attacks
    _transactions[index] = tx.copyWith(
      status: RequestStatus.active,
      clearHandoverToken: true,
    );

    MarketplaceService().updateAvailability(
      tx.listingId,
      ItemAvailability.borrowed,
    );

    notifyListeners();

    if (FirebaseService().isInitialized) {
      FirebaseService()
          .confirmHandover(
            requestId,
            scannedToken,
            scannerUserId ?? tx.borrowerId,
          )
          .catchError((e) {
            debugPrint("Error confirming handover in Firebase: $e");
            return false;
          });
    }

    return true;
  }

  // 5. Initiate Return (generates return QR token)
  bool initiateReturn(String requestId, {String? actorId}) {
    final index = _transactions.indexWhere((t) => t.id == requestId);
    if (index == -1) return false;

    final tx = _transactions[index];

    // Status check
    if (tx.status != RequestStatus.active) return false;

    // SECURITY: Only borrower or owner can initiate return
    if (actorId != null && actorId != tx.borrowerId && actorId != tx.ownerId) {
      return false;
    }

    final returnToken =
        "BB-RETURN-${const Uuid().v4().substring(0, 8).toUpperCase()}";
    _transactions[index] = tx.copyWith(
      status: RequestStatus.returnPending,
      returnQrToken: returnToken,
    );

    // Notify owner
    NotificationService().addNotification(
      AppNotification(
        id: const Uuid().v4(),
        userId: tx.ownerId,
        title: "Item Ready for Return",
        message:
            "${tx.borrowerName} has marked '${tx.itemTitle}' ready for return inspection.",
        type: NotificationType.returnReminder,
        createdAt: DateTime.now(),
        referenceId: tx.id,
      ),
    );

    notifyListeners();

    if (FirebaseService().isInitialized) {
      FirebaseService().initiateReturn(requestId, returnToken).catchError((e) {
        debugPrint("Error initiating return in Firebase: $e");
      });
    }

    return true;
  }

  // 6. Confirm Return (transitions to returned & burns return token)
  bool confirmReturn(
    String requestId,
    String scannedToken, {
    String? scannerUserId,
  }) {
    final index = _transactions.indexWhere((t) => t.id == requestId);
    if (index == -1) return false;

    final tx = _transactions[index];

    // Status check
    if (tx.status != RequestStatus.returnPending) return false;

    // SECURITY: Only the owner receiving their item can confirm return
    if (scannerUserId != null && scannerUserId != tx.ownerId) {
      return false;
    }

    // Exact token match required
    if (tx.returnQrToken == null || tx.returnQrToken != scannedToken) {
      return false;
    }

    // Invalidate token and mark returned
    _transactions[index] = tx.copyWith(
      status: RequestStatus.returned,
      clearReturnToken: true,
    );

    MarketplaceService().updateAvailability(
      tx.listingId,
      ItemAvailability.available,
    );

    // Notify borrower to review
    NotificationService().addNotification(
      AppNotification(
        id: const Uuid().v4(),
        userId: tx.borrowerId,
        title: "Return Confirmed!",
        message:
            "${tx.ownerName} confirmed the safe return of '${tx.itemTitle}'. Please rate your experience!",
        type: NotificationType.itemReturned,
        createdAt: DateTime.now(),
        referenceId: tx.id,
      ),
    );

    notifyListeners();

    if (FirebaseService().isInitialized) {
      FirebaseService()
          .confirmReturn(requestId, scannedToken, scannerUserId ?? tx.ownerId)
          .catchError((e) {
            debugPrint("Error confirming return in Firebase: $e");
            return false;
          });
    }

    return true;
  }

  // 7. Add Review
  bool addReview(Review review) {
    // Check if transaction exists and if present ensure it is returned
    final tx = getRequestById(review.transactionId);
    if (tx != null) {
      if (tx.status != RequestStatus.returned) {
        return false;
      }
      // SECURITY: Reviewer must be a transaction participant
      if (review.reviewerId != tx.borrowerId && review.reviewerId != tx.ownerId) {
        return false;
      }
    }

    // SECURITY: No self reviews
    if (review.reviewerId == review.targetUserId) {
      return false;
    }

    // SECURITY: Prevent duplicate reviews for the same transaction by same reviewer
    final duplicate = _reviews.any(
      (r) =>
          r.transactionId == review.transactionId &&
          r.reviewerId == review.reviewerId,
    );
    if (duplicate) {
      return false;
    }

    _reviews.insert(0, review);
    notifyListeners();

    if (FirebaseService().isInitialized) {
      FirebaseService().createReview(
        transactionId: review.transactionId,
        reviewerId: review.reviewerId,
        reviewerName: review.reviewerName,
        reviewerAvatarUrl: review.reviewerAvatarUrl,
        targetUserId: review.targetUserId,
        rating: review.rating,
        comment: review.comment,
        itemTitle: review.itemTitle,
      ).catchError((e) {
        debugPrint("Error publishing review to Firebase: $e");
      });
    }

    return true;
  }

  List<Review> getReviewsForUser(String userId) {
    return _reviews.where((r) => r.targetUserId == userId).toList();
  }
}

final transactionServiceProvider = ChangeNotifierProvider<TransactionService>((
  ref,
) {
  return TransactionService();
});
