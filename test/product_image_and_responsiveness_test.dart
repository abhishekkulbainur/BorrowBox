// Dart Imports
import 'dart:io';

// Flutter Imports
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project Imports
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/services/storage_service.dart';
import 'package:lendnborrow/core/utils/responsive.dart';
import 'package:lendnborrow/core/widgets/item_card.dart';
import 'package:lendnborrow/core/widgets/product_image_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService & Product Image Tests', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService();
    });

    test('StorageService enforces maximum 5 images per listing', () {
      expect(StorageService.maxImagesPerListing, 5);
      expect(StorageService.maxFileSizeBytes, 10 * 1024 * 1024);
    });

    test('Upload listing images preserves photo order and designates first as cover', () async {
      // In offline/test mode without Firebase credentials, uploadListingImages gracefully falls back
      final mockFile1 = File('test_photo_cover.jpg');
      final mockFile2 = File('test_photo_detail.jpg');

      final urls = await storageService.uploadListingImages(
        userId: 'user_abhishek',
        itemId: 'item_laptop_01',
        files: [mockFile1, mockFile2],
      );

      expect(urls.length, 2);
      expect(urls.first, contains('test_photo_cover.jpg'));
      expect(urls[1], contains('test_photo_detail.jpg'));
    });

    test('StorageService deleteItemImages runs safely without crashing', () async {
      await expectLater(
        storageService.deleteItemImages(
          userId: 'user_abhishek',
          itemId: 'item_laptop_01',
          imageUrls: ['https://firebasestorage.googleapis.com/v0/b/mock/test.jpg'],
        ),
        completes,
      );
    });
  });

  group('Responsive Layout & Multi-Device Tests', () {
    testWidgets('Responsive.gridDelegate adapts properly to screen widths and text scaling', (tester) async {
      late SliverGridDelegateWithFixedCrossAxisCount delegateStandard;
      late SliverGridDelegateWithFixedCrossAxisCount delegateNarrow;
      late SliverGridDelegateWithFixedCrossAxisCount delegateLargeText;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Test standard phone screen (393 x 852 logical)
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              delegateStandard = Responsive.gridDelegate(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(delegateStandard.crossAxisCount, 2);
      expect(delegateStandard.childAspectRatio, greaterThan(0.6));

      // Test small screen (320px wide)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              delegateNarrow = Responsive.gridDelegate(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(delegateNarrow.childAspectRatio, lessThanOrEqualTo(delegateStandard.childAspectRatio));

      // Test enlarged accessibility text scale (1.4x)
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 740),
              textScaler: TextScaler.linear(1.4),
            ),
            child: Builder(
              builder: (context) {
                delegateLargeText = Responsive.gridDelegate(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      // Ensures more vertical breathing room per card for enlarged text
      expect(delegateLargeText.childAspectRatio, lessThan(0.70));
    });

    testWidgets('ItemCard renders on narrow 320px screen without RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      final testItem = MarketplaceItem(
        id: 'test_drill',
        ownerId: 'user_abhishek',
        ownerName: 'Abhishek Kulbainur',
        title: 'Bosch Professional 18V Cordless Rotary Hammer Drill Kit with Accessories',
        description: 'Includes 2 batteries and heavy duty case.',
        category: ItemCategory.tools,
        condition: ItemCondition.excellent,
        pickupLocation: 'Greenfield Heights, Block C Main Gate',
        maxDurationDays: 5,
        depositAmount: 500,
        createdAt: DateTime.now(),
        imageUrls: const ['assets/images/drill.jpg'],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 140, // Width of single column in 320px 2-column grid
                child: ItemCard(
                  item: testItem,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ItemCard), findsOneWidget);
      expect(find.textContaining('Bosch'), findsOneWidget);
      expect(tester.takeException(), isNull); // ZERO RenderFlex overflow!

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('ItemCard renders with 1.3x accessibility text scale without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 740));

      final testItem = MarketplaceItem(
        id: 'test_calc',
        ownerId: 'user_snehal',
        ownerName: 'Snehal Mascarenhas',
        title: 'Casio fx-991EX ClassWiz Advanced Scientific Calculator',
        description: 'Clean matrix and calculus solver.',
        category: ItemCategory.calculators,
        condition: ItemCondition.likeNew,
        pickupLocation: 'Campus Central Library Desk',
        maxDurationDays: 7,
        depositAmount: null,
        createdAt: DateTime.now(),
        imageUrls: const [],
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 740),
            textScaler: TextScaler.linear(1.3),
          ),
          child: ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 160,
                  child: ItemCard(
                    item: testItem,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ItemCard), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('ProductImageView & Gallery Component Tests', () {
    testWidgets('ProductImageView renders category icon when imageUrl is null or empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductImageView(
              imageUrl: null,
              category: ItemCategory.tools,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(ProductImageView), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('ProductImageGallery displays swipeable PageView and counter badge', (tester) async {
      const photos = [
        'assets/images/photo1.jpg',
        'assets/images/photo2.jpg',
        'assets/images/photo3.jpg',
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductImageGallery(
              imageUrls: photos,
              category: ItemCategory.electronics,
              height: 250,
            ),
          ),
        ),
      );

      expect(find.byType(ProductImageGallery), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget); // Counter badge
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('ProductImageGallery with empty photos renders placeholder gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductImageGallery(
              imageUrls: [],
              category: ItemCategory.books,
              height: 200,
            ),
          ),
        ),
      );

      expect(find.byType(ProductImageGallery), findsOneWidget);
      expect(find.byType(ProductImageView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
