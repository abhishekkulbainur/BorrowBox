import 'package:flutter_test/flutter_test.dart';
import 'package:lendnborrow/core/models/borrow_request.dart';
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/models/review.dart';
import 'package:lendnborrow/core/models/user_profile.dart';
import 'package:lendnborrow/core/services/notification_service.dart';
import 'package:lendnborrow/core/services/transaction_service.dart';

void main() {
  group('TransactionService Tests', () {
    late TransactionService transactionService;
    late MarketplaceItem testItem;
    late UserProfile borrower;
    late UserProfile owner;
    late UserProfile intruder;

    setUp(() {
      transactionService = TransactionService();
      owner = UserProfile(
        id: 'user_abhishek',
        name: 'Abhishek Kulbainur',
        email: 'abhishek@borrowbox.local',
        rating: 4.9,
        joinedDate: DateTime(2025, 1, 1),
      );
      borrower = UserProfile(
        id: 'user_snehal',
        name: 'Snehal Mascarenhas',
        email: 'snehal@borrowbox.local',
        rating: 4.8,
        joinedDate: DateTime(2025, 1, 1),
      );
      intruder = UserProfile(
        id: 'user_intruder',
        name: 'Malicious Third Party',
        email: 'intruder@borrowbox.local',
        rating: 1.0,
        joinedDate: DateTime(2025, 1, 1),
      );
      testItem = MarketplaceItem(
        id: 'item_test_drill',
        title: 'Cordless Drill Set',
        description: 'Two-speed cordless drill with bit accessories',
        category: ItemCategory.tools,
        condition: ItemCondition.likeNew,
        availability: ItemAvailability.available,
        ownerId: owner.id,
        ownerName: owner.name,
        pickupLocation: 'Main Gate',
        maxDurationDays: 7,
        imageUrls: [],
        createdAt: DateTime.now(),
      );
    });

    test(
      'Create borrow request creates pending request and dispatches owner notification',
      () async {
        final req = await transactionService.createBorrowRequest(
          item: testItem,
          borrowerId: borrower.id,
          borrowerName: borrower.name,
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 4)),
          message: 'Need it for shelf installation',
        );

        expect(req.id, isNotEmpty);
        expect(req.status, RequestStatus.pending);
        expect(req.listingId, testItem.id);
        expect(req.borrowerId, borrower.id);
        expect(req.ownerId, owner.id);

        final borrowerBorrows = transactionService.getMyBorrowed(borrower.id);
        expect(borrowerBorrows.any((r) => r.id == req.id), isTrue);

        final ownerIncoming = transactionService.getIncomingPendingRequests(
          owner.id,
        );
        expect(ownerIncoming.any((r) => r.id == req.id), isTrue);

        final ownerNotifs = NotificationService().getNotificationsForUser(
          owner.id,
        );
        expect(ownerNotifs.any((n) => n.referenceId == req.id), isTrue);
      },
    );

    test('User cannot borrow their own listed item', () async {
      expect(
        () async => await transactionService.createBorrowRequest(
          item: testItem,
          borrowerId: owner.id, // Owner attempting to borrow own item
          borrowerName: owner.name,
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 4)),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'Only listing owner can approve request; non-owner cannot approve',
      () async {
        final req = await transactionService.createBorrowRequest(
          item: testItem,
          borrowerId: borrower.id,
          borrowerName: borrower.name,
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 4)),
        );

        // Non-owner / intruder tries to approve
        final unauthorizedApproval = transactionService.approveRequest(
          req.id,
          actorId: intruder.id,
        );
        expect(unauthorizedApproval, isFalse);

        // Borrower cannot approve their own request
        final borrowerSelfApproval = transactionService.approveRequest(
          req.id,
          actorId: borrower.id,
        );
        expect(borrowerSelfApproval, isFalse);

        // Owner approves successfully
        final authorizedApproval = transactionService.approveRequest(
          req.id,
          actorId: owner.id,
        );
        expect(authorizedApproval, isTrue);

        final updated = transactionService.getRequestById(req.id)!;
        expect(updated.status, RequestStatus.handoverPending);
        expect(updated.handoverQrToken, isNotNull);
        expect(updated.handoverQrToken?.startsWith('BB-HANDOVER-'), isTrue);
      },
    );

    test('Owner can reject borrow request with reason', () async {
      final req = await transactionService.createBorrowRequest(
        item: testItem,
        borrowerId: borrower.id,
        borrowerName: borrower.name,
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 4)),
      );

      final rejected = transactionService.rejectRequest(
        req.id,
        actorId: owner.id,
        reason: 'Out of town',
      );
      expect(rejected, isTrue);

      final updated = transactionService.getRequestById(req.id)!;
      expect(updated.status, RequestStatus.rejected);
      expect(updated.notes, 'Out of town');
    });

    test(
      'Handover verification: rejects intruder, verifies authorized scanner, and burns token to prevent replay',
      () async {
        final req = await transactionService.createBorrowRequest(
          item: testItem,
          borrowerId: borrower.id,
          borrowerName: borrower.name,
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 4)),
        );
        transactionService.approveRequest(req.id, actorId: owner.id);
        final approvedReq = transactionService.getRequestById(req.id)!;
        final token = approvedReq.handoverQrToken!;

        // 1. Intruder scanning the token must be rejected
        final intruderScan = transactionService.confirmHandover(
          req.id,
          token,
          scannerUserId: intruder.id,
        );
        expect(intruderScan, isFalse);

        // 2. Invalid token string must be rejected
        final invalidTokenScan = transactionService.confirmHandover(
          req.id,
          'BB-HANDOVER-FAKE-TOKEN',
          scannerUserId: borrower.id,
        );
        expect(invalidTokenScan, isFalse);

        // 3. Authorized counterpart confirming handover succeeds
        final authorizedScan = transactionService.confirmHandover(
          req.id,
          token,
          scannerUserId: borrower.id,
        );
        expect(authorizedScan, isTrue);

        final activeReq = transactionService.getRequestById(req.id)!;
        expect(activeReq.status, RequestStatus.active);
        expect(activeReq.handoverQrToken, isNull); // Burned after use

        // 4. Token replay attempt must fail
        final replayedScan = transactionService.confirmHandover(
          req.id,
          token,
          scannerUserId: borrower.id,
        );
        expect(replayedScan, isFalse);
      },
    );

    test(
      'Complete Return Flow: initiate return, burn return token, confirm return',
      () async {
        final req = await transactionService.createBorrowRequest(
          item: testItem,
          borrowerId: borrower.id,
          borrowerName: borrower.name,
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 4)),
        );
        transactionService.approveRequest(req.id, actorId: owner.id);
        final approvedReq = transactionService.getRequestById(req.id)!;
        transactionService.confirmHandover(
          req.id,
          approvedReq.handoverQrToken!,
          scannerUserId: borrower.id,
        );

        // Borrower initiates return
        final returnInitiated = transactionService.initiateReturn(
          req.id,
          actorId: borrower.id,
        );
        expect(returnInitiated, isTrue);

        final returnPendingReq = transactionService.getRequestById(req.id)!;
        expect(returnPendingReq.status, RequestStatus.returnPending);
        expect(returnPendingReq.returnQrToken, isNotNull);

        final returnToken = returnPendingReq.returnQrToken!;

        // Intruder cannot confirm return
        final intruderConfirm = transactionService.confirmReturn(
          req.id,
          returnToken,
          scannerUserId: intruder.id,
        );
        expect(intruderConfirm, isFalse);

        // Owner confirms receipt of returned item
        final returnConfirmed = transactionService.confirmReturn(
          req.id,
          returnToken,
          scannerUserId: owner.id,
        );
        expect(returnConfirmed, isTrue);

        final completedReq = transactionService.getRequestById(req.id)!;
        expect(completedReq.status, RequestStatus.returned);
        expect(completedReq.returnQrToken, isNull); // Burned after return
      },
    );

    test(
      'Review verification: prevents self-review and duplicate reviews',
      () async {
        // 1. Attempt review on unfinished transaction
        final req = await transactionService.createBorrowRequest(
          item: testItem,
          borrowerId: borrower.id,
          borrowerName: borrower.name,
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 4)),
        );
        final invalidReview = Review(
          id: 'rev_invalid',
          transactionId: req.id,
          reviewerId: borrower.id,
          reviewerName: borrower.name,
          targetUserId: owner.id,
          rating: 5.0,
          comment: 'Too early review',
          createdAt: DateTime.now(),
          itemTitle: testItem.title,
        );
        expect(transactionService.addReview(invalidReview), isFalse);

        // 2. Complete the transaction
        transactionService.approveRequest(req.id, actorId: owner.id);
        final approved = transactionService.getRequestById(req.id)!;
        transactionService.confirmHandover(
          req.id,
          approved.handoverQrToken!,
          scannerUserId: borrower.id,
        );
        transactionService.initiateReturn(req.id, actorId: borrower.id);
        final pendingReturn = transactionService.getRequestById(req.id)!;
        transactionService.confirmReturn(
          req.id,
          pendingReturn.returnQrToken!,
          scannerUserId: owner.id,
        );

        // 3. Valid peer review succeeds
        final validReview = Review(
          id: 'rev_valid',
          transactionId: req.id,
          reviewerId: borrower.id,
          reviewerName: borrower.name,
          targetUserId: owner.id,
          rating: 5.0,
          comment: 'Great tool, worked flawlessly!',
          createdAt: DateTime.now(),
          itemTitle: testItem.title,
        );
        expect(transactionService.addReview(validReview), isTrue);

        // 4. Duplicate review attempt by same reviewer fails
        final duplicateReview = Review(
          id: 'rev_duplicate',
          transactionId: req.id,
          reviewerId: borrower.id,
          reviewerName: borrower.name,
          targetUserId: owner.id,
          rating: 4.0,
          comment: 'Second review attempt',
          createdAt: DateTime.now(),
          itemTitle: testItem.title,
        );
        expect(transactionService.addReview(duplicateReview), isFalse);
      },
    );
  });
}
