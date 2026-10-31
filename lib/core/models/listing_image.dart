// Dart Imports
import 'dart:convert';

/// Represents a single product image stored in Cloudinary with rich metadata
/// persisted directly to Cloud Firestore.
class ListingImage {
  /// The HTTPS delivery URL on Cloudinary CDN
  final String secureUrl;

  /// The unique public identifier on Cloudinary (e.g., borrowbox/product_images/item_123_0)
  final String publicId;

  /// Original width in pixels where available
  final int? width;

  /// Original height in pixels where available
  final int? height;

  /// Image file extension/format (e.g., jpg, png, webp)
  final String? format;

  /// File size in bytes
  final int? bytes;

  /// Zero-based presentation order in listing carousel
  final int order;

  /// Flag indicating if this image is selected as the primary marketplace cover
  final bool isCover;

  /// Timestamp of upload
  final DateTime? createdAt;

  const ListingImage({
    required this.secureUrl,
    this.publicId = "",
    this.width,
    this.height,
    this.format,
    this.bytes,
    this.order = 0,
    this.isCover = false,
    this.createdAt,
  });

  /// True if this image has a registered Cloudinary public ID
  bool get hasPublicId => publicId.trim().isNotEmpty;

  /// True if the URL points to Cloudinary's media delivery network
  bool get isCloudinaryUrl =>
      secureUrl.contains("cloudinary.com") || secureUrl.contains("res.cloudinary.com");

  ListingImage copyWith({
    String? secureUrl,
    String? publicId,
    int? width,
    int? height,
    String? format,
    int? bytes,
    int? order,
    bool? isCover,
    DateTime? createdAt,
  }) {
    return ListingImage(
      secureUrl: secureUrl ?? this.secureUrl,
      publicId: publicId ?? this.publicId,
      width: width ?? this.width,
      height: height ?? this.height,
      format: format ?? this.format,
      bytes: bytes ?? this.bytes,
      order: order ?? this.order,
      isCover: isCover ?? this.isCover,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serialize to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'secure_url': secureUrl,
      'public_id': publicId,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (format != null) 'format': format,
      if (bytes != null) 'bytes': bytes,
      'order': order,
      'is_cover': isCover,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Factory deserializer from Firestore Map with safe fallbacks
  factory ListingImage.fromMap(
    Map<String, dynamic> map, {
    int fallbackOrder = 0,
    bool fallbackCover = false,
  }) {
    DateTime? parsedCreatedAt;
    final rawDate = map['created_at'] ?? map['createdAt'];
    if (rawDate is String) {
      parsedCreatedAt = DateTime.tryParse(rawDate);
    }

    return ListingImage(
      secureUrl: (map['secure_url'] ??
              map['secureUrl'] ??
              map['url'] ??
              "")
          .toString(),
      publicId: (map['public_id'] ?? map['publicId'] ?? "").toString(),
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      format: map['format']?.toString(),
      bytes: (map['bytes'] as num?)?.toInt(),
      order: (map['order'] as num?)?.toInt() ?? fallbackOrder,
      isCover: (map['is_cover'] as bool?) ??
          (map['isCover'] as bool?) ??
          fallbackCover,
      createdAt: parsedCreatedAt,
    );
  }

  /// Backward-compatible factory from legacy plain URL string
  factory ListingImage.fromUrl(
    String url, {
    int order = 0,
    bool isCover = false,
  }) {
    return ListingImage(
      secureUrl: url,
      publicId: "",
      order: order,
      isCover: isCover,
    );
  }

  String toJson() => json.encode(toMap());

  factory ListingImage.fromJson(String source) =>
      ListingImage.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ListingImage(order: $order, isCover: $isCover, publicId: $publicId, secureUrl: $secureUrl)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListingImage &&
        other.secureUrl == secureUrl &&
        other.publicId == publicId &&
        other.order == order &&
        other.isCover == isCover;
  }

  @override
  int get hashCode =>
      secureUrl.hashCode ^ publicId.hashCode ^ order.hashCode ^ isCover.hashCode;
}
