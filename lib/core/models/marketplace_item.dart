import 'package:lendnborrow/core/models/listing_image.dart';

enum ItemCategory {
  all,
  tools,
  electronics,
  books,
  sports,
  household,
  travel,
  calculators,
  creative,
  games,
  furniture,
  gaming,
  kitchen,
  accessories,
  educational,
  other,
}

enum ItemCondition { likeNew, excellent, good, fair }

enum ItemAvailability { available, reserved, borrowed, deactivated }

class MarketplaceItem {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatarUrl;
  final double ownerRating;
  final String title;
  final String description;
  final ItemCategory category;
  final ItemCondition condition;
  final String pickupLocation;
  final int maxDurationDays;
  final double? depositAmount;
  final ItemAvailability availability;
  final List<String> imageUrls;
  final List<ListingImage>? imagesMeta;
  final String? terms;
  final DateTime createdAt;
  final String? communityId;
  final String? communityName;
  final int favoriteCount;
  final bool isFavorite;
  final bool isActive;

  const MarketplaceItem({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatarUrl,
    this.ownerRating = 5.0,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.pickupLocation,
    this.maxDurationDays = 7,
    this.depositAmount,
    this.availability = ItemAvailability.available,
    required this.imageUrls,
    this.imagesMeta,
    this.terms,
    required this.createdAt,
    this.communityId,
    this.communityName,
    this.favoriteCount = 0,
    this.isFavorite = false,
    this.isActive = true,
  });

  MarketplaceItem copyWith({
    String? id,
    String? title,
    String? description,
    ItemCategory? category,
    ItemCondition? condition,
    String? pickupLocation,
    int? maxDurationDays,
    double? depositAmount,
    ItemAvailability? availability,
    List<String>? imageUrls,
    List<ListingImage>? imagesMeta,
    String? terms,
    String? communityId,
    String? communityName,
    int? favoriteCount,
    bool? isFavorite,
    bool? isActive,
  }) {
    return MarketplaceItem(
      id: id ?? this.id,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerAvatarUrl: ownerAvatarUrl,
      ownerRating: ownerRating,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      maxDurationDays: maxDurationDays ?? this.maxDurationDays,
      depositAmount: depositAmount ?? this.depositAmount,
      availability: availability ?? this.availability,
      imageUrls: imageUrls ?? this.imageUrls,
      imagesMeta: imagesMeta ?? this.imagesMeta,
      terms: terms ?? this.terms,
      createdAt: createdAt,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isActive: isActive ?? this.isActive,
    );
  }

  String get categoryDisplay {
    switch (category) {
      case ItemCategory.all:
        return "All";
      case ItemCategory.tools:
        return "Tools & DIY";
      case ItemCategory.electronics:
        return "Electronics";
      case ItemCategory.books:
        return "Books & Notes";
      case ItemCategory.sports:
        return "Sports Equipment";
      case ItemCategory.household:
        return "Household";
      case ItemCategory.travel:
        return "Travel & Camping";
      case ItemCategory.calculators:
        return "Calculators";
      case ItemCategory.creative:
        return "Creative & Camera";
      case ItemCategory.games:
        return "Board Games";
      case ItemCategory.furniture:
        return "Furniture";
      case ItemCategory.gaming:
        return "Gaming & Consoles";
      case ItemCategory.kitchen:
        return "Kitchen Appliances";
      case ItemCategory.accessories:
        return "Accessories";
      case ItemCategory.educational:
        return "Educational Equipment";
      case ItemCategory.other:
        return "Others";
    }
  }

  String get conditionDisplay {
    switch (condition) {
      case ItemCondition.likeNew:
        return "Like New";
      case ItemCondition.excellent:
        return "Excellent";
      case ItemCondition.good:
        return "Good";
      case ItemCondition.fair:
        return "Fair";
    }
  }

  /// Ordered list of image URLs. Guaranteed backward-compatible.
  List<String> get photoUrls => imageUrls.isNotEmpty
      ? imageUrls
      : images.map((img) => img.secureUrl).toList();

  /// Rich Cloudinary image metadata objects.
  /// Falls back to constructing from [imageUrls] if [imagesMeta] was not stored.
  List<ListingImage> get images {
    if (imagesMeta != null && imagesMeta!.isNotEmpty) {
      return imagesMeta!;
    }
    return imageUrls.asMap().entries.map((entry) {
      return ListingImage.fromUrl(
        entry.value,
        order: entry.key,
        isCover: entry.key == 0,
      );
    }).toList();
  }

  /// Cover image URL for card thumbnails
  String? get coverImageUrl {
    if (imagesMeta != null && imagesMeta!.isNotEmpty) {
      final cover = imagesMeta!.firstWhere(
        (img) => img.isCover,
        orElse: () => imagesMeta!.first,
      );
      if (cover.secureUrl.isNotEmpty) return cover.secureUrl;
    }
    return imageUrls.isNotEmpty ? imageUrls.first : null;
  }

  bool get isFree => depositAmount == null || depositAmount == 0;
  double? get rentalPricePerDay =>
      depositAmount != null && depositAmount! > 0
          ? (depositAmount! / 10.0)
          : null;

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      if (ownerAvatarUrl != null) 'ownerAvatarUrl': ownerAvatarUrl,
      'ownerRating': ownerRating,
      'title': title,
      'description': description,
      'category': category.name,
      'condition': condition.name,
      'pickupLocation': pickupLocation,
      'maxDurationDays': maxDurationDays,
      if (depositAmount != null) 'depositAmount': depositAmount,
      'availability': availability.name,
      'imageUrls': imageUrls,
      if (imagesMeta != null)
        'imagesMeta': imagesMeta!.map((img) => img.toMap()).toList(),
      if (terms != null) 'terms': terms,
      'createdAt': createdAt.toIso8601String(),
      if (communityId != null) 'communityId': communityId,
      if (communityName != null) 'communityName': communityName,
      'favoriteCount': favoriteCount,
      'isFavorite': isFavorite,
      'isActive': isActive,
    };
  }

  factory MarketplaceItem.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawImagesMeta = map['imagesMeta'] ?? map['images_meta'];
    List<ListingImage>? parsedImagesMeta;
    if (rawImagesMeta is List) {
      parsedImagesMeta = rawImagesMeta
          .asMap()
          .entries
          .map((e) => ListingImage.fromMap(
                Map<String, dynamic>.from(e.value as Map),
                fallbackOrder: e.key,
                fallbackCover: e.key == 0,
              ))
          .toList();
    }

    final rawImageUrls = map['imageUrls'] ?? map['image_urls'];
    List<String> parsedUrls = [];
    if (rawImageUrls is List) {
      parsedUrls = List<String>.from(rawImageUrls);
    } else if (parsedImagesMeta != null) {
      parsedUrls = parsedImagesMeta.map((img) => img.secureUrl).toList();
    }

    return MarketplaceItem(
      id: id ?? (map['id'] ?? '').toString(),
      ownerId: (map['ownerId'] ?? map['owner_id'] ?? '').toString(),
      ownerName: (map['ownerName'] ?? map['owner_name'] ?? 'Community Member').toString(),
      ownerAvatarUrl: map['ownerAvatarUrl'] ?? map['owner_avatar_url'],
      ownerRating: (map['ownerRating'] ?? map['owner_rating'] as num?)?.toDouble() ?? 5.0,
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      category: ItemCategory.values.firstWhere(
        (c) => c.name == (map['category'] ?? ''),
        orElse: () => ItemCategory.other,
      ),
      condition: ItemCondition.values.firstWhere(
        (c) => c.name == (map['condition'] ?? ''),
        orElse: () => ItemCondition.good,
      ),
      pickupLocation: (map['pickupLocation'] ?? map['pickup_location'] ?? '').toString(),
      maxDurationDays: (map['maxDurationDays'] ?? map['max_duration_days'] as num?)?.toInt() ?? 7,
      depositAmount: (map['depositAmount'] ?? map['deposit_amount'] as num?)?.toDouble(),
      availability: ItemAvailability.values.firstWhere(
        (a) => a.name == (map['availability'] ?? ''),
        orElse: () => ItemAvailability.available,
      ),
      imageUrls: parsedUrls,
      imagesMeta: parsedImagesMeta,
      terms: map['terms'],
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : (map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      communityId: map['communityId'] ?? map['community_id'],
      communityName: map['communityName'] ?? map['community_name'],
      favoriteCount: (map['favoriteCount'] ?? map['favorite_count'] as num?)?.toInt() ?? 0,
      isFavorite: (map['isFavorite'] ?? map['is_favorite'] as bool?) ?? false,
      isActive: (map['isActive'] ?? map['is_active'] as bool?) ?? true,
    );
  }
}
