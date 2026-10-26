// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/services/community_service.dart';
import 'package:lendnborrow/core/widgets/app_logo.dart';

class CommunitiesScreen extends ConsumerWidget {
  const CommunitiesScreen({super.key});

  static const String path = "/communities";

  IconData _getCommunityIcon(String icon) {
    switch (icon) {
      case "apartment":
        return Symbols.apartment;
      case "handyman":
        return Symbols.handyman;
      case "school":
        return Symbols.school;
      case "diversity_3":
        return Symbols.diversity_3;
      default:
        return Symbols.groups;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final communityService = ref.watch(communityServiceProvider);
    final communities = communityService.allCommunities;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppLogo.icon(size: 28, borderRadius: 6),
            SizedBox(width: 10),
            Text(
              "Local Communities",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Informative header banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withAlpha(80),
                  theme.colorScheme.secondaryContainer.withAlpha(40),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.share_location,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Borrow Closer to Home",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Join your apartment, college, or neighborhood circle to share tools and equipment with nearby peers.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            "Discover Circles & Societies",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...communities.map((comm) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: comm.isJoined
                      ? theme.colorScheme.primary.withAlpha(100)
                      : theme.colorScheme.outlineVariant.withAlpha(50),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: comm.isJoined
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCommunityIcon(comm.icon),
                            color: comm.isJoined
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comm.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      comm.typeDisplay,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    comm.location,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      comm.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "${comm.memberCount} members",
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.inventory_2_outlined, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "${comm.activeItemsCount} items",
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        comm.isJoined
                            ? OutlinedButton(
                                onPressed: () {
                                  communityService.toggleJoinCommunity(comm.id);
                                },
                                child: const Text("Joined ✓"),
                              )
                            : FilledButton(
                                onPressed: () {
                                  communityService.toggleJoinCommunity(comm.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Joined ${comm.name}!"),
                                    ),
                                  );
                                },
                                child: const Text("Join Circle"),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
