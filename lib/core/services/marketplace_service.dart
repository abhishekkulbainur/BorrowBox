// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/legacy.dart';

// Project Imports
import 'package:lendnborrow/core/models/marketplace_item.dart';

class MarketplaceService extends ChangeNotifier {
  static final MarketplaceService _instance = MarketplaceService._internal();
  factory MarketplaceService() => _instance;
  MarketplaceService._internal() {
    _initSeedListings();
  }

  final List<MarketplaceItem> _items = [];
  final Set<String> _favoriteItemIds = {};

  List<MarketplaceItem> get allItems => List.unmodifiable(_items);

  void _initSeedListings() {
    _items.addAll([
      MarketplaceItem(
        id: "item_calc_01",
        ownerId: "user_snehal",
        ownerName: "Snehal Mascarenhas",
        ownerRating: 5.0,
        title: "Casio fx-991EX ClassWiz Scientific Calculator",
        description:
            "Original dual-power natural textbook display scientific calculator with matrix and equation solver. Perfect for mid-terms or finals.",
        category: ItemCategory.calculators,
        condition: ItemCondition.likeNew,
        pickupLocation: "Central Campus / Block B",
        maxDurationDays: 5,
        depositAmount: null,
        availability: ItemAvailability.available,
        imageUrls: [],
        terms: "Please return with protective slide-on hard case intact.",
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        communityName: "Campus Exchange Hub",
        favoriteCount: 8,
      ),
      MarketplaceItem(
        id: "item_drill_02",
        ownerId: "user_abhishek",
        ownerName: "Abhishek Kulbainur",
        ownerRating: 4.9,
        title: "Bosch 18V Cordless Drill & Screwdriver Kit",
        description:
            "Powerful two-speed cordless drill with battery charger, masonry and wood bits included. Ideal for furniture assembly or apartment DIY projects.",
        category: ItemCategory.tools,
        condition: ItemCondition.excellent,
        pickupLocation: "Greenfield Heights, Tower 3",
        maxDurationDays: 3,
        depositAmount: 500,
        availability: ItemAvailability.available,
        imageUrls: [],
        terms: "Use responsibly; wear eye protection during drilling.",
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        communityName: "Greenfield Heights Resident Association",
        favoriteCount: 15,
      ),
      MarketplaceItem(
        id: "item_tent_03",
        ownerId: "user_snehal",
        ownerName: "Snehal Mascarenhas",
        ownerRating: 5.0,
        title: "Quechua 3-Person Waterproof Camping Tent",
        description:
            "Easy 10-minute pitch dome tent with double roof and ventilation. Waterproof and wind-resistant up to 50 km/h.",
        category: ItemCategory.travel,
        condition: ItemCondition.excellent,
        pickupLocation: "South Koramangala",
        maxDurationDays: 7,
        depositAmount: 1000,
        availability: ItemAvailability.available,
        imageUrls: [],
        terms: "Please pack completely dry to prevent mildew.",
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        communityName: "Downtown Sharing Circle",
        favoriteCount: 22,
      ),
      MarketplaceItem(
        id: "item_hub_04",
        ownerId: "user_abhishek",
        ownerName: "Abhishek Kulbainur",
        ownerRating: 4.9,
        title: "Anker USB-C Hub 7-in-1 (4K HDMI, SD & Power)",
        description:
            "Aluminum 7-in-1 USB-C adapter with 4K@60Hz HDMI, 100W Power Delivery, SD/microSD slots, and 2x USB-A 3.0 ports. Perfect for seminars and conferences.",
        category: ItemCategory.electronics,
        condition: ItemCondition.likeNew,
        pickupLocation: "Tech Valley Co-Working",
        maxDurationDays: 4,
        depositAmount: null,
        availability: ItemAvailability.available,
        imageUrls: [],
        terms: "Handle connector with care.",
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        communityName: "Tech Valley Maker Space",
        favoriteCount: 12,
      ),
      MarketplaceItem(
        id: "item_book_05",
        ownerId: "user_snehal",
        ownerName: "Snehal Mascarenhas",
        ownerRating: 5.0,
        title: "Engineering Mechanics: Statics & Dynamics (Meriam & Kraige)",
        description:
            "Standard reference textbook with solved practice problems. Clean pages with minimal pencil highlights.",
        category: ItemCategory.books,
        condition: ItemCondition.good,
        pickupLocation: "Library Plaza",
        maxDurationDays: 14,
        depositAmount: null,
        availability: ItemAvailability.available,
        imageUrls: [],
        terms: "No permanent pen or highlighter marks, please.",
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        communityName: "Campus Exchange Hub",
        favoriteCount: 5,
      ),
      MarketplaceItem(
        id: "item_badminton_06",
        ownerId: "user_abhishek",
        ownerName: "Abhishek Kulbainur",
        ownerRating: 4.9,
        title: "Yonex Astrox Badminton Racket Pair with Cover",
        description:
            "Two high-tension graphite rackets with full padded shoulder case. Great for weekend badminton courts.",
        category: ItemCategory.sports,
        condition: ItemCondition.good,
        pickupLocation: "Sports Complex Gate 1",
        maxDurationDays: 2,
        depositAmount: null,
        availability: ItemAvailability.available,
        imageUrls: [],
        terms: "Do not play with heavy plastic shuttles that break strings.",
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        communityName: "Greenfield Heights Resident Association",
        favoriteCount: 19,
      ),
      MarketplaceItem(
        id: "item_catan_07",
        ownerId: "user_snehal",
        ownerName: "Snehal Mascarenhas",
        ownerRating: 5.0,
        title: "Catan Board Game (5th Edition Complete Box)",
        description:
            "The classic strategy board game of resource trading and settlement building. All resource cards, hex tiles, and dice counted and sealed in zip pouches.",
        category: ItemCategory.games,
        condition: ItemCondition.excellent,
        pickupLocation: "Community Hall Lounge",
        maxDurationDays: 4,
        depositAmount: null,
        availability: ItemAvailability.available,
        imageUrls: [],
        terms: "Keep away from food and liquid beverages during play.",
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        communityName: "Downtown Sharing Circle",
        favoriteCount: 31,
      ),
      MarketplaceItem(
        id: "item_camera_08",
        ownerId: "user_abhishek",
        ownerName: "Abhishek Kulbainur",
        ownerRating: 4.9,
        title: "Canon EOS DSLR Camera with 18-55mm IS Lens & Bag",
        description:
            "24.2 MP DSLR with dual pixel autofocus, 64GB high-speed SD card, battery, and charger. Ideal for college video presentations, portfolio shoots, or family events.",
        category: ItemCategory.creative,
        condition: ItemCondition.excellent,
        pickupLocation: "Media Lab Reception",
        maxDurationDays: 3,
        depositAmount: 1500,
        availability: ItemAvailability.available,
        imageUrls: [],
        terms: "Keep lens cap on when not shooting; use neck strap at all times.",
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        communityName: "Tech Valley Maker Space",
        favoriteCount: 44,
      ),
    ]);
  }

  List<MarketplaceItem> searchAndFilter({
    String query = "",
    ItemCategory category = ItemCategory.all,
    ItemCondition? condition,
    bool onlyAvailable = false,
    String? communityId,
  }) {
    return _items.where((item) {
      if (category != ItemCategory.all && item.category != category) {
        return false;
      }
      if (condition != null && item.condition != condition) {
        return false;
      }
      if (onlyAvailable && item.availability != ItemAvailability.available) {
        return false;
      }
      if (communityId != null && item.communityId != communityId) {
        return false;
      }
      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchDesc = item.description.toLowerCase().contains(q);
        final matchLoc = item.pickupLocation.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchLoc) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  MarketplaceItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  void toggleFavorite(String itemId) {
    if (_favoriteItemIds.contains(itemId)) {
      _favoriteItemIds.remove(itemId);
    } else {
      _favoriteItemIds.add(itemId);
    }
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final current = _items[index];
      final isFav = _favoriteItemIds.contains(itemId);
      _items[index] = current.copyWith(
        isFavorite: isFav,
        favoriteCount: isFav ? current.favoriteCount + 1 : current.favoriteCount - 1,
      );
    }
    notifyListeners();
  }

  bool isFavorite(String itemId) => _favoriteItemIds.contains(itemId);

  List<MarketplaceItem> getFavoriteItems() {
    return _items.where((i) => _favoriteItemIds.contains(i.id)).toList();
  }

  List<MarketplaceItem> getItemsByOwner(String ownerId) {
    return _items.where((i) => i.ownerId == ownerId).toList();
  }

  void addListing(MarketplaceItem item) {
    _items.insert(0, item);
    notifyListeners();
  }

  void updateAvailability(String itemId, ItemAvailability status) {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(availability: status);
      notifyListeners();
    }
  }

  bool deleteListing(String itemId, {String? actorId}) {
    final item = getItemById(itemId);
    if (item == null) return false;
    if (actorId != null && item.ownerId != actorId) {
      return false; // Unauthorized: Only the owner can delete their listing
    }
    _items.removeWhere((i) => i.id == itemId);
    _favoriteItemIds.remove(itemId);
    notifyListeners();
    return true;
  }
}

final marketplaceServiceProvider = ChangeNotifierProvider<MarketplaceService>((ref) {
  return MarketplaceService();
});
