// Flutter Imports
import "package:flutter/material.dart";

// Project Imports
import "package:lendnborrow/core/models/item_transaction.dart";
import "package:lendnborrow/core/widgets/item_transactions_list.dart";
import "package:lendnborrow/l10n/app_localizations.dart";

class BorrowedScreen extends StatelessWidget {
  const BorrowedScreen({super.key});

  static const String path = "/borrowed";

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.borrowed_screen_title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: ItemTransactionsList(type: TransactionType.borrowed),
        ),
      ),
    );
  }
}
