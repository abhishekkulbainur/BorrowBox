// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/widgets/app_logo.dart';
import 'package:lendnborrow/core/widgets/empty_state_view.dart';
import 'package:lendnborrow/core/widgets/item_card.dart';
import 'package:lendnborrow/feature/explore/create_listing_screen.dart';
import 'package:lendnborrow/feature/explore/item_details_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  static const String path = "/explore";

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  ItemCategory _selectedCategory = ItemCategory.all;
  ItemCondition? _selectedCondition;
  bool _onlyAvailable = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = ref.watch(marketplaceServiceProvider);
    final theme = Theme.of(context);

    final filteredItems = marketplace.searchAndFilter(
      query: _searchController.text,
      category: _selectedCategory,
      condition: _selectedCondition,
      onlyAvailable: _onlyAvailable,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppLogo.icon(size: 28, borderRadius: 6),
            SizedBox(width: 10),
            Text(
              "Explore Marketplace",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _onlyAvailable || _selectedCondition != null,
              child: const Icon(Symbols.tune),
            ),
            tooltip: "Filters",
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateListingScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Share Item"),
      ),
      body: Column(
        children: [
          // Search input bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search calculators, tools, electronics...",
                prefixIcon: const Icon(Symbols.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(
                  80,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Horizontal Category Chip bar
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ItemCategory.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = ItemCategory.values[index];
                final isSelected = category == _selectedCategory;

                return ChoiceChip(
                  label: Text(_categoryLabel(category)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Grid Results
          Expanded(
            child: filteredItems.isEmpty
                ? EmptyStateView(
                    icon: Symbols.search_off,
                    title: "No items found",
                    message:
                        "Try searching with different keywords or reset your filters.",
                    actionLabel: "Clear Filters",
                    onAction: () {
                      setState(() {
                        _searchController.clear();
                        _selectedCategory = ItemCategory.all;
                        _selectedCondition = null;
                        _onlyAvailable = false;
                      });
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 80,
                      top: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return ItemCard(
                        item: item,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ItemDetailsScreen(item: item),
                            ),
                          );
                        },
                        onFavoriteToggle: () {
                          ref
                              .read(marketplaceServiceProvider)
                              .toggleFavorite(item.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(ItemCategory cat) {
    switch (cat) {
      case ItemCategory.all:
        return "All";
      case ItemCategory.tools:
        return "Tools & DIY";
      case ItemCategory.electronics:
        return "Electronics";
      case ItemCategory.books:
        return "Books";
      case ItemCategory.sports:
        return "Sports";
      case ItemCategory.household:
        return "Household";
      case ItemCategory.travel:
        return "Travel";
      case ItemCategory.calculators:
        return "Calculators";
      case ItemCategory.creative:
        return "Creative";
      case ItemCategory.games:
        return "Games";
      case ItemCategory.other:
        return "General";
    }
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filter Marketplace",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCondition = null;
                            _onlyAvailable = false;
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text("Reset"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text("Only Available Items"),
                    subtitle: const Text(
                      "Hide reserved and currently borrowed items",
                    ),
                    value: _onlyAvailable,
                    onChanged: (val) {
                      setModalState(() => _onlyAvailable = val);
                      setState(() {});
                    },
                  ),
                  const Divider(),
                  const Text(
                    "Item Condition",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ItemCondition.values.map((cond) {
                      final selected = _selectedCondition == cond;
                      return ChoiceChip(
                        label: Text(cond.name.toUpperCase()),
                        selected: selected,
                        onSelected: (val) {
                          setModalState(() {
                            _selectedCondition = val ? cond : null;
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text("Apply Filters"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
