// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/models/report_item.dart';
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/chat_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/services/transaction_service.dart';
import 'package:lendnborrow/core/widgets/product_image_view.dart';
import 'package:lendnborrow/core/widgets/status_badge.dart';
import 'package:lendnborrow/feature/auth/auth_screen.dart';
import 'package:lendnborrow/feature/chat/chat_screen.dart';
import 'package:lendnborrow/feature/explore/edit_listing_screen.dart';

class ItemDetailsScreen extends ConsumerStatefulWidget {
  final MarketplaceItem item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  ConsumerState<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends ConsumerState<ItemDetailsScreen> {
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  late DateTime _endDate;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _endDate = _startDate.add(Duration(days: widget.item.maxDurationDays));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marketplace = ref.watch(marketplaceServiceProvider);
    final currentItem = marketplace.getItemById(widget.item.id) ?? widget.item;
    final currentUser = ref.watch(currentUserProvider);
    final isMyItem = currentUser?.id == currentItem.ownerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentItem.title),
        actions: [
          if (isMyItem) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: "Edit Listing",
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditListingScreen(item: currentItem),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: "Delete Listing",
              onPressed: () =>
                  _confirmDeleteListing(context, currentItem, currentUser?.id),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: "Chat with Owner",
              onPressed: () => _openChatWithOwner(context, currentItem),
            ),
          ],
          IconButton(
            icon: Icon(
              currentItem.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: currentItem.isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              ref
                  .read(marketplaceServiceProvider)
                  .toggleFavorite(currentItem.id);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == "share") {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Listing link copied to clipboard"),
                  ),
                );
              } else if (val == "report") {
                _showReportListingDialog(context, currentItem);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "share",
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 18),
                    SizedBox(width: 8),
                    Text("Share Listing"),
                  ],
                ),
              ),
              if (!isMyItem)
                const PopupMenuItem(
                  value: "report",
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text("Report Listing"),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withAlpha(60),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentItem.depositAmount != null
                        ? "₹${currentItem.depositAmount!.toInt()} Deposit"
                        : "Free Sharing",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: currentItem.depositAmount != null
                          ? theme.colorScheme.primary
                          : Colors.green[700],
                    ),
                  ),
                  Text(
                    "Up to ${currentItem.maxDurationDays} days",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isMyItem)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditListingScreen(item: currentItem),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Listing"),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.chat_bubble_outline),
                      tooltip: "Chat with Owner",
                      onPressed: () => _openChatWithOwner(context, currentItem),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: (currentItem.availability ==
                                  ItemAvailability.available &&
                              currentItem.isActive)
                          ? () {
                              if (currentUser == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please sign in or register to borrow items.",
                                    ),
                                  ),
                                );
                                Navigator.of(context).pushNamed(AuthScreen.path);
                                return;
                              }
                              _showRequestBottomSheet(context, currentItem);
                            }
                          : null,
                      icon: const Icon(Icons.send),
                      label: Text(
                        currentItem.availability ==
                                    ItemAvailability.available &&
                                currentItem.isActive
                            ? "Request to Borrow"
                            : "Unavailable",
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Swipeable Product Image Gallery with indicators and zoom
            ProductImageGallery(
              imageUrls: currentItem.photoUrls,
              category: currentItem.category,
              height: 250,
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags Row
                  Row(
                    children: [
                      StatusBadge.availability(currentItem.availability),
                      const SizedBox(width: 8),
                      StatusBadge.condition(currentItem.condition),
                      const Spacer(),
                      Text(
                        currentItem.categoryDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Item Title
                  Text(
                    currentItem.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Owner Trust Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(60),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(60),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: theme.colorScheme.primary.withAlpha(
                            40,
                          ),
                          child: Text(
                            currentItem.ownerName[0],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    currentItem.ownerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.blue[600],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    "${currentItem.ownerRating.toStringAsFixed(1)} (Peer Rated)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (currentItem.communityName != null)
                          Chip(
                            avatar: const Icon(Icons.group, size: 14),
                            label: Text(
                              currentItem.communityName!,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    "Description",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentItem.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Location & Logistics
                  Text(
                    "Pickup & Lending Logistics",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildLogisticsTile(
                    theme,
                    Symbols.location_on,
                    "Pickup Location",
                    currentItem.pickupLocation,
                  ),
                  _buildLogisticsTile(
                    theme,
                    Symbols.calendar_month,
                    "Maximum Loan Period",
                    "Up to ${currentItem.maxDurationDays} consecutive days",
                  ),
                  if (currentItem.terms != null)
                    _buildLogisticsTile(
                      theme,
                      Symbols.verified_user,
                      "Owner Terms & Guidelines",
                      currentItem.terms!,
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsTile(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestBottomSheet(BuildContext context, MarketplaceItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final durationDays = _endDate.difference(_startDate).inDays;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Request to Borrow",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dates Selection
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 60),
                              ),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _startDate = picked;
                                if (_endDate.isBefore(_startDate)) {
                                  _endDate = _startDate.add(
                                    const Duration(days: 2),
                                  );
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.date_range, size: 16),
                          label: Text(
                            "From: ${DateFormat.yMd().format(_startDate)}",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate: _startDate.add(
                                Duration(days: item.maxDurationDays),
                              ),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _endDate = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(
                            "Until: ${DateFormat.yMd().format(_endDate)}",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Requested duration: $durationDays days (Max allowed: ${item.maxDurationDays} days)",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Message input
                  TextField(
                    controller: _messageController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Note for ${item.ownerName}",
                      hintText:
                          "Why do you need this item? Mention preferred pickup time...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  FilledButton(
                    onPressed: () async {
                      final currentUser = ref.read(currentUserProvider);
                      if (currentUser == null) {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(AuthScreen.path);
                        return;
                      }

                      try {
                        await ref
                            .read(transactionServiceProvider)
                            .createBorrowRequest(
                              item: item,
                              borrowerId: currentUser.id,
                              borrowerName: currentUser.name,
                              startDate: _startDate,
                              endDate: _endDate,
                              message: _messageController.text.trim(),
                            );

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green[800],
                              content: Text(
                                "Request sent to ${item.ownerName}! You'll be notified upon approval.",
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red[800],
                              content: Text(
                                e
                                    .toString()
                                    .replaceAll("ArgumentError: ", "")
                                    .replaceAll("Exception: ", ""),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text("Send Borrow Request"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteListing(
    BuildContext context,
    MarketplaceItem item,
    String? actorId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Listing?"),
        content: Text(
          "Are you sure you want to remove '${item.title}' from the community marketplace? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red[800]),
            onPressed: () {
              Navigator.of(ctx).pop();
              final ok = ref
                  .read(marketplaceServiceProvider)
                  .deleteListing(item.id, actorId: actorId);
              if (ok) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Listing '${item.title}' was deleted."),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Failed to delete listing: unauthorized."),
                  ),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _openChatWithOwner(BuildContext context, MarketplaceItem item) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please sign in or register to chat with the owner."),
        ),
      );
      Navigator.of(context).pushNamed(AuthScreen.path);
      return;
    }

    final chatService = ref.read(chatServiceProvider);
    final conv = await chatService.getOrCreateConversation(
      myUserId: currentUser.id,
      myName: currentUser.name,
      myAvatar: currentUser.avatarUrl,
      otherUserId: item.ownerId,
      otherName: item.ownerName,
      itemId: item.id,
      itemTitle: item.title,
      itemImageUrl: item.imageUrls.isNotEmpty ? item.imageUrls.first : null,
    );

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(conversation: conv),
        ),
      );
    }
  }

  void _showReportListingDialog(
    BuildContext context,
    MarketplaceItem item,
  ) {
    final detailsController = TextEditingController();
    String selectedReason = "Misleading description or fake item";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text("Report Listing"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Report \"${item.title}\" to BorrowBox safety team:",
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                items: const [
                  DropdownMenuItem(
                    value: "Misleading description or fake item",
                    child: Text("Misleading or Fake Item"),
                  ),
                  DropdownMenuItem(
                    value: "Damaged or non-functional item",
                    child: Text("Damaged / Non-functional"),
                  ),
                  DropdownMenuItem(
                    value: "Prohibited or dangerous equipment",
                    child: Text("Prohibited / Dangerous item"),
                  ),
                  DropdownMenuItem(
                    value: "Suspicious deposit demands",
                    child: Text("Suspicious Deposit Demand"),
                  ),
                  DropdownMenuItem(
                    value: "Other",
                    child: Text("Other Concern"),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => selectedReason = val);
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Add specific details for moderation...",
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                final myUser = ref.read(currentUserProvider);
                if (myUser != null) {
                  final report = ReportItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    reporterId: myUser.id,
                    reporterName: myUser.name,
                    targetUserId: item.ownerId,
                    targetListingId: item.id,
                    targetListingTitle: item.title,
                    reason: selectedReason,
                    details: detailsController.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  await ref.read(chatServiceProvider).submitReport(report);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Thank you. This listing was flagged for review.",
                      ),
                    ),
                  );
                }
              },
              child: const Text("Submit Report"),
            ),
          ],
        ),
      ),
    );
  }
}
