// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/models/user_profile.dart';
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/services/transaction_service.dart';
import 'package:lendnborrow/core/widgets/app_logo.dart';
import 'package:lendnborrow/core/widgets/empty_state_view.dart';
import 'package:lendnborrow/core/widgets/status_badge.dart';
import 'package:lendnborrow/feature/admin/admin_dashboard_screen.dart';
import 'package:lendnborrow/feature/auth/auth_screen.dart';
import 'package:lendnborrow/feature/explore/item_details_screen.dart';
import 'package:lendnborrow/feature/history/history_screen.dart';
import 'package:lendnborrow/feature/settings/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String path = "/profile";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authServiceProvider);
    final currentUser = auth.currentUser;
    final txService = ref.watch(transactionServiceProvider);
    final marketplace = ref.watch(marketplaceServiceProvider);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Profile",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Symbols.settings),
              tooltip: "Settings",
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const AppLogo(size: 110, borderRadius: 16),
              const SizedBox(height: 16),
              Text(
                "Welcome to BorrowBox",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Register or sign in with any personal email to lend gear, borrow items, and build your community reputation.",
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AuthScreen.path),
                icon: const Icon(Icons.login),
                label: const Text("Sign In or Register"),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final reviews = txService.getReviewsForUser(currentUser.id);
    final favoriteCount = marketplace.getFavoriteItems().length;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppLogo.icon(size: 28, borderRadius: 6),
            SizedBox(width: 10),
            Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.logout),
            tooltip: "Sign Out",
            onPressed: () {
              auth.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Signed out of BorrowBox")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Symbols.settings),
            tooltip: "Settings",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Profile Header Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(60),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        currentUser.name.isNotEmpty ? currentUser.name[0] : "U",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentUser.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (currentUser.isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF00E5FF),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              "ADMIN",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                          ),
                        ] else if (currentUser.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: Colors.blue[600],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser.email,
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Symbols.location_on,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currentUser.location,
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (currentUser.bio.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        currentUser.bio,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const Divider(height: 28),

                    // Factual Trust Metrics
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol(
                          context,
                          currentUser.rating.toStringAsFixed(1),
                          "Rating ⭐",
                          theme.colorScheme.primary,
                        ),
                        _buildStatCol(
                          context,
                          "${currentUser.completedLoans}",
                          "Loans Shared",
                          Colors.green[700]!,
                        ),
                        _buildStatCol(
                          context,
                          "${currentUser.reviewCount}",
                          "Peer Reviews",
                          theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showEditProfileSheet(context, ref, currentUser),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text("Edit Profile Information"),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size.fromHeight(38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (currentUser.isAdmin) ...[
              Card(
                elevation: 2,
                color: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                  title: const Text(
                    "Admin Command Center",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: const Text(
                    "Marketplace moderation, dispute override & live cloud ping",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF00E5FF),
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(AdminDashboardScreen.path),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Shortcuts Menu
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(50),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Symbols.history),
                    title: const Text("Completed History Archive"),
                    subtitle: const Text(
                      "View past returned and completed transactions",
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Symbols.favorite),
                    title: const Text("Saved Favorites"),
                    subtitle: Text("$favoriteCount items saved"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showFavoritesSheet(context, marketplace),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Symbols.backup),
                    title: const Text("Database Backup & Data Privacy"),
                    subtitle: const Text(
                      "Export/Import local SQLite backups natively",
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Symbols.logout, color: Colors.red),
                    title: const Text(
                      "Sign Out",
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text("Exit active user session"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      auth.signOut();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Peer Reviews Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Peer Reviews (${reviews.length})",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (reviews.isEmpty)
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(40),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      "No reviews yet. Complete your first borrowing transaction to receive peer ratings!",
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              ...reviews.map((rev) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              child: Text(
                                rev.reviewerName.isNotEmpty
                                    ? rev.reviewerName[0]
                                    : "R",
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              rev.reviewerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: List.generate(
                                rev.rating.toInt(),
                                (_) => const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(rev.comment, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          "Item: ${rev.itemTitle}",
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  void _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile user,
  ) {
    final nameController = TextEditingController(text: user.name);
    final bioController = TextEditingController(text: user.bio);
    final locationController = TextEditingController(text: user.location);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Edit Profile",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Full Name *",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: "General Area / Neighborhood",
                  hintText: "e.g., Koramangala, Indiranagar",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "About You / Bio",
                  hintText:
                      "e.g., DIY maker, happy to share gear with neighbors.",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Name cannot be empty.")),
                    );
                    return;
                  }
                  await ref
                      .read(authServiceProvider)
                      .updateProfile(
                        name: newName,
                        bio: bioController.text.trim(),
                        location: locationController.text.trim().isNotEmpty
                            ? locationController.text.trim()
                            : "Local Community",
                      );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Profile updated successfully!"),
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFavoritesSheet(
    BuildContext context,
    MarketplaceService marketplace,
  ) {
    final favorites = marketplace.getFavoriteItems();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Saved Favorites (${favorites.length})",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: favorites.isEmpty
                    ? const EmptyStateView(
                        icon: Symbols.favorite_border,
                        title: "No Saved Favorites",
                        message:
                            "Tap the heart icon on any marketplace item to save it here for quick access.",
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: favorites.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = favorites[index];
                          return ListTile(
                            tileColor: theme.colorScheme.surfaceContainerHighest
                                .withAlpha(40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withAlpha(80),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Symbols.category,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "${item.categoryDisplay} • ${item.pickupLocation}",
                            ),
                            trailing: StatusBadge.availability(
                              item.availability,
                            ),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ItemDetailsScreen(item: item),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
