// Flutter Imports
import "package:flutter/material.dart";

// Package Imports
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_symbols_icons/symbols.dart";

// Project Imports
import "package:lendnborrow/core/models/item_transaction.dart";
import "package:lendnborrow/core/provider/item_transaction_provider.dart";
import "package:lendnborrow/core/widgets/empty_state_view.dart";
import "package:lendnborrow/core/widgets/item_transaction_tile.dart";
import "package:lendnborrow/l10n/app_localizations.dart";

class ItemTransactionsList extends ConsumerWidget {
  final TransactionType type;
  const ItemTransactionsList({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    final provider = switch (type) {
      TransactionType.lent => lentItemsProvider,
      TransactionType.borrowed => borrowedItemsProvider,
      TransactionType.lost => lostItemsProvider,
    };

    final emptyText = switch (type) {
      TransactionType.lent => localizations.no_lent_items,
      TransactionType.borrowed => localizations.no_borrowed_items,
      TransactionType.lost => localizations.no_lost_items,
    };

    final emptyTitle = switch (type) {
      TransactionType.lent => "No Lent Items in Ledger",
      TransactionType.borrowed => "No Borrowed Items in Ledger",
      TransactionType.lost => "No Lost Items in Ledger",
    };

    final itemsAsync = ref.watch(provider);

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return EmptyStateView(
            icon: Symbols.inventory_2,
            title: emptyTitle,
            message: emptyText,
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              ItemTransactionTile(item: items[index]),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Error: $e",
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}
