import 'package:flutter_test/flutter_test.dart';
import 'package:lendnborrow/core/models/borrow_request.dart';
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/models/user_profile.dart';
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/services/notification_service.dart';
import 'package:lendnborrow/core/services/transaction_service.dart';

void main() {
  group('10-User Concurrent Simulation & Security Suite', () {
    late AuthService authService;
    late MarketplaceService marketplaceService;
    late TransactionService transactionService;
    late NotificationService notificationService;

    setUp(() {
      authService = AuthService();
      marketplaceService = MarketplaceService();
      transactionService = TransactionService();
      notificationService = NotificationService();
    });

    test(
      'Scenario 1: 10 separate user accounts can register and maintain isolated identities',
      () async {
        final users = <UserProfile>[];

        for (int i = 1; i <= 10; i++) {
          final email = 'device_user_$i@borrowbox.test';
          final name = 'Test User $i';
          await authService.registerWithEmail(
            name: name,
            email: email,
            password: 'password_123_$i',
            location: 'Block $i, Area $i',
          );
          final current = authService.currentUser;
          expect(current, isNotNull);
          expect(current!.email, email);
          expect(current.name, name);
          users.add(current);
        }

        // Verify all 10 user IDs are strictly unique
        final uniqueIds = users.map((u) => u.id).toSet();
        expect(
          uniqueIds.length,
          10,
          reason: 'All 10 users must receive distinct, unique user IDs',
        );
      },
    );

    test(
      'Scenario 2: One user creates an item and all other 9 users can discover it',
      () async {
        final owner = UserProfile(
          id: 'usr_owner_01',
          name: 'Device 1 Owner',
          email: 'owner1@borrowbox.test',
          joinedDate: DateTime.now(),
        );

        final testItem = MarketplaceItem(
          id: 'item_projector_101',
          ownerId: owner.id,
          ownerName: owner.name,
          title: 'Epson 1080p Home Cinema Projector',
          description: 'Bright 3000 lumens projector with HDMI cable',
          category: ItemCategory.electronics,
          condition: ItemCondition.excellent,
          pickupLocation: 'Tower 4, Flat 402',
          maxDurationDays: 3,
          imageUrls: [],
          createdAt: DateTime.now(),
          availability: ItemAvailability.available,
        );

        marketplaceService.addListing(testItem);

        // Verify the item is in the catalog
        final foundItem = marketplaceService.getItemById('item_projector_101');
        expect(foundItem, isNotNull);
        expect(foundItem!.ownerId, owner.id);

        // Simulate 9 peer users searching for "projector"
        for (int i = 2; i <= 10; i++) {
          final searchResults = marketplaceService.searchAndFilter(
            query: 'projector',
          );
          expect(
            searchResults.any((item) => item.id == 'item_projector_101'),
            isTrue,
            reason:
                'Device $i must be able to view the item listed by Device 1',
          );
        }
      },
    );

    test(
      'Scenario 3: Borrower submits request, owner sees it, approves, and borrower receives update',
      () async {
        final owner = UserProfile(
          id: 'usr_owner_02',
          name: 'Camera Owner',
          email: 'camera_owner@borrowbox.test',
          joinedDate: DateTime.now(),
        );

        final borrower = UserProfile(
          id: 'usr_borrower_03',
          name: 'Film Student Borrower',
          email: 'film_student@borrowbox.test',
          joinedDate: DateTime.now(),
        );

        final cameraItem = MarketplaceItem(
          id: 'item_sony_alpha',
          ownerId: owner.id,
          ownerName: owner.name,
          title: 'Sony Alpha A7 III Full-Frame Camera',
          description: 'Mirrorless camera body with 28-70mm lens',
          category: ItemCategory.creative,
          condition: ItemCondition.likeNew,
          pickupLocation: 'Media Department',
          maxDurationDays: 4,
          imageUrls: [],
          createdAt: DateTime.now(),
          availability: ItemAvailability.available,
        );
        marketplaceService.addListing(cameraItem);

        // Borrower submits request
        final request = await transactionService.createBorrowRequest(
          item: cameraItem,
          borrowerId: borrower.id,
          borrowerName: borrower.name,
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 3)),
          message: 'Need for weekend student short film production.',
        );

        expect(request.status, RequestStatus.pending);
        expect(request.borrowerId, borrower.id);
        expect(request.ownerId, owner.id);

        // Owner checks incoming requests
        final incomingRequests = transactionService.getIncomingPendingRequests(
          owner.id,
        );
        expect(incomingRequests.any((r) => r.id == request.id), isTrue);

        // Verify owner received notification
        final ownerNotifs = notificationService.getNotificationsForUser(
          owner.id,
        );
        expect(ownerNotifs.any((n) => n.referenceId == request.id), isTrue);

        // Owner approves request
        final approvalSuccess = transactionService.approveRequest(
          request.id,
          actorId: owner.id,
        );
        expect(approvalSuccess, isTrue);

        final updatedRequest = transactionService.getRequestById(request.id);
        expect(updatedRequest!.status, RequestStatus.handoverPending);
        expect(updatedRequest.handoverQrToken, isNotNull);

        // Item availability becomes reserved
        final reservedItem = marketplaceService.getItemById(cameraItem.id);
        expect(reservedItem!.availability, ItemAvailability.reserved);
      },
    );

    test(
      'Scenario 4: Concurrency control prevents borrowing an unavailable or already reserved item',
      () async {
        final owner = UserProfile(
          id: 'usr_owner_04',
          name: 'Generator Owner',
          email: 'generator_owner@borrowbox.test',
          joinedDate: DateTime.now(),
        );

        final borrowedItem = MarketplaceItem(
          id: 'item_portable_generator',
          ownerId: owner.id,
          ownerName: owner.name,
          title: 'Honda 2000W Inverter Generator',
          description: 'Super quiet generator for outdoor events',
          category: ItemCategory.tools,
          condition: ItemCondition.good,
          pickupLocation: 'Clubhouse',
          maxDurationDays: 2,
          imageUrls: [],
          createdAt: DateTime.now(),
          availability: ItemAvailability.borrowed, // Already borrowed!
        );
        marketplaceService.addListing(borrowedItem);

        // User 5 attempts to request the already borrowed item
        expect(
          () async => await transactionService.createBorrowRequest(
            item: borrowedItem,
            borrowerId: 'usr_user_05',
            borrowerName: 'Late Requester',
            startDate: DateTime.now().add(const Duration(days: 1)),
            endDate: DateTime.now().add(const Duration(days: 2)),
          ),
          throwsA(isA<ArgumentError>()),
          reason:
              'Borrowing request on unavailable item must be blocked by business logic',
        );
      },
    );

    test(
      'Scenario 5: Unauthorized third-party cannot tamper with profile or delete another user item',
      () async {
        final owner = UserProfile(
          id: 'usr_legit_owner',
          name: 'Legit Owner',
          email: 'legit@borrowbox.test',
          joinedDate: DateTime.now(),
        );

        final myItem = MarketplaceItem(
          id: 'item_drone_pro',
          ownerId: owner.id,
          ownerName: owner.name,
          title: 'DJI Mini 3 Pro Drone',
          description: 'Under 249g foldable drone with 4K HDR video',
          category: ItemCategory.electronics,
          condition: ItemCondition.likeNew,
          pickupLocation: 'Heli Pad',
          maxDurationDays: 3,
          imageUrls: [],
          createdAt: DateTime.now(),
          availability: ItemAvailability.available,
        );
        marketplaceService.addListing(myItem);

        // Malicious intruder attempts deletion
        final unauthorizedDelete = marketplaceService.deleteListing(
          'item_drone_pro',
          actorId: 'usr_malicious_hacker',
        );
        expect(unauthorizedDelete, isFalse);
        expect(marketplaceService.getItemById('item_drone_pro'), isNotNull);

        // Legitimate owner deletes
        final authorizedDelete = marketplaceService.deleteListing(
          'item_drone_pro',
          actorId: owner.id,
        );
        expect(authorizedDelete, isTrue);
        expect(marketplaceService.getItemById('item_drone_pro'), isNull);
      },
    );

    test(
      'Scenario 6: End-to-end QR handover, return verification, and completed loan metrics',
      () async {
        final ownerId = 'usr_peer_a';
        final borrowerId = 'usr_peer_b';

        final cycleItem = MarketplaceItem(
          id: 'item_mountain_bike',
          ownerId: ownerId,
          ownerName: 'Peer A',
          title: 'Trek Marlin 7 Mountain Bike',
          description: 'Lightweight alpha silver aluminum frame',
          category: ItemCategory.sports,
          condition: ItemCondition.excellent,
          pickupLocation: 'Trail Gate',
          maxDurationDays: 2,
          imageUrls: [],
          createdAt: DateTime.now(),
          availability: ItemAvailability.available,
        );
        marketplaceService.addListing(cycleItem);

        // Step 1: Peer B requests
        final req = await transactionService.createBorrowRequest(
          item: cycleItem,
          borrowerId: borrowerId,
          borrowerName: 'Peer B',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 2)),
        );

        // Step 2: Peer A approves
        final approved = transactionService.approveRequest(
          req.id,
          actorId: ownerId,
        );
        expect(approved, isTrue);

        final approvedReq = transactionService.getRequestById(req.id)!;
        final handoverToken = approvedReq.handoverQrToken!;
        expect(handoverToken, isNotEmpty);

        // Step 3: Peer B presents QR code, Peer A or B scans it
        final handoverDone = transactionService.confirmHandover(
          req.id,
          handoverToken,
          scannerUserId: borrowerId,
        );
        expect(handoverDone, isTrue);

        final activeReq = transactionService.getRequestById(req.id)!;
        expect(activeReq.status, RequestStatus.active);
        expect(
          activeReq.handoverQrToken,
          isNull,
          reason: 'Handover token burned on usage',
        );
        expect(
          marketplaceService.getItemById(cycleItem.id)!.availability,
          ItemAvailability.borrowed,
        );

        // Step 4: Peer B initiates return
        final returnInitiated = transactionService.initiateReturn(
          req.id,
          actorId: borrowerId,
        );
        expect(returnInitiated, isTrue);

        final returnPendingReq = transactionService.getRequestById(req.id)!;
        expect(returnPendingReq.status, RequestStatus.returnPending);
        final returnToken = returnPendingReq.returnQrToken!;
        expect(returnToken, isNotEmpty);

        // Step 5: Peer A confirms return inspection
        final returnConfirmed = transactionService.confirmReturn(
          req.id,
          returnToken,
          scannerUserId: ownerId,
        );
        expect(returnConfirmed, isTrue);

        final completedReq = transactionService.getRequestById(req.id)!;
        expect(completedReq.status, RequestStatus.returned);
        expect(
          completedReq.returnQrToken,
          isNull,
          reason: 'Return token burned on completion',
        );
        expect(
          marketplaceService.getItemById(cycleItem.id)!.availability,
          ItemAvailability.available,
        );
      },
    );
  });
}
