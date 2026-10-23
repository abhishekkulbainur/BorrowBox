// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/models/borrow_request.dart';
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/services/transaction_service.dart';
import 'package:lendnborrow/core/widgets/empty_state_view.dart';
import 'package:lendnborrow/core/widgets/qr_handover_modal.dart';
import 'package:lendnborrow/core/widgets/status_badge.dart';
import 'package:lendnborrow/feature/auth/auth_screen.dart';
import 'package:lendnborrow/feature/borrowed/borrowed_screen.dart';
import 'package:lendnborrow/feature/lent/lent_screen.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  static const String path = "/activity";

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final txService = ref.watch(transactionServiceProvider);
    final marketplace = ref.watch(marketplaceServiceProvider);

    // If guest / unauthenticated:
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "My Sharing Activity",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.swap_horiz, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  "Sign In to Track Activity",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Track your active loans, incoming requests, and borrowed items across community circles.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(AuthScreen.path),
                  icon: const Icon(Icons.login),
                  label: const Text("Sign In or Register"),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const BorrowedScreen()),
                    );
                  },
                  icon: const Icon(Icons.lock_clock),
                  label: const Text("Open Local SQLite Ledger"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final userId = currentUser.id;
    final myBorrows = txService.getMyBorrowed(userId);
    final myLentLoans = txService.getMyLent(userId);
    final incomingRequests = txService.getIncomingPendingRequests(userId);
    final myListings = marketplace.getItemsByOwner(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Sharing Activity",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Symbols.download, size: 18),
                  const SizedBox(width: 6),
                  const Text("Borrowed"),
                  if (myBorrows.where((b) => b.status == RequestStatus.active).isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${myBorrows.where((b) => b.status == RequestStatus.active).length}",
                        style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Symbols.upload, size: 18),
                  const SizedBox(width: 6),
                  const Text("Lent & Requests"),
                  if (incomingRequests.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${incomingRequests.length}",
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Symbols.inventory_2, size: 18),
                  const SizedBox(width: 6),
                  Text("My Listings (${myListings.length})"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBorrowedTab(context, myBorrows),
          _buildLentTab(context, incomingRequests, myLentLoans),
          _buildListingsTab(context, myListings),
        ],
      ),
    );
  }

  // Borrowed items view
  Widget _buildBorrowedTab(BuildContext context, List<BorrowRequest> items) {
    if (items.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: EmptyStateView(
              icon: Symbols.download,
              title: "No Borrowed Items Yet",
              message: "Discover items in your community and submit a borrow request.",
              actionLabel: "Explore Items",
              onAction: () {},
            ),
          ),
          _buildOfflineLedgerBanner(context, isLent: false),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final req = items[index];
              return _buildBorrowCard(context, req);
            },
          ),
        ),
        _buildOfflineLedgerBanner(context, isLent: false),
      ],
    );
  }

  Widget _buildBorrowCard(BuildContext context, BorrowRequest req) {
    final theme = Theme.of(context);
    final txService = ref.read(transactionServiceProvider);
    final currentUserId = ref.read(currentUserProvider)?.id;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(60)),
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
            Text(
              "Lender: ${req.ownerName}",
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Duration: ${DateFormat.yMd().format(req.startDate)} - ${DateFormat.yMd().format(req.endDate)}",
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (req.status == RequestStatus.handoverPending)
                  FilledButton.icon(
                    onPressed: () {
                      _showQrModal(context, req, false);
                    },
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text("Show Handover QR"),
                  )
                else if (req.status == RequestStatus.active)
                  FilledButton.tonalIcon(
                    onPressed: () {
                      final ok = txService.initiateReturn(req.id, actorId: currentUserId);
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Return initiated! Show return QR to owner.")),
                        );
                      }
                    },
                    icon: const Icon(Icons.assignment_return, size: 16),
                    label: const Text("Initiate Return"),
                  )
                else if (req.status == RequestStatus.returnPending)
                  FilledButton.icon(
                    onPressed: () {
                      _showQrModal(context, req, true);
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: const Text("Show Return QR"),
                  )
                else
                  Text(
                    req.statusDisplay,
                    style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Lent & requests view
  Widget _buildLentTab(
    BuildContext context,
    List<BorrowRequest> pending,
    List<BorrowRequest> loans,
  ) {
    final theme = Theme.of(context);
    final txService = ref.read(transactionServiceProvider);

    if (pending.isEmpty && loans.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: EmptyStateView(
              icon: Symbols.upload,
              title: "No Active Loans or Requests",
              message: "When peers request to borrow your listings, they will appear here.",
            ),
          ),
          _buildOfflineLedgerBanner(context, isLent: true),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.mark_email_unread_outlined, size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      "Incoming Requests (${pending.length})",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...pending.map((req) => _buildIncomingRequestCard(context, req, txService)),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  const Icon(Icons.sync_alt, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    "Active Loans (${loans.length})",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...loans.map((req) => _buildLentCard(context, req, txService)),
            ],
          ),
        ),
        _buildOfflineLedgerBanner(context, isLent: true),
      ],
    );
  }

  Widget _buildIncomingRequestCard(
    BuildContext context,
    BorrowRequest req,
    TransactionService txService,
  ) {
    final theme = Theme.of(context);
    final currentUserId = ref.read(currentUserProvider)?.id;

    return Card(
      elevation: 0.5,
      color: Colors.amber.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber.withAlpha(80)),
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
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                StatusBadge.request(req.status),
              ],
            ),
            const SizedBox(height: 6),
            Text("From: ${req.borrowerName}"),
            Text(
              "Requested: ${DateFormat.yMd().format(req.startDate)} - ${DateFormat.yMd().format(req.endDate)}",
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
            if (req.message != null && req.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "\"${req.message!}\"",
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    final ok = txService.rejectRequest(req.id, actorId: currentUserId);
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Request declined.")),
                      );
                    }
                  },
                  child: const Text("Decline"),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final ok = txService.approveRequest(req.id, actorId: currentUserId);
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Approved request for ${req.borrowerName}!")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to approve request: unauthorized.")),
                      );
                    }
                  },
                  child: const Text("Approve Loan"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLentCard(
    BuildContext context,
    BorrowRequest req,
    TransactionService txService,
  ) {
    final theme = Theme.of(context);
    final currentUserId = ref.read(currentUserProvider)?.id;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(60)),
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
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                StatusBadge.request(req.status),
              ],
            ),
            const SizedBox(height: 4),
            Text("Borrowed by: ${req.borrowerName}"),
            Text(
              "Return due by: ${DateFormat.yMd().format(req.endDate)}",
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (req.status == RequestStatus.handoverPending)
                  FilledButton.icon(
                    onPressed: () {
                      _showQrModal(context, req, false);
                    },
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text("Handover QR"),
                  )
                else if (req.status == RequestStatus.returnPending)
                  FilledButton.icon(
                    onPressed: () {
                      final ok = txService.confirmReturn(
                        req.id,
                        req.returnQrToken ?? "",
                        scannerUserId: currentUserId,
                      );
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Return verified and loan completed!")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Return verification failed: unauthorized or invalid token.")),
                        );
                      }
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text("Confirm Return Received"),
                  )
                else
                  Text(
                    req.statusDisplay,
                    style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // My Listings view
  Widget _buildListingsTab(BuildContext context, List<MarketplaceItem> listings) {
    if (listings.isEmpty) {
      return EmptyStateView(
        icon: Symbols.inventory_2,
        title: "No Published Listings",
        message: "You haven't shared any items yet. Share an item to let peers borrow it!",
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: listings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = listings[index];
        return ListTile(
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${item.categoryDisplay} • ${item.pickupLocation}"),
          trailing: StatusBadge.availability(item.availability),
        );
      },
    );
  }

  void _showQrModal(BuildContext context, BorrowRequest req, bool isReturn) {
    final currentUserId = ref.read(currentUserProvider)?.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => QrHandoverModal(
        request: req,
        isReturn: isReturn,
        onConfirmHandover: () {
          if (isReturn) {
            ref.read(transactionServiceProvider).confirmReturn(
                  req.id,
                  req.returnQrToken ?? "",
                  scannerUserId: currentUserId,
                );
          } else {
            ref.read(transactionServiceProvider).confirmHandover(
                  req.id,
                  req.handoverQrToken ?? "",
                  scannerUserId: currentUserId,
                );
          }
        },
      ),
    );
  }

  // Preserving access to the existing offline personal tracking ledger
  Widget _buildOfflineLedgerBanner(BuildContext context, {required bool isLent}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(70),
      child: Row(
        children: [
          Icon(Icons.lock_clock, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLent
                  ? "Looking for your private offline lending records?"
                  : "Looking for your private offline borrowing records?",
              style: const TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => isLent ? const LentScreen() : const BorrowedScreen(),
                ),
              );
            },
            child: const Text("Open Local Ledger"),
          ),
        ],
      ),
    );
  }
}
