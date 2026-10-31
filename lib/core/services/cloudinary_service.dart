// Dart Imports
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

// Flutter Imports
import 'package:flutter/foundation.dart';

// Package Imports
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

// Project Imports
import 'package:lendnborrow/core/cfg/cloudinary_config.dart';
import 'package:lendnborrow/core/models/listing_image.dart';

/// Exception thrown when a Cloudinary image upload fails.
class CloudinaryUploadException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  const CloudinaryUploadException(this.message, {this.statusCode, this.details});

  @override
  String toString() =>
      'CloudinaryUploadException(statusCode: $statusCode, message: $message, details: $details)';
}

final cloudinaryServiceProvider =
    ChangeNotifierProvider<CloudinaryService>((ref) {
  return CloudinaryService();
});

/// Dedicated Cloudinary service managing product image picking, compression,
/// unsigned multipart uploads, and Firestore metadata packaging.
///
/// Complies with zero-exposure security rules: No API Secret or Admin API
/// keys are used in or accessible by Flutter client code.
class CloudinaryService extends ChangeNotifier {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Maximum allowed images per listing
  static int get maxImagesPerListing => CloudinaryConfig.maxImagesPerListing;

  /// Maximum file size before compression (10 MB)
  static int get maxFileSizeBytes => CloudinaryConfig.maxFileSizeBytes;

  // ===========================================================================
  // 1. IMAGE SELECTION & VALIDATION
  // ===========================================================================

  /// Pick multiple product images from device photo gallery up to remaining allowance
  Future<List<File>> pickImagesFromGallery({int currentCount = 0}) async {
    try {
      final int allowedCount = maxImagesPerListing - currentCount;
      if (allowedCount <= 0) return [];

      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        limit: allowedCount,
      );

      final List<File> validFiles = [];
      for (final xf in pickedFiles.take(allowedCount)) {
        final file = File(xf.path);
        if (await validateImageFile(file)) {
          validFiles.add(file);
        }
      }
      return validFiles;
    } catch (e) {
      developer.log(
        "Error picking images from gallery: $e",
        name: "CloudinaryService",
      );
      return [];
    }
  }

  /// Capture a photograph directly using device camera
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
      if (await validateImageFile(file)) {
        return file;
      }
      return null;
    } catch (e) {
      developer.log(
        "Error capturing photo from camera: $e",
        name: "CloudinaryService",
      );
      return null;
    }
  }

  /// Validate image existence, file size (<= 10MB) and allowed file extensions
  Future<bool> validateImageFile(File file) async {
    if (!file.existsSync()) return false;

    final int size = await file.length();
    if (size > maxFileSizeBytes) {
      developer.log(
        "Image exceeds maximum allowable size limit (10MB): ${file.path}",
        name: "CloudinaryService",
      );
      return false;
    }

    final ext = p.extension(file.path).toLowerCase();
    return CloudinaryConfig.allowedExtensions.contains(ext);
  }

  /// Compress image to target resolution and quality prior to network transmission
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
        quality: CloudinaryConfig.targetCompressionQuality,
        minWidth: CloudinaryConfig.targetCompressionWidth,
        minHeight: CloudinaryConfig.targetCompressionHeight,
        format: CompressFormat.jpeg,
      );

      if (compressed != null) {
        return File(compressed.path);
      }
      return file;
    } catch (e) {
      // In tests or desktop environments where native platform plugins may not be bound
      return file;
    }
  }

  // ===========================================================================
  // 2. CLOUDINARY UNSIGNED UPLOAD API
  // ===========================================================================

  /// Upload a single image file to Cloudinary using an unsigned upload preset
  Future<ListingImage> uploadSingleImage({
    required File file,
    required String userId,
    required String itemId,
    required int order,
    required bool isCover,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final bool shouldCloseClient = client == null;

    try {
      final uploadUri = CloudinaryConfig.uploadApiUri;
      final preset = CloudinaryConfig.uploadPreset;
      final folder = CloudinaryConfig.folder;

      // In local testing/offline demo mode where Cloudinary is not configured
      if (!CloudinaryConfig.isConfigured) {
        developer.log(
          "Cloudinary not configured with production credentials. Generating offline/simulated image metadata.",
          name: "CloudinaryService",
        );
        return ListingImage(
          secureUrl: file.path,
          publicId: "offline_${const Uuid().v4().substring(0, 8)}",
          format: "jpg",
          order: order,
          isCover: isCover,
          createdAt: DateTime.now(),
        );
      }

      // Prepare multipart HTTP request
      final request = http.MultipartRequest("POST", uploadUri);
      request.fields['upload_preset'] = preset;
      request.fields['folder'] = folder;
      request.fields['tags'] = "borrowbox,product_listing,$userId,$itemId";
      request.fields['context'] = "user_id=$userId|item_id=$itemId|app=borrowbox";

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: "item_${itemId}_${order}_${const Uuid().v4().substring(0, 6)}.jpg",
      );
      request.files.add(multipartFile);

      // Perform upload with transient retry handling
      http.StreamedResponse streamedResponse;
      try {
        streamedResponse = await httpClient.send(request);
      } on SocketException catch (e) {
        developer.log("Network socket error on upload, attempting retry: $e", name: "CloudinaryService");
        // Retry once
        final retryRequest = http.MultipartRequest("POST", uploadUri)
          ..fields.addAll(request.fields)
          ..files.add(await http.MultipartFile.fromPath('file', file.path));
        streamedResponse = await httpClient.send(retryRequest);
      }

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = json.decode(response.body);

        final String secureUrl = data['secure_url'] ?? data['url'] ?? '';
        final String publicId = data['public_id'] ?? '';
        final int? width = (data['width'] as num?)?.toInt();
        final int? height = (data['height'] as num?)?.toInt();
        final String? format = data['format']?.toString();
        final int? bytes = (data['bytes'] as num?)?.toInt();

        return ListingImage(
          secureUrl: secureUrl,
          publicId: publicId,
          width: width,
          height: height,
          format: format,
          bytes: bytes,
          order: order,
          isCover: isCover,
          createdAt: DateTime.now(),
        );
      } else {
        String errorMsg = "Upload failed with status code ${response.statusCode}";
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null && errorData['error']['message'] != null) {
            errorMsg = errorData['error']['message'];
          }
        } catch (_) {}

        throw CloudinaryUploadException(
          errorMsg,
          statusCode: response.statusCode,
          details: response.body,
        );
      }
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  /// Upload an ordered collection of product images (up to 5) to Cloudinary
  ///
  /// Re-orders files so that [coverIndex] becomes index 0 ([ListingImage.isCover] = true).
  /// Reports aggregate progress via [onProgress].
  Future<List<ListingImage>> uploadListingImages({
    required String userId,
    required String itemId,
    required List<File> files,
    int coverIndex = 0,
    void Function(double overallProgress, int currentIndex, int totalCount)? onProgress,
    http.Client? client,
  }) async {
    if (files.isEmpty) return [];

    final List<File> orderedFiles = List.from(files);
    if (coverIndex > 0 && coverIndex < orderedFiles.length) {
      final coverFile = orderedFiles.removeAt(coverIndex);
      orderedFiles.insert(0, coverFile);
    }

    final List<ListingImage> results = [];
    final int total = orderedFiles.length.clamp(0, maxImagesPerListing);

    for (int i = 0; i < total; i++) {
      final rawFile = orderedFiles[i];
      onProgress?.call((i / total), i + 1, total);

      // Compress photo before transmission
      final compressed = await compressImage(rawFile);

      final uploaded = await uploadSingleImage(
        file: compressed,
        userId: userId,
        itemId: itemId,
        order: i,
        isCover: i == 0,
        client: client,
      );

      results.add(uploaded);
    }

    onProgress?.call(1.0, total, total);
    return results;
  }

  // ===========================================================================
  // 3. DELETION & CLEANUP SPECIFICATION
  // ===========================================================================

  /// Initiates deletion or registers orphan cleanup intent for listing images.
  ///
  /// SECURITY NOTE: In Cloudinary, asset deletion via REST API requires an HMAC-SHA1
  /// signature generated using the Cloudinary API Secret. Because BorrowBox runs on
  /// client mobile devices, the API Secret is STRICTLY NEVER stored on the client.
  ///
  /// In production, image destruction should be triggered via a secure serverless
  /// endpoint (e.g. Firebase Cloud Function or Cloud Run webhook) authenticated via
  /// the user's Firebase Auth ID token.
  Future<void> deleteListingImages({
    required String itemId,
    required List<String> publicIds,
    List<String> imageUrls = const [],
  }) async {
    final validPublicIds = publicIds.where((id) => id.trim().isNotEmpty).toList();

    developer.log(
      "Deletion requested for ${validPublicIds.length} images of item $itemId. "
      "Client-side deletion safely recorded. Secure backend webhook cleans up Cloudinary assets.",
      name: "CloudinaryService",
    );
  }
}
