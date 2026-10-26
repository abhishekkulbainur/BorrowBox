// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/services/notification_service.dart';
import 'package:lendnborrow/core/services/transaction_service.dart';
import 'package:lendnborrow/core/widgets/app_logo.dart';
import 'package:lendnborrow/core/widgets/item_card.dart';
import 'package:lendnborrow/feature/explore/create_listing_screen.dart';
import 'package:lendnborrow/feature/explore/item_details_screen.dart';
import 'package:lendnborrow/feature/auth/auth_screen.dart';
import 'package:lendnborrow/feature/home/home_summary.dart';
import 'package:lendnborrow/feature/notifications/notifications_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String path = "/home";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final txService = ref.watch(transactionServiceProvider);
    final marketplace = ref.watch(marketplaceServiceProvider);
    final notifService = ref.watch(notificationServiceProvider);

    final userId = currentUser?.id ?? "";
    final activeBorrows = txService.getActiveBorrows(userId).length;
    final activeLoans = txService.getActiveLoans(userId).length;
    final pendingRequests = txService.getIncomingPendingRequests(userId).length;
    final unreadNotifs = notifService.getUnreadCountForUser(userId);
    final featuredItems = marketplace.allItems.take(4).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refreshes data providers
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Header & Notification Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const AppLogo.icon(size: 44, borderRadius: 10),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "BorrowBox",
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "Share More. Own Less.",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton.filledTonal(
                      icon: Badge(
                        isLabelVisible: unreadNotifs > 0,
                        label: Text("$unreadNotifs"),
                        child: const Icon(Symbols.notifications),
                      ),
                      tooltip: "Notifications",
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Welcome User Banner
                if (currentUser != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      "Hello, ${currentUser.name.split(' ')[0]} 👋 Ready to borrow or share today?",
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    color: theme.colorScheme.primaryContainer.withAlpha(45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withAlpha(40),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_open,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome to BorrowBox",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const Text(
                                  "Sign in or register with any email to borrow and share items.",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushNamed(AuthScreen.path),
                            child: const Text("Sign In"),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Quick Activity Metrics Strip
                Row(
                  children: [
                    _buildStatTile(
                      context,
                      "$activeBorrows",
                      "Borrowing",
                      Symbols.download,
                      theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    _buildStatTile(
                      context,
                      "$activeLoans",
                      "Lending Out",
                      Symbols.upload,
                      Colors.green[700]!,
                    ),
                    const SizedBox(width: 10),
                    _buildStatTile(
                      context,
                      "$pendingRequests",
                      "Requests",
                      Symbols.inbox,
                      pendingRequests > 0
                          ? Colors.orange[800]!
                          : theme.colorScheme.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Fast Action Buttons: Share Item or Explore
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CreateListingScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Share an Item"),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Popular Categories Quick Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Explore Categories",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 85,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryItem(
                        context,
                        "Tools",
                        Symbols.build,
                        Colors.orange,
                      ),
                      _buildCategoryItem(
                        context,
                        "Electronics",
                        Symbols.devices,
                        Colors.blue,
                      ),
                      _buildCategoryItem(
                        context,
                        "Books",
                        Symbols.menu_book,
                        Colors.teal,
                      ),
                      _buildCategoryItem(
                        context,
                        "Calculators",
                        Symbols.calculate,
                        Colors.indigo,
                      ),
                      _buildCategoryItem(
                        context,
                        "Travel",
                        Symbols.camping,
                        Colors.green,
                      ),
                      _buildCategoryItem(
                        context,
                        "Sports",
                        Symbols.sports_tennis,
                        Colors.red,
                      ),
                      _buildCategoryItem(
                        context,
                        "Games",
                        Symbols.casino,
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Community Sharing Highlights
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Available Near You",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${marketplace.allItems.length} active",
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: featuredItems.length,
                  itemBuilder: (context, index) {
                    final item = featuredItems[index];
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
                const SizedBox(height: 24),

                // Sustainability Circular Impact Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.teal.withAlpha(40),
                        Colors.green.withAlpha(20),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.teal.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Symbols.eco, color: Colors.green[700], size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Community Sustainability Impact",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Every borrowed item avoids single-use purchasing, manufacturing waste, and unnecessary packaging.",
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildImpactStat("48+", "Items Reused"),
                          _buildImpactStat("₹24,500+", "Money Saved"),
                          _buildImpactStat("18.2 kg", "e-Waste Prevented"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Existing Personal Offline Tracking Ledger Section
                ExpansionTile(
                  title: const Text(
                    "Private Offline Ledger (Local Device DB)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    "Your private on-device transactions (no cloud sync)",
                    style: TextStyle(fontSize: 12),
                  ),
                  leading: const Icon(Symbols.lock),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: HomeSummary(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context,
    String count,
    String label,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withAlpha(50),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ],
    );
  }
}
