// Flutter Imports
import "package:flutter/material.dart";

// Package Imports
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:material_symbols_icons/symbols.dart";

// Project Imports
import "package:lendnborrow/core/models/borrow_request.dart";
import "package:lendnborrow/core/services/auth_service.dart";
import "package:lendnborrow/core/services/transaction_service.dart";
import "package:lendnborrow/core/widgets/empty_state_view.dart";
import "package:lendnborrow/core/widgets/status_badge.dart";
import "package:lendnborrow/feature/history/history_items.dart";

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  static const String path = "/history";

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final txService = ref.watch(transactionServiceProvider);

    final userId = currentUser?.id ?? "";
    final completedBorrows = txService
        .getMyBorrowed(userId)
        .where(
          (r) =>
              r.status == RequestStatus.returned ||
              r.status == RequestStatus.rejected ||
              r.status == RequestStatus.cancelled,
        )
        .toList();

    final completedLends = txService
        .getMyLent(userId)
        .where(
          (r) =>
              r.status == RequestStatus.returned ||
              r.status == RequestStatus.rejected ||
              r.status == RequestStatus.cancelled,
        )
        .toList();

    final allCompletedCloud = [...completedBorrows, ...completedLends]
      ..sort((a, b) => b.requestDate.compareTo(a.requestDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "History & Archive",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Symbols.cloud_done, size: 16),
                  const SizedBox(width: 6),
                  Text("Cloud Sharing (${allCompletedCloud.length})"),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.inventory_2, size: 16),
                  SizedBox(width: 6),
                  Text("Local Ledger"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Cloud Completed Transactions
          _buildCloudHistoryTab(context, allCompletedCloud, userId),

          // Tab 2: Private Offline SQLite Ledger History
          const SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: HistoryItems(),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudHistoryTab(
    BuildContext context,
    List<BorrowRequest> items,
    String currentUserId,
  ) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return const EmptyStateView(
        icon: Symbols.history,
        title: "No Completed Transactions",
        message:
            "When shared items are returned or transactions are completed, they will be archived here.",
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = items[index];
        final isBorrower = req.borrowerId == currentUserId;
        final partnerName = isBorrower ? req.ownerName : req.borrowerName;
        final roleLabel = isBorrower ? "Borrowed from" : "Lent to";

        return Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(50),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        req.itemTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatusBadge.request(req.status),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isBorrower ? Symbols.download : Symbols.upload,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$roleLabel $partnerName",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Period: ${DateFormat.yMd().format(req.startDate)} - ${DateFormat.yMd().format(req.endDate)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
