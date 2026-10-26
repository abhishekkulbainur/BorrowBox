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

class HistoryItems extends ConsumerWidget {
  const HistoryItems({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyItemsProvider);
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return historyAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const EmptyStateView(
            icon: Symbols.archive,
            title: "No Offline Ledger History",
            message:
                "Private offline records that have been returned or completed will appear here.",
          );
        }

        final lent = items
            .where((i) => i.type == TransactionType.lent && !i.wasLost)
            .toList();
        final borrowed = items
            .where((i) => i.type == TransactionType.borrowed && !i.wasLost)
            .toList();
        final lost = items.where((i) => i.wasLost).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (borrowed.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
                child: Text(
                  localizations.borrowed_screen_title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              _buildList(borrowed),
              const SizedBox(height: 16),
            ],
            if (lent.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
                child: Text(
                  localizations.lent_screen_title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              _buildList(lent),
              const SizedBox(height: 16),
            ],
            if (lost.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
                child: Text(
                  localizations.lost,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
              ),
              _buildList(lost),
            ],
          ],
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
            "Error loading history: $e",
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<ItemTransaction> items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) => ItemTransactionTile(item: items[index]),
    );
  }
}
