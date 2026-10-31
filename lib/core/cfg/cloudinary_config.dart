// Dart Imports
import 'dart:io' show Platform;

/// Centralized configuration for Cloudinary image uploads and transformations.
///
/// Cloudinary Cloud Name and Unsigned Upload Preset are loaded securely from
/// compile-time environment variables (`--dart-define`), process environment,
/// or runtime configuration.
///
/// NOTE: The Cloudinary API Secret is NEVER included or exposed in client code.
class CloudinaryConfig {
  CloudinaryConfig._();

  // Environment variable names
  static const String envCloudNameKey = 'CLOUDINARY_CLOUD_NAME';
  static const String envUploadPresetKey = 'CLOUDINARY_UPLOAD_PRESET';
  static const String envFolderKey = 'CLOUDINARY_FOLDER';

  // Read compile-time dart-defines
  static const String _dartDefineCloudName =
      String.fromEnvironment(envCloudNameKey, defaultValue: '');
  static const String _dartDefineUploadPreset =
      String.fromEnvironment(envUploadPresetKey, defaultValue: '');
  static const String _dartDefineFolder =
      String.fromEnvironment(envFolderKey, defaultValue: '');

  // In-memory overrides (for tests and dynamic initialization)
  static String? _overrideCloudName;
  static String? _overrideUploadPreset;
  static String? _overrideFolder;

  // Fallback defaults for BorrowBox Cloudinary configuration
  static const String defaultCloudName = "f8e7pbct";
  static const String defaultUploadPreset = "borrowbox_product_preset";
  static const String defaultFolder = "borrowbox/product_images";

  /// The active Cloudinary Cloud Name
  static String get cloudName {
    if (_overrideCloudName != null && _overrideCloudName!.isNotEmpty) {
      return _overrideCloudName!;
    }
    if (_dartDefineCloudName.isNotEmpty) {
      return _dartDefineCloudName;
    }
    try {
      final envVal = Platform.environment[envCloudNameKey];
      if (envVal != null && envVal.isNotEmpty) return envVal;
    } catch (_) {}
    return defaultCloudName;
  }

  /// The active Unsigned Upload Preset
  static String get uploadPreset {
    if (_overrideUploadPreset != null && _overrideUploadPreset!.isNotEmpty) {
      return _overrideUploadPreset!;
    }
    if (_dartDefineUploadPreset.isNotEmpty) {
      return _dartDefineUploadPreset;
    }
    try {
      final envVal = Platform.environment[envUploadPresetKey];
      if (envVal != null && envVal.isNotEmpty) return envVal;
    } catch (_) {}
    return defaultUploadPreset;
  }

  /// The dedicated Cloudinary directory for BorrowBox product images
  static String get folder {
    if (_overrideFolder != null && _overrideFolder!.isNotEmpty) {
      return _overrideFolder!;
    }
    if (_dartDefineFolder.isNotEmpty) {
      return _dartDefineFolder;
    }
    try {
      final envVal = Platform.environment[envFolderKey];
      if (envVal != null && envVal.isNotEmpty) return envVal;
    } catch (_) {}
    return defaultFolder;
  }

  /// Returns true if valid Cloudinary credentials have been configured
  static bool get isConfigured {
    final cName = cloudName;
    final preset = uploadPreset;
    return cName.isNotEmpty &&
        preset.isNotEmpty &&
        cName != "borrowbox-demo" &&
        cName != "placeholder_cloud_name";
  }

  /// Override configuration dynamically (used in unit tests or setup screens)
  static void setCredentials({
    String? cloudName,
    String? uploadPreset,
    String? folder,
  }) {
    _overrideCloudName = cloudName;
    _overrideUploadPreset = uploadPreset;
    _overrideFolder = folder;
  }

  /// Reset overrides back to environment defaults
  static void resetOverrides() {
    _overrideCloudName = null;
    _overrideUploadPreset = null;
    _overrideFolder = null;
  }

  /// The REST API endpoint for unsigned multipart uploads
  static Uri get uploadApiUri =>
      Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

  // Constraints & Restrictions
  static const int maxImagesPerListing = 5;
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB limit before compression
  static const List<String> allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

  // Image optimization parameters
  static const int targetCompressionWidth = 1280;
  static const int targetCompressionHeight = 1280;
  static const int targetCompressionQuality = 80;

  /// Generate a mobile-optimized Cloudinary delivery URL with dynamic transformation
  ///
  /// Examples:
  /// - Automatic WebP/AVIF format selection (`f_auto`)
  /// - Quality optimization (`q_auto`)
  /// - Responsive downscaling (`w_600,c_limit`)
  static String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    int? quality,
    bool autoFormat = true,
  }) {
    if (!originalUrl.contains("cloudinary.com/")) {
      return originalUrl;
    }

    final uploadMarker = "/image/upload/";
    final index = originalUrl.indexOf(uploadMarker);
    if (index == -1) return originalUrl;

    final List<String> transforms = [];
    if (autoFormat) transforms.add("f_auto");
    transforms.add("q_auto${quality != null ? ':$quality' : ''}");

    if (width != null && height != null) {
      transforms.add("w_$width,h_$height,c_fill");
    } else if (width != null) {
      transforms.add("w_$width,c_limit");
    } else if (height != null) {
      transforms.add("h_$height,c_limit");
    }

    final transformString = "${transforms.join(',')}/";
    final before = originalUrl.substring(0, index + uploadMarker.length);
    final after = originalUrl.substring(index + uploadMarker.length);

    // If transforms are already present, avoid stacking duplicates
    if (after.startsWith("f_auto") || after.startsWith("q_auto") || after.startsWith("w_")) {
      return originalUrl;
    }

    return "$before$transformString$after";
  }
}
