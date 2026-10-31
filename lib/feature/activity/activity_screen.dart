// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:uuid/uuid.dart';

// Project Imports
import 'package:lendnborrow/core/models/borrow_request.dart';
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/models/review.dart';
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/chat_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/services/transaction_service.dart';
import 'package:lendnborrow/core/widgets/app_logo.dart';
import 'package:lendnborrow/core/widgets/empty_state_view.dart';
import 'package:lendnborrow/core/widgets/product_image_view.dart';
import 'package:lendnborrow/core/widgets/qr_handover_modal.dart';
import 'package:lendnborrow/core/widgets/status_badge.dart';
import 'package:lendnborrow/feature/auth/auth_screen.dart';
import 'package:lendnborrow/feature/borrowed/borrowed_screen.dart';
import 'package:lendnborrow/feature/chat/chat_screen.dart';
import 'package:lendnborrow/feature/explore/edit_listing_screen.dart';
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
                const AppLogo(size: 90, borderRadius: 16),
                const SizedBox(height: 16),
                Text(
                  "Sign In to Track Activity",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Track your active loans, incoming requests, and borrowed items across community circles.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AuthScreen.path),
                  icon: const Icon(Icons.login),
                  label: const Text("Sign In or Register"),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BorrowedScreen(),
                      ),
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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo.icon(size: 26, borderRadius: 6),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "My Sharing Activity",
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Symbols.download, size: 16),
                  const SizedBox(width: 5),
                  const Text("Borrowed"),
                  if (myBorrows
                      .where((b) => b.status == RequestStatus.active)
                      .isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${myBorrows.where((b) => b.status == RequestStatus.active).length}",
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Symbols.upload, size: 16),
                  const SizedBox(width: 5),
                  const Text("Lent & Requests"),
                  if (incomingRequests.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${incomingRequests.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Symbols.inventory_2, size: 16),
                  const SizedBox(width: 5),
                  const Text("My Listings"),
                  if (myListings.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${myListings.length}",
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyStateView(
            icon: Symbols.download,
            title: "No Borrowed Items Yet",
            message:
                "Discover items in your community and submit a borrow request.",
            actionLabel: "Explore Items",
            onAction: () {},
          ),
          const SizedBox(height: 16),
          _buildOfflineLedgerBanner(context, isLent: false),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return _buildOfflineLedgerBanner(context, isLent: false);
        }
        final req = items[index];
        return _buildBorrowCard(context, req);
      },
    );
  }

  Widget _buildBorrowCard(BuildContext context, BorrowRequest req) {
    final theme = Theme.of(context);
    final txService = ref.read(transactionServiceProvider);
    final currentUserId = ref.read(currentUserProvider)?.id;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Builder(
          builder: (context) {
            final item = ref.watch(marketplaceServiceProvider).getItemById(req.listingId);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item != null) ...[
                      ProductImageView(
                        imageUrl: item.photoUrls.isNotEmpty ? item.photoUrls.first : null,
                        category: item.category,
                        width: 44,
                        height: 44,
                        borderRadius: BorderRadius.circular(8),
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 10),
                    ],
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
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
            const Divider(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      tooltip: "Chat with Lender",
                      onPressed: () => _openChat(
                        context,
                        otherUserId: req.ownerId,
                        otherUserName: req.ownerName,
                        itemId: req.itemId,
                        itemTitle: req.itemTitle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (req.status == RequestStatus.pending ||
                        req.status == RequestStatus.handoverPending) ...[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: theme.colorScheme.error,
                        ),
                        onPressed: () {
                          if (currentUserId != null) {
                            final ok = txService.cancelRequest(
                              req.id,
                              currentUserId,
                            );
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Request cancelled."),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (req.status == RequestStatus.handoverPending)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          _showQrModal(context, req, false);
                        },
                        icon: const Icon(Icons.qr_code, size: 16),
                        label: const Text("Show Handover QR"),
                      )
                    else if (req.status == RequestStatus.active)
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          final ok = txService.initiateReturn(
                            req.id,
                            actorId: currentUserId,
                          );
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Return initiated! Show return QR to owner.",
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.assignment_return, size: 16),
                        label: const Text("Initiate Return"),
                      )
                    else if (req.status == RequestStatus.returnPending)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          _showQrModal(context, req, true);
                        },
                        icon: const Icon(Icons.qr_code_scanner, size: 16),
                        label: const Text("Show Return QR"),
                      )
                    else if (req.status == RequestStatus.returned)
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          _showReviewModal(
                            context,
                            req,
                            isReviewingOwner: true,
                          );
                        },
                        icon: const Icon(Icons.star_outline, size: 16),
                        label: const Text("Rate Lender"),
                      )
                    else
                      Text(
                        req.statusDisplay,
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ],
          );
        },
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
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const EmptyStateView(
            icon: Symbols.upload,
            title: "No Active Loans or Requests",
            message:
                "When peers request to borrow your listings, they will appear here.",
          ),
          const SizedBox(height: 16),
          _buildOfflineLedgerBanner(context, isLent: true),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 18,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                "Incoming Requests (${pending.length})",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...pending.map(
            (req) => _buildIncomingRequestCard(context, req, txService),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            const Icon(Icons.sync_alt, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              "Active Loans (${loans.length})",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...loans.map((req) => _buildLentCard(context, req, txService)),
        const SizedBox(height: 16),
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
    final item = ref.watch(marketplaceServiceProvider).getItemById(req.listingId);

    return Card(
      elevation: 0,
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
                if (item != null) ...[
                  ProductImageView(
                    imageUrl: item.photoUrls.isNotEmpty ? item.photoUrls.first : null,
                    category: item.category,
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(8),
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    req.itemTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      tooltip: "Chat with Borrower",
                      onPressed: () => _openChat(
                        context,
                        otherUserId: req.borrowerId,
                        otherUserName: req.borrowerName,
                        itemId: req.itemId,
                        itemTitle: req.itemTitle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        final ok = txService.rejectRequest(
                          req.id,
                          actorId: currentUserId,
                        );
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
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        final ok = txService.approveRequest(
                          req.id,
                          actorId: currentUserId,
                        );
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Approved request for ${req.borrowerName}!",
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Failed to approve request: unauthorized.",
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text("Approve Loan"),
                    ),
                  ],
                ),
              ),
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
    final item = ref.watch(marketplaceServiceProvider).getItemById(req.listingId);

    return Card(
      elevation: 0,
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
                if (item != null) ...[
                  ProductImageView(
                    imageUrl: item.photoUrls.isNotEmpty ? item.photoUrls.first : null,
                    category: item.category,
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(8),
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    req.itemTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
            Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      tooltip: "Chat with Borrower",
                      onPressed: () => _openChat(
                        context,
                        otherUserId: req.borrowerId,
                        otherUserName: req.borrowerName,
                        itemId: req.itemId,
                        itemTitle: req.itemTitle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (req.status == RequestStatus.handoverPending)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          _showQrModal(context, req, false);
                        },
                        icon: const Icon(Icons.qr_code, size: 16),
                        label: const Text("Handover QR"),
                      )
                    else if (req.status == RequestStatus.returnPending)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          final ok = txService.confirmReturn(
                            req.id,
                            req.returnQrToken ?? "",
                            scannerUserId: currentUserId,
                          );
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Return verified and loan completed!",
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Return verification failed: unauthorized or invalid token.",
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text("Confirm Return Received"),
                      )
                    else if (req.status == RequestStatus.returned)
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          _showReviewModal(
                            context,
                            req,
                            isReviewingOwner: false,
                          );
                        },
                        icon: const Icon(Icons.star_outline, size: 16),
                        label: const Text("Rate Borrower"),
                      )
                    else
                      Text(
                        req.statusDisplay,
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // My Listings view
  Widget _buildListingsTab(
    BuildContext context,
    List<MarketplaceItem> listings,
  ) {
    final theme = Theme.of(context);
    final marketplace = ref.read(marketplaceServiceProvider);

    if (listings.isEmpty) {
      return EmptyStateView(
        icon: Symbols.inventory_2,
        title: "No Published Listings",
        message:
            "You haven't shared any items yet. Share an item to let peers borrow it!",
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: listings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = listings[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(60),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProductImageView(
                      imageUrl: item.photoUrls.isNotEmpty
                          ? item.photoUrls.first
                          : null,
                      category: item.category,
                      width: 56,
                      height: 56,
                      borderRadius: BorderRadius.circular(10),
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${item.categoryDisplay} • ${item.pickupLocation}",
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.isFree
                                ? "Free Community Share"
                                : "₹${item.rentalPricePerDay?.toStringAsFixed(0)}/day",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: item.isFree
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge.availability(item.availability),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditListingScreen(item: item),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 15),
                      label: const Text("Edit"),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () async {
                        final newActive = !item.isActive;
                        await marketplace.toggleListingActive(
                          item.id,
                          newActive,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                newActive
                                    ? "Listing activated!"
                                    : "Listing paused.",
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        item.isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 15,
                      ),
                      label: Text(item.isActive ? "Pause" : "Resume"),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: "Delete listing",
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Delete Listing?"),
                            content: Text(
                              "Are you sure you want to permanently delete '${item.title}'?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text("Cancel"),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                ),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          marketplace.deleteListing(item.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Listing deleted.")),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            ref
                .read(transactionServiceProvider)
                .confirmReturn(
                  req.id,
                  req.returnQrToken ?? "",
                  scannerUserId: currentUserId,
                );
          } else {
            ref
                .read(transactionServiceProvider)
                .confirmHandover(
                  req.id,
                  req.handoverQrToken ?? "",
                  scannerUserId: currentUserId,
                );
          }
        },
      ),
    );
  }

  Future<void> _openChat(
    BuildContext context, {
    required String otherUserId,
    required String otherUserName,
    required String itemId,
    required String itemTitle,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final chatService = ref.read(chatServiceProvider);
    final conversation = await chatService.getOrCreateConversation(
      currentUserId: currentUser.id,
      currentUserName: currentUser.displayName,
      currentUserAvatar: currentUser.avatarUrl,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      itemId: itemId,
      itemTitle: itemTitle,
    );

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversation: conversation,
          currentUserId: currentUser.id,
        ),
      ),
    );
  }

  void _showReviewModal(
    BuildContext context,
    BorrowRequest req, {
    required bool isReviewingOwner,
  }) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final targetUserId = isReviewingOwner ? req.ownerId : req.borrowerId;
    final targetUserName = isReviewingOwner ? req.ownerName : req.borrowerName;

    double rating = 5.0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text("Rate $targetUserName"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "How was your experience sharing '${req.itemTitle}'?",
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  return IconButton(
                    onPressed: () {
                      setModalState(() {
                        rating = starVal.toDouble();
                      });
                    },
                    icon: Icon(
                      starVal <= rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Comments or feedback (optional)",
                  border: OutlineInputBorder(),
                  hintText: "E.g., Item was in great condition, prompt return!",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                final review = Review(
                  id: const Uuid().v4(),
                  transactionId: req.id,
                  reviewerId: currentUser.id,
                  reviewerName: currentUser.displayName,
                  reviewerAvatarUrl: currentUser.avatarUrl,
                  targetUserId: targetUserId,
                  rating: rating,
                  comment: commentCtrl.text.trim(),
                  createdAt: DateTime.now(),
                  itemTitle: req.itemTitle,
                );

                ref.read(transactionServiceProvider).addReview(review);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Thank you for your review!")),
                  );
                }
              },
              child: const Text("Submit Review"),
            ),
          ],
        ),
      ),
    );
  }

  // Preserving access to the existing offline personal tracking ledger
  Widget _buildOfflineLedgerBanner(
    BuildContext context, {
    required bool isLent,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(70),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.lock_clock, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isLent
                    ? "Looking for your private offline lending records?"
                    : "Looking for your private offline borrowing records?",
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        isLent ? const LentScreen() : const BorrowedScreen(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              ),
              child: const Text("Open Ledger", style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
