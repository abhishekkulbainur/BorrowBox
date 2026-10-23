// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/services/transaction_service.dart';
import 'package:lendnborrow/feature/auth/auth_screen.dart';
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
          title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer.withAlpha(120),
                child: Icon(Symbols.person, size: 44, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                "Welcome to BorrowBox",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Register or sign in with any personal email to lend gear, borrow items, and build your community reputation.",
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(AuthScreen.path),
                icon: const Icon(Icons.login),
                label: const Text("Sign In or Register"),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Explicitly Labelled Developer Mode
              if (auth.isDevMode) ...[
                Card(
                  elevation: 0,
                  color: Colors.amber.withAlpha(25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.amber.withAlpha(90)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.developer_mode, size: 18, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              "Developer & Evaluation Mode Only",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Quickly switch test accounts to evaluate multi-user transactions on a single device:",
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => auth.switchDemoUser("user_abhishek"),
                                child: const Text("Abhishek (Owner)"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => auth.switchDemoUser("user_snehal"),
                                child: const Text("Snehal (Borrower)"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final reviews = txService.getReviewsForUser(currentUser.id);
    final favoriteCount = marketplace.getFavoriteItems().length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
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
                side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(60)),
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
                        if (currentUser.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified, size: 18, color: Colors.blue[600]),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser.email,
                      style: TextStyle(color: theme.colorScheme.outline, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Symbols.location_on, size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          currentUser.location,
                          style: TextStyle(color: theme.colorScheme.outline, fontSize: 13),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Explicitly Labelled Developer Account Switcher (For evaluation)
            if (auth.isDevMode)
              Card(
                elevation: 0,
                color: Colors.amber.withAlpha(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.amber.withAlpha(70)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.developer_mode, size: 22, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "[Dev Mode] Active Account:",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              currentUser.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                        tooltip: "Switch Demo Test Account",
                        onSelected: (userId) {
                          auth.switchDemoUser(userId);
                        },
                        itemBuilder: (context) {
                          return auth.demoUsers.map((user) {
                            return PopupMenuItem(
                              value: user.id,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    child: Text(user.name[0], style: const TextStyle(fontSize: 10)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(user.name),
                                ],
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Shortcuts Menu
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(50)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Symbols.history),
                    title: const Text("Completed History Archive"),
                    subtitle: const Text("View past returned and completed transactions"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Symbols.favorite),
                    title: const Text("Saved Favorites"),
                    subtitle: Text("$favoriteCount items saved"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$favoriteCount favorite items in your list.")),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Symbols.backup),
                    title: const Text("Database Backup & Data Privacy"),
                    subtitle: const Text("Export/Import local SQLite backups natively"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Symbols.logout, color: Colors.red),
                    title: const Text("Sign Out", style: TextStyle(color: Colors.red)),
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
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                              child: Text(rev.reviewerName.isNotEmpty ? rev.reviewerName[0] : "R", style: const TextStyle(fontSize: 10)),
                            ),
                            const SizedBox(width: 8),
                            Text(rev.reviewerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Row(
                              children: List.generate(
                                rev.rating.toInt(),
                                (_) => const Icon(Icons.star, size: 14, color: Colors.amber),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(rev.comment, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          "Item: ${rev.itemTitle}",
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
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

  Widget _buildStatCol(BuildContext context, String value, String label, Color color) {
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
}
