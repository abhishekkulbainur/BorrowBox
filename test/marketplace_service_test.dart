import 'package:flutter_test/flutter_test.dart';
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';

void main() {
  group('MarketplaceService Tests', () {
    late MarketplaceService service;

    setUp(() {
      service = MarketplaceService();
    });

    test('Initial seeded items are available across diverse categories', () {
      final items = service.allItems;
      expect(items.length, greaterThanOrEqualTo(8));
      expect(items.any((i) => i.category == ItemCategory.calculators), isTrue);
      expect(items.any((i) => i.category == ItemCategory.tools), isTrue);
      expect(items.any((i) => i.category == ItemCategory.electronics), isTrue);
    });

    test(
      'Search filtering returns matching items by title and description',
      () {
        final results = service.searchAndFilter(query: 'Casio');
        expect(results.length, greaterThanOrEqualTo(1));
        expect(results.first.title.contains('Casio'), isTrue);

        final drillResults = service.searchAndFilter(query: 'Bosch');
        expect(drillResults.length, greaterThanOrEqualTo(1));
        expect(drillResults.first.title.contains('Bosch'), isTrue);
      },
    );

    test('Category filtering isolates specific categories', () {
      final toolsOnly = service.searchAndFilter(category: ItemCategory.tools);
      expect(toolsOnly.every((i) => i.category == ItemCategory.tools), isTrue);
      expect(toolsOnly.isNotEmpty, isTrue);
    });

    test('Condition and availability filtering works accurately', () {
      final likeNewOnly = service.searchAndFilter(
        condition: ItemCondition.likeNew,
      );
      expect(
        likeNewOnly.every((i) => i.condition == ItemCondition.likeNew),
        isTrue,
      );

      final availableOnly = service.searchAndFilter(onlyAvailable: true);
      expect(
        availableOnly.every(
          (i) => i.availability == ItemAvailability.available,
        ),
        isTrue,
      );
    });

    test('Toggle favorite updates favorite status and counter', () {
      final item = service.allItems.first;
      final initialFavCount = item.favoriteCount;

      expect(service.isFavorite(item.id), isFalse);

      service.toggleFavorite(item.id);
      expect(service.isFavorite(item.id), isTrue);
      expect(service.getFavoriteItems().any((i) => i.id == item.id), isTrue);

      final updatedItem = service.getItemById(item.id)!;
      expect(updatedItem.favoriteCount, initialFavCount + 1);

      // Toggle off
      service.toggleFavorite(item.id);
      expect(service.isFavorite(item.id), isFalse);
    });

    test('Add and delete new listing with authorization checks', () {
      final newItem = MarketplaceItem(
        id: 'test_item_999',
        ownerId: 'user_tester',
        ownerName: 'Test User',
        title: 'Arduino UNO Starter Kit',
        description: 'Complete microcontroller board with sensors',
        category: ItemCategory.electronics,
        condition: ItemCondition.likeNew,
        pickupLocation: 'Lab 4',
        maxDurationDays: 14,
        imageUrls: [],
        createdAt: DateTime.now(),
      );

      service.addListing(newItem);
      expect(service.getItemById('test_item_999'), isNotNull);

      // Intruder cannot delete
      final intruderDelete = service.deleteListing(
        'test_item_999',
        actorId: 'user_intruder',
      );
      expect(intruderDelete, isFalse);
      expect(service.getItemById('test_item_999'), isNotNull);

      // Owner deletes successfully
      final ownerDelete = service.deleteListing(
        'test_item_999',
        actorId: 'user_tester',
      );
      expect(ownerDelete, isTrue);
      expect(service.getItemById('test_item_999'), isNull);
    });
  });
}
