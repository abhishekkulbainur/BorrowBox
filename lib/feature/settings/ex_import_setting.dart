// Flutter Imports
import "package:flutter/material.dart";

// Package Imports
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_symbols_icons/symbols.dart";

// Project Imports
import "package:lendnborrow/core/provider/item_transaction_provider.dart";
import "package:lendnborrow/core/services/native_backup.dart";
import "package:lendnborrow/core/utils/colors.dart";
import "package:lendnborrow/core/utils/extensions.dart";
import "package:lendnborrow/l10n/app_localizations.dart";

class ExImportSetting extends ConsumerStatefulWidget {
  const ExImportSetting({super.key});

  @override
  ConsumerState<ExImportSetting> createState() => _ExImportSettingState();
}

class _ExImportSettingState extends ConsumerState<ExImportSetting> {
  bool _isOperating = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Information / Transparency Note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withAlpha(50),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Symbols.info, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Private Offline Ledger (Local SQLite)",
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "This exports or restores your private offline borrowing records stored locally on this phone. Your cloud marketplace items and borrow requests remain securely synchronized with Google Cloud Firestore.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (_isOperating)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Processing database operation...",
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

        // Export Tile
        ListTile(
          enabled: !_isOperating,
          leading: const Icon(Symbols.save_alt),
          title: Text(localizations.export_db),
          subtitle: Text(localizations.save_backup_to),
          trailing: const Icon(Symbols.chevron_right, size: 20),
          onTap: () async {
            if (_isOperating) return;
            final messenger = ScaffoldMessenger.of(context);
            final errColor = errorColor(context);
            setState(() => _isOperating = true);
            try {
              final result = await NativeBackup.exportWithPicker();
              if (!mounted) return;

              if (result.isSuccess) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: Colors.green[800],
                  ),
                );
              } else if (result.isCancelled) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: errColor,
                  ),
                );
              }
            } catch (e) {
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text("Export failed: $e"),
                  backgroundColor: errColor,
                ),
              );
            } finally {
              if (mounted) setState(() => _isOperating = false);
            }
          },
        ),

        // Import Tile
        ListTile(
          enabled: !_isOperating,
          leading: const Icon(Symbols.restore),
          title: Text(localizations.import_db),
          subtitle: Text(localizations.pick_a_backup_file),
          trailing: const Icon(Symbols.chevron_right, size: 20),
          onTap: () async {
            if (_isOperating) return;
            final messenger = ScaffoldMessenger.of(context);
            final errColor = errorColor(context);

            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                icon: const Icon(
                  Symbols.warning,
                  color: Colors.orange,
                  size: 36,
                ),
                title: Text(localizations.restore_db),
                content: const Text(
                  "Restoring will validate the backup file and replace your private offline SQLite records. Your Cloud Firestore data is unaffected. Proceed?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(localizations.cancel.capitalize()),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(localizations.restore.capitalize()),
                  ),
                ],
              ),
            );

            if (confirm != true || !mounted) return;

            setState(() => _isOperating = true);
            try {
              final result = await NativeBackup.importWithPicker();
              if (!mounted) return;

              if (result.isSuccess) {
                // Refresh local SQLite providers immediately
                ref.invalidate(historyItemsProvider);
                ref.invalidate(lentItemsProvider);
                ref.invalidate(borrowedItemsProvider);

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: Colors.green[800],
                  ),
                );
              } else if (result.isCancelled) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: errColor,
                  ),
                );
              }
            } catch (e) {
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text("Restore failed: $e"),
                  backgroundColor: errColor,
                ),
              );
            } finally {
              if (mounted) setState(() => _isOperating = false);
            }
          },
        ),
      ],
    );
  }
}
