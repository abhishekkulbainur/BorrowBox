// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/widgets/product_image_view.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(60),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Product Image Banner with badges
            SizedBox(
              height: 116,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: ProductImageView(
                        imageUrl: item.coverImageUrl ??
                            (item.photoUrls.isNotEmpty
                                ? item.photoUrls.first
                                : null),
                        category: item.category,
                        fit: BoxFit.cover,
                      ),
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(60),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            item.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: item.isFavorite ? Colors.red : Colors.white,
                            size: 20,
                          ),
                          onPressed: onFavoriteToggle,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.categoryDisplay,
                          style: TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      StatusBadge.condition(item.condition),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Symbols.location_on,
                        size: 13,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.pickupLocation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      Text(
                        "Up to ${item.maxDurationDays}d",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      if (item.depositAmount != null)
                        Text(
                          "₹${item.depositAmount!.toInt()} dep.",
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.colorScheme.outline,
                          ),
                        )
                      else
                        Text(
                          "Free loan",
                          style: TextStyle(
                            fontSize: 10.5,
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
