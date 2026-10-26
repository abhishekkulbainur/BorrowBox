// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:qr_flutter/qr_flutter.dart';

// Project Imports
import 'package:lendnborrow/core/models/borrow_request.dart';

class QrHandoverModal extends StatelessWidget {
  final BorrowRequest request;
  final bool isReturn;
  final VoidCallback onConfirmHandover;

  const QrHandoverModal({
    super.key,
    required this.request,
    this.isReturn = false,
    required this.onConfirmHandover,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final token = isReturn
        ? (request.returnQrToken ?? "BB-RETURN-${request.id}")
        : (request.handoverQrToken ?? "BB-HANDOVER-${request.id}");

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isReturn ? "Return Verification QR" : "Handover Verification QR",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isReturn
                ? "Show this QR code to ${request.ownerName} to verify safe return."
                : "Show this QR code to ${request.borrowerName} to complete handover.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: token,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Token: $token",
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              onConfirmHandover();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              isReturn
                  ? "Confirm Return Verified"
                  : "Confirm Handover Completed",
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
