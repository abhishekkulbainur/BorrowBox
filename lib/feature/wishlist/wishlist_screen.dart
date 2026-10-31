// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/utils/responsive.dart';
import 'package:lendnborrow/core/widgets/empty_state_view.dart';
import 'package:lendnborrow/core/widgets/item_card.dart';
import 'package:lendnborrow/feature/explore/item_details_screen.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  static const String path = "/wishlist";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketplace = ref.watch(marketplaceServiceProvider);
    final favorites = marketplace.getFavoriteItems();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Saved Wishlist (${favorites.length})",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: favorites.isEmpty
          ? const EmptyStateView(
              icon: Symbols.favorite_border,
              title: "Your Wishlist is Empty",
              message:
                  "Browse the marketplace and tap the heart icon on any item you'd like to save for future borrowing.",
            )
          : GridView.builder(
              padding: Responsive.horizontalPadding(context).copyWith(
                top: 16,
                bottom: 24,
              ),
              gridDelegate: Responsive.gridDelegate(context),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return ItemCard(
                  item: item,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ItemDetailsScreen(item: item),
                      ),
                    );
                  },
                  onFavoriteToggle: () {
                    marketplace.toggleFavorite(item.id);
                  },
                );
              },
            ),
    );
  }
}
