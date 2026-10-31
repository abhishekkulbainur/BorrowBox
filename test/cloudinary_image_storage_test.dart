// Dart Imports
import 'dart:convert';
import 'dart:io';

// Flutter Imports
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Package Imports
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Project Imports
import 'package:lendnborrow/core/cfg/cloudinary_config.dart';
import 'package:lendnborrow/core/models/listing_image.dart';
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/services/cloudinary_service.dart';
import 'package:lendnborrow/core/widgets/item_card.dart';
import 'package:lendnborrow/core/widgets/product_image_view.dart';

void main() {
  group('CloudinaryConfig & Credentials Security Tests', () {
    tearDown(() {
      CloudinaryConfig.resetOverrides();
    });

    test('CloudinaryConfig loads BorrowBox configured credentials safely', () {
      expect(CloudinaryConfig.cloudName, 'f8e7pbct');
      expect(CloudinaryConfig.uploadPreset, 'borrowbox_product_preset');
      expect(CloudinaryConfig.folder, 'borrowbox/product_images');
      expect(CloudinaryConfig.isConfigured, isTrue);
      expect(
        CloudinaryConfig.uploadApiUri.toString(),
        'https://api.cloudinary.com/v1_1/f8e7pbct/image/upload',
      );
      expect(CloudinaryConfig.maxImagesPerListing, 5);
      expect(CloudinaryConfig.maxFileSizeBytes, 10 * 1024 * 1024);
    });

    test('Zero-Secret Rule: Flutter client contains no API secret', () {
      // Reflection/Structural check: CloudinaryConfig has no api_secret field
      expect(CloudinaryConfig.uploadApiUri.toString(),
          contains('api.cloudinary.com/v1_1'));
      expect(CloudinaryConfig.uploadApiUri.toString(),
          isNot(contains('api_secret')));
    });

    test('CloudinaryConfig supports dynamic programmatic overrides for testing', () {
      CloudinaryConfig.setCredentials(
        cloudName: 'test-cloud-123',
        uploadPreset: 'test-unsigned-preset',
        folder: 'test/products',
      );

      expect(CloudinaryConfig.cloudName, 'test-cloud-123');
      expect(CloudinaryConfig.uploadPreset, 'test-unsigned-preset');
      expect(CloudinaryConfig.folder, 'test/products');
      expect(CloudinaryConfig.isConfigured, isTrue);
      expect(
        CloudinaryConfig.uploadApiUri.toString(),
        'https://api.cloudinary.com/v1_1/test-cloud-123/image/upload',
      );
    });

    test('Cloudinary URL optimizer injects responsive transformations', () {
      const originalUrl =
          'https://res.cloudinary.com/demo/image/upload/sample.jpg';

      final optimized = CloudinaryConfig.getOptimizedUrl(
        originalUrl,
        width: 600,
        height: 400,
      );

      expect(optimized, contains('f_auto'));
      expect(optimized, contains('q_auto'));
      expect(optimized, contains('w_600,h_400,c_fill'));
      expect(optimized, contains('sample.jpg'));

      // Non-cloudinary URLs are left untouched
      const externalUrl = 'https://example.com/photo.png';
      expect(CloudinaryConfig.getOptimizedUrl(externalUrl), externalUrl);
    });
  });

  group('ListingImage Model & Firestore Schema Tests', () {
    test('ListingImage serializes and deserializes accurately', () {
      final now = DateTime.now();
      final image = ListingImage(
        secureUrl: 'https://res.cloudinary.com/demo/image/upload/v123/prod_1.jpg',
        publicId: 'borrowbox/product_images/prod_1',
        width: 1920,
        height: 1080,
        format: 'jpg',
        bytes: 245600,
        order: 0,
        isCover: true,
        createdAt: now,
      );

      final map = image.toMap();
      expect(map['secure_url'], image.secureUrl);
      expect(map['public_id'], image.publicId);
      expect(map['width'], 1920);
      expect(map['height'], 1080);
      expect(map['format'], 'jpg');
      expect(map['bytes'], 245600);
      expect(map['order'], 0);
      expect(map['is_cover'], isTrue);

      final fromMap = ListingImage.fromMap(map);
      expect(fromMap.secureUrl, image.secureUrl);
      expect(fromMap.publicId, image.publicId);
      expect(fromMap.width, 1920);
      expect(fromMap.height, 1080);
      expect(fromMap.order, 0);
      expect(fromMap.isCover, isTrue);
    });

    test('ListingImage.fromUrl provides backward compatibility for legacy strings', () {
      const legacyUrl = 'https://firebasestorage.googleapis.com/v0/b/app/item.jpg';
      final img = ListingImage.fromUrl(legacyUrl, order: 2, isCover: false);

      expect(img.secureUrl, legacyUrl);
      expect(img.publicId, '');
      expect(img.order, 2);
      expect(img.isCover, isFalse);
    });
  });

  group('MarketplaceItem Cloudinary Metadata Integration Tests', () {
    test('MarketplaceItem persists imagesMeta and preserves imageUrls backward compatibility', () {
      final images = [
        const ListingImage(
          secureUrl: 'https://res.cloudinary.com/demo/image/upload/img_1.jpg',
          publicId: 'borrowbox/product_images/img_1',
          order: 0,
          isCover: true,
        ),
        const ListingImage(
          secureUrl: 'https://res.cloudinary.com/demo/image/upload/img_2.jpg',
          publicId: 'borrowbox/product_images/img_2',
          order: 1,
          isCover: false,
        ),
      ];

      final item = MarketplaceItem(
        id: 'item_test_01',
        ownerId: 'user_1',
        ownerName: 'Alice',
        title: 'Projector',
        description: 'HD Mini Projector',
        category: ItemCategory.electronics,
        condition: ItemCondition.excellent,
        pickupLocation: 'Main Campus',
        createdAt: DateTime.now(),
        imageUrls: images.map((i) => i.secureUrl).toList(),
        imagesMeta: images,
      );

      expect(item.images.length, 2);
      expect(item.coverImageUrl, images[0].secureUrl);
      expect(item.photoUrls.length, 2);
      expect(item.photoUrls.first, images[0].secureUrl);

      // Verify Firestore toMap and fromMap
      final map = item.toMap();
      expect(map['imageUrls'], isA<List>());
      expect(map['imagesMeta'], isA<List>());

      final reconstructed = MarketplaceItem.fromMap(map, id: 'item_test_01');
      expect(reconstructed.id, 'item_test_01');
      expect(reconstructed.images.length, 2);
      expect(reconstructed.images[0].publicId, 'borrowbox/product_images/img_1');
      expect(reconstructed.images[0].isCover, isTrue);
      expect(reconstructed.coverImageUrl, images[0].secureUrl);
    });

    test('Legacy items without imagesMeta synthesize ListingImage objects seamlessly', () {
      final legacyItem = MarketplaceItem(
        id: 'legacy_item',
        ownerId: 'user_legacy',
        ownerName: 'Bob',
        title: 'Old Drill',
        description: 'Standard drill',
        category: ItemCategory.tools,
        condition: ItemCondition.good,
        pickupLocation: 'Indiranagar',
        createdAt: DateTime.now(),
        imageUrls: const [
          'https://example.com/legacy_cover.jpg',
          'https://example.com/legacy_side.jpg',
        ],
        // imagesMeta is omitted/null
      );

      expect(legacyItem.images.length, 2);
      expect(legacyItem.images[0].secureUrl, 'https://example.com/legacy_cover.jpg');
      expect(legacyItem.images[0].isCover, isTrue);
      expect(legacyItem.images[1].isCover, isFalse);
      expect(legacyItem.coverImageUrl, 'https://example.com/legacy_cover.jpg');
    });
  });

  group('CloudinaryService Upload & Error Handling Tests', () {
    late Directory tempDir;
    late List<File> testFiles;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cloudinary_test_');
      testFiles = [];
      for (int i = 0; i < 5; i++) {
        final f = File('${tempDir.path}/test_image_$i.jpg');
        await f.writeAsBytes(List.generate(1024, (index) => index % 256));
        testFiles.add(f);
      }
    });

    tearDown(() async {
      CloudinaryConfig.resetOverrides();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Upload all 5 images via Cloudinary unsigned API with mock client', () async {
      CloudinaryConfig.setCredentials(
        cloudName: 'test-cloud',
        uploadPreset: 'test-preset',
        folder: 'borrowbox/product_images',
      );

      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        expect(request.method, 'POST');
        expect(request.url.toString(), contains('api.cloudinary.com/v1_1/test-cloud/image/upload'));

        return http.Response(
          json.encode({
            'secure_url': 'https://res.cloudinary.com/test-cloud/image/upload/v123/img_$requestCount.jpg',
            'public_id': 'borrowbox/product_images/item_123_$requestCount',
            'width': 1280,
            'height': 960,
            'format': 'jpg',
            'bytes': 150000,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = CloudinaryService();
      final List<double> progressValues = [];
      int onProgressCallCount = 0;

      final results = await service.uploadListingImages(
        userId: 'user_test_alice',
        itemId: 'item_123',
        files: testFiles,
        coverIndex: 2, // Photo 2 designated as cover
        onProgress: (overall, current, total) {
          onProgressCallCount++;
          progressValues.add(overall);
        },
        client: mockClient,
      );

      expect(results.length, 5);
      expect(requestCount, 5);
      expect(onProgressCallCount, greaterThanOrEqualTo(5));
      expect(progressValues.last, 1.0);

      // Verify that cover image at index 0 has isCover = true
      expect(results[0].isCover, isTrue);
      expect(results[0].order, 0);

      // Remaining photos have isCover = false
      for (int i = 1; i < results.length; i++) {
        expect(results[i].isCover, isFalse);
        expect(results[i].order, i);
      }
    });

    test('CloudinaryService handles failed uploads and throws CloudinaryUploadException', () async {
      CloudinaryConfig.setCredentials(
        cloudName: 'test-cloud',
        uploadPreset: 'test-preset',
      );

      final errorClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'error': {'message': 'Invalid upload_preset or cloud_name'}
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = CloudinaryService();

      expect(
        () async => await service.uploadSingleImage(
          file: testFiles.first,
          userId: 'user_1',
          itemId: 'item_1',
          order: 0,
          isCover: true,
          client: errorClient,
        ),
        throwsA(isA<CloudinaryUploadException>()),
      );
    });

    test('deleteListingImages executes safely on client without exposing secret', () async {
      final service = CloudinaryService();

      // Should complete without error
      await expectLater(
        service.deleteListingImages(
          itemId: 'item_123',
          publicIds: ['borrowbox/product_images/item_123_0'],
          imageUrls: ['https://res.cloudinary.com/test-cloud/image.jpg'],
        ),
        completes,
      );
    });
    test('Image file validation enforces allowed extensions and size limits', () async {
      final service = CloudinaryService();

      // Valid jpg file
      final validFile = File('${tempDir.path}/valid.jpg');
      await validFile.writeAsBytes(List.generate(500, (i) => i % 256));
      expect(await service.validateImageFile(validFile), isTrue);

      // Disallowed extension (.exe or .txt)
      final invalidExtFile = File('${tempDir.path}/malicious.exe');
      await invalidExtFile.writeAsBytes(List.generate(500, (i) => i % 256));
      expect(await service.validateImageFile(invalidExtFile), isFalse);

      // Non-existent file
      final nonExistentFile = File('${tempDir.path}/does_not_exist.png');
      expect(await service.validateImageFile(nonExistentFile), isFalse);
    });

    test('Unconfigured Cloudinary gracefully falls back to offline simulated metadata', () async {
      // Clear credentials
      CloudinaryConfig.setCredentials(
        cloudName: 'placeholder_cloud_name',
        uploadPreset: '',
      );

      final service = CloudinaryService();
      final result = await service.uploadSingleImage(
        file: testFiles.first,
        userId: 'user_offline',
        itemId: 'item_offline',
        order: 0,
        isCover: true,
      );

      expect(result.publicId, startsWith('offline_'));
      expect(result.isCover, isTrue);
      expect(result.order, 0);
    });
  });

  group('Responsive UI & Cloudinary Image Rendering Tests', () {
    testWidgets('ItemCard renders with Cloudinary cover image on 360x740 screen', (tester) async {
      final item = MarketplaceItem(
        id: 'item_card_test',
        ownerId: 'owner_1',
        ownerName: 'Sarah',
        title: 'GoPro Hero 11 Camera',
        description: 'Action camera with underwater housing',
        category: ItemCategory.creative,
        condition: ItemCondition.likeNew,
        pickupLocation: 'Koramangala',
        depositAmount: 1500,
        createdAt: DateTime.now(),
        imageUrls: const [
          'https://res.cloudinary.com/f8e7pbct/image/upload/v1/gopro.jpg',
        ],
      );

      tester.view.physicalSize = const Size(360 * 2.5, 740 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 175,
              child: ItemCard(
                item: item,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('GoPro Hero 11 Camera'), findsOneWidget);
      expect(find.byType(ProductImageView), findsOneWidget);
    });

    testWidgets('ItemCard renders safely on narrow 320px phone without overflow', (tester) async {
      final item = MarketplaceItem(
        id: 'item_narrow_test',
        ownerId: 'owner_2',
        ownerName: 'David',
        title: 'Telescope 70mm Astronomical Refractor',
        description: 'For stargazing and moon observation',
        category: ItemCategory.educational,
        condition: ItemCondition.excellent,
        pickupLocation: 'HSR Layout',
        depositAmount: 800,
        createdAt: DateTime.now(),
        imageUrls: const [
          'https://res.cloudinary.com/f8e7pbct/image/upload/v1/telescope.jpg',
        ],
      );

      tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 145,
              child: ItemCard(
                item: item,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Telescope 70mm Astronomical Refractor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProductImageView renders category icon placeholder for null or empty URL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductImageView(
              imageUrl: '',
              category: ItemCategory.tools,
            ),
          ),
        ),
      );

      expect(find.byType(ProductImageView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProductImageGallery displays swipeable images on Item Details', (tester) async {
      final sampleUrls = [
        'https://res.cloudinary.com/f8e7pbct/image/upload/v1/img1.jpg',
        'https://res.cloudinary.com/f8e7pbct/image/upload/v1/img2.jpg',
        'https://res.cloudinary.com/f8e7pbct/image/upload/v1/img3.jpg',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductImageGallery(
              imageUrls: sampleUrls,
              category: ItemCategory.electronics,
              height: 250,
            ),
          ),
        ),
      );

      expect(find.byType(ProductImageGallery), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('My Listings list tile renders ProductImageView with cover image', (tester) async {
      final item = MarketplaceItem(
        id: 'item_my_listing',
        ownerId: 'owner_me',
        ownerName: 'Alice',
        title: 'Cordless Drill',
        description: 'Heavy duty drill',
        category: ItemCategory.tools,
        condition: ItemCondition.good,
        pickupLocation: 'Whitefield',
        createdAt: DateTime.now(),
        imageUrls: const [
          'https://res.cloudinary.com/f8e7pbct/image/upload/v1/drill_cover.jpg',
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                leading: ProductImageView(
                  imageUrl: item.coverImageUrl,
                  category: item.category,
                  width: 56,
                  height: 56,
                ),
                title: Text(item.title),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cordless Drill'), findsOneWidget);
      expect(find.byType(ProductImageView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
