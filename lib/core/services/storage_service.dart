// Dart Imports
import 'dart:developer' as developer;
import 'dart:io';

// Package Imports
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

// Project Imports
import 'package:lendnborrow/core/services/firebase_service.dart';

import 'package:flutter/foundation.dart';

final storageServiceProvider = ChangeNotifierProvider<StorageService>((ref) {
  return StorageService();
});

class StorageService extends ChangeNotifier {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final ImagePicker _picker = ImagePicker();
  static const int maxImagesPerListing = 5;
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  /// Pick single or multiple product images from device photo gallery
  Future<List<File>> pickImagesFromGallery({int currentCount = 0}) async {
    try {
      final int allowedCount = maxImagesPerListing - currentCount;
      if (allowedCount <= 0) return [];

      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        limit: allowedCount,
      );

      final List<File> files = [];
      for (final xf in pickedFiles.take(allowedCount)) {
        final file = File(xf.path);
        if (await _validateImageFile(file)) {
          files.add(file);
        }
      }
      return files;
    } catch (e) {
      developer.log("Error picking images from gallery: $e", name: "StorageService");
      return [];
    }
  }

  /// Capture a new photograph directly with camera
  Future<File?> captureImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo == null) return null;
      final file = File(photo.path);
      if (await _validateImageFile(file)) {
        return file;
      }
      return null;
    } catch (e) {
      developer.log("Error capturing photo from camera: $e", name: "StorageService");
      return null;
    }
  }

  /// Validate image format and maximum allowable size
  Future<bool> _validateImageFile(File file) async {
    if (!file.existsSync()) return false;
    final int size = await file.length();
    if (size > maxFileSizeBytes) {
      developer.log("Image exceeds maximum size limit (10MB): ${file.path}", name: "StorageService");
      return false;
    }
    final ext = p.extension(file.path).toLowerCase();
    const validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    return validExtensions.contains(ext);
  }

  /// Compress image before network transmission to conserve bandwidth & storage
  Future<File> compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        "compressed_${const Uuid().v4().substring(0, 8)}.jpg",
      );

      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1280,
        minHeight: 1280,
        format: CompressFormat.jpeg,
      );

      if (compressed != null) {
        return File(compressed.path);
      }
      return file;
    } catch (e) {
      // In test/local environments where platform channels may not be bound, return original
      return file;
    }
  }

  /// Upload a list of product photographs to Firebase Storage
  /// Path: users/{userId}/items/{itemId}/images/{imageId}.jpg
  Future<List<String>> uploadListingImages({
    required String userId,
    required String itemId,
    required List<File> files,
    void Function(double overallProgress, int currentIndex, int totalCount)? onProgress,
  }) async {
    final List<String> downloadUrls = [];
    final storage = FirebaseService().storage;

    // Check if Firebase Storage is initialized
    final bool hasLiveStorage = FirebaseService().isInitialized && storage != null;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      onProgress?.call(i / files.length, i + 1, files.length);

      final compressedFile = await compressImage(file);
      final imageId = "img_${const Uuid().v4().substring(0, 8)}";

      if (hasLiveStorage) {
        try {
          final storageRef = storage
              .ref()
              .child('users')
              .child(userId)
              .child('items')
              .child(itemId)
              .child('images')
              .child('$imageId.jpg');

          final uploadTask = storageRef.putFile(
            compressedFile,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'userId': userId,
                'itemId': itemId,
              },
            ),
          );

          final snapshot = await uploadTask.whenComplete(() {});
          final url = await snapshot.ref.getDownloadURL();
          downloadUrls.add(url);
        } catch (e) {
          developer.log("Failed to upload image $i to Firebase Storage: $e", name: "StorageService");
          // Fallback to local path so the listing still preserves user photo reference
          downloadUrls.add(compressedFile.path);
        }
      } else {
        // Local / Offline / Test environment mode
        downloadUrls.add(compressedFile.path);
      }
    }

    onProgress?.call(1.0, files.length, files.length);
    return downloadUrls;
  }

  /// Delete images associated with an item from Firebase Storage
  Future<void> deleteItemImages({
    required String userId,
    required String itemId,
    required List<String> imageUrls,
  }) async {
    final storage = FirebaseService().storage;
    if (!FirebaseService().isInitialized || storage == null) return;

    for (final url in imageUrls) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        try {
          final ref = storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          developer.log("Error deleting image from Storage: $e", name: "StorageService");
        }
      }
    }
  }
}
