import 'package:flutter_test/flutter_test.dart';
import 'package:lendnborrow/core/models/borrow_request.dart';
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/models/review.dart';
import 'package:lendnborrow/core/services/chat_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/services/transaction_service.dart';

void main() {
  group('ChatService Tests', () {
    late ChatService chatService;

    setUp(() {
      chatService = ChatService();
    });

    test('Create and retrieve conversation between borrower and lender', () async {
      final conv = await chatService.getOrCreateConversation(
        currentUserId: 'borrower_1',
        currentUserName: 'Alice Borrower',
        currentUserAvatar: null,
        otherUserId: 'lender_1',
        otherUserName: 'Bob Lender',
        itemId: 'item_drill_1',
        itemTitle: 'Bosch Hammer Drill',
      );

      expect(conv.id, contains('borrower_1'));
      expect(conv.id, contains('lender_1'));
      expect(conv.participants, contains('borrower_1'));
      expect(conv.participants, contains('lender_1'));
      expect(conv.itemTitle, 'Bosch Hammer Drill');

      // Idempotency: retrieving same conversation returns existing
      final conv2 = await chatService.getOrCreateConversation(
        currentUserId: 'borrower_1',
        currentUserName: 'Alice Borrower',
        otherUserId: 'lender_1',
        otherUserName: 'Bob Lender',
        itemId: 'item_drill_1',
        itemTitle: 'Bosch Hammer Drill',
      );
      expect(conv2.id, conv.id);
    });

    test('Sending messages updates unread count and conversation lastMessage', () async {
      final conv = await chatService.getOrCreateConversation(
        currentUserId: 'borrower_1',
        currentUserName: 'Alice',
        otherUserId: 'lender_1',
        otherUserName: 'Bob',
        itemId: 'item_1',
        itemTitle: 'Camera Lens',
      );

      await chatService.sendMessage(
        conversationId: conv.id,
        senderId: 'borrower_1',
        senderName: 'Alice',
        recipientId: 'lender_1',
        text: 'Hello Bob, is tomorrow 10am good for pickup?',
      );

      // Verify unread count for Bob
      final bobUnread = chatService.getUnreadCountForUser('lender_1');
      expect(bobUnread, 1);

      // Borrower Alice unread count is 0
      final aliceUnread = chatService.getUnreadCountForUser('borrower_1');
      expect(aliceUnread, 0);

      // Bob marks as read
      await chatService.markConversationAsRead(conv.id, 'lender_1');
      expect(chatService.getUnreadCountForUser('lender_1'), 0);
    });

    test('Block user prevents further message delivery', () async {
      final conv = await chatService.getOrCreateConversation(
        currentUserId: 'user_a',
        currentUserName: 'User A',
        otherUserId: 'user_b',
        otherUserName: 'User B',
        itemId: 'item_test',
        itemTitle: 'Tripod',
      );

      // User A blocks User B
      await chatService.blockUser(blockerId: 'user_a', blockedUserId: 'user_b');
      expect(chatService.isUserBlocked('user_b', currentUserId: 'user_a'), isTrue);

      // Sending message while blocked returns null
      final msg = await chatService.sendMessage(
        conversationId: conv.id,
        senderId: 'user_b',
        senderName: 'User B',
        recipientId: 'user_a',
        text: 'Unwanted message',
      );
      expect(msg, isNull);

      // Unblock restores communication
      await chatService.unblockUser(blockerId: 'user_a', blockedUserId: 'user_b');
      expect(chatService.isUserBlocked('user_b', currentUserId: 'user_a'), isFalse);
    });

    test('Submit safety report stores report successfully', () async {
      final report = await chatService.reportItemOrUser(
        reporterId: 'reporter_1',
        targetId: 'bad_item_1',
        type: 'item',
        reason: 'Misleading description / damaged item',
        details: 'The item arrived with significant undisclosed water damage.',
      );

      expect(report.id, isNotEmpty);
      expect(report.reporterId, 'reporter_1');
      expect(report.type, 'item');
      expect(report.status.name, 'pending');
    });
  });

  group('MarketplaceService & Listing Lifecycle Tests', () {
    late MarketplaceService service;

    setUp(() {
      service = MarketplaceService();
    });

    test('Toggle listing active status pauses and resumes item availability', () async {
      final item = service.allItems.first;
      expect(item.isActive, isTrue);
      expect(item.availability, ItemAvailability.available);

      // Pause listing
      await service.toggleListingActive(item.id, false);
      final pausedItem = service.getItemById(item.id)!;
      expect(pausedItem.isActive, isFalse);
      expect(pausedItem.availability, ItemAvailability.deactivated);

      // Resume listing
      await service.toggleListingActive(item.id, true);
      final resumedItem = service.getItemById(item.id)!;
      expect(resumedItem.isActive, isTrue);
      expect(resumedItem.availability, ItemAvailability.available);
    });

    test('Update listing details validates owner permission', () async {
      final item = service.allItems.first;
      final originalTitle = item.title;

      // Update with matching owner
      final success = await service.updateListing(
        item.id,
        actorId: item.ownerId,
        title: 'Updated ${item.title}',
        description: 'New verified description',
        pickupLocation: 'Main Campus Gate 2',
      );
      expect(success, isTrue);

      final updated = service.getItemById(item.id)!;
      expect(updated.title, 'Updated $originalTitle');
      expect(updated.pickupLocation, 'Main Campus Gate 2');

      // Update with unauthorized actor fails
      final unauthorized = await service.updateListing(
        item.id,
        actorId: 'intruder_user_id',
        title: 'Hacked Title',
      );
      expect(unauthorized, isFalse);
    });
  });

  group('TransactionService & Review Tests', () {
    late TransactionService txService;

    setUp(() {
      txService = TransactionService();
    });

    test('Borrower can cancel pending request safely', () {
      final req = txService.allTransactions.first;
      final borrowerId = req.borrowerId;

      final cancelled = txService.cancelRequest(req.id, borrowerId);
      expect(cancelled, isTrue);

      final updatedReq = txService.getRequestById(req.id)!;
      expect(updatedReq.status, RequestStatus.cancelled);
    });

    test('Add review updates peer ratings and stores review', () async {
      final review = Review(
        id: 'rev_test_1',
        transactionId: 'tx_test_1',
        reviewerId: 'reviewer_alice',
        reviewerName: 'Alice',
        targetUserId: 'target_bob',
        rating: 5.0,
        comment: 'Excellent condition, super friendly lender!',
        createdAt: DateTime.now(),
        itemTitle: 'Power Drill',
      );

      final ok = txService.addReview(review);
      expect(ok, isTrue);
      final userReviews = txService.getReviewsForUser('target_bob');
      expect(userReviews.any((r) => r.id == 'rev_test_1'), isTrue);
    });
  });
}
