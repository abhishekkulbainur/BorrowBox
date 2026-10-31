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

  List<String> get photoUrls => imageUrls;
  bool get isFree => depositAmount == null || depositAmount == 0;
  double? get rentalPricePerDay =>
      depositAmount != null && depositAmount! > 0
          ? (depositAmount! / 10.0)
          : null;
}
