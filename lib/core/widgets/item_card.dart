// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/widgets/status_badge.dart';

class ItemCard extends StatelessWidget {
  final MarketplaceItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
  });

  IconData _getCategoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.tools:
        return Symbols.build;
      case ItemCategory.electronics:
        return Symbols.devices;
      case ItemCategory.books:
        return Symbols.menu_book;
      case ItemCategory.sports:
        return Symbols.sports_tennis;
      case ItemCategory.household:
        return Symbols.home;
      case ItemCategory.travel:
        return Symbols.camping;
      case ItemCategory.calculators:
        return Symbols.calculate;
      case ItemCategory.creative:
        return Symbols.photo_camera;
      case ItemCategory.games:
        return Symbols.casino;
      default:
        return Symbols.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image/Icon Placeholder banner
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(40),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _getCategoryIcon(item.category),
                      size: 48,
                      color: theme.colorScheme.primary.withAlpha(180),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: StatusBadge.availability(item.availability),
                  ),
                  if (onFavoriteToggle != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Icon(
                          item.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: item.isFavorite ? Colors.red : theme.colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        onPressed: onFavoriteToggle,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.categoryDisplay,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      StatusBadge.condition(item.condition),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Symbols.location_on,
                        size: 14,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.pickupLocation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Up to ${item.maxDurationDays} days",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      if (item.depositAmount != null)
                        Text(
                          "₹${item.depositAmount!.toInt()} dep.",
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                        )
                      else
                        Text(
                          "Free loan",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
