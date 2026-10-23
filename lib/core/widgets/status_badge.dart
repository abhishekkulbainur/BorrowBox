// Flutter Imports
import 'package:flutter/material.dart';

// Project Imports
import 'package:lendnborrow/core/models/borrow_request.dart';
import 'package:lendnborrow/core/models/marketplace_item.dart';

class StatusBadge extends StatelessWidget {
  final RequestStatus? requestStatus;
  final ItemAvailability? availability;
  final ItemCondition? condition;

  const StatusBadge.request(this.requestStatus, {super.key})
      : availability = null,
        condition = null;

  const StatusBadge.availability(this.availability, {super.key})
      : requestStatus = null,
        condition = null;

  const StatusBadge.condition(this.condition, {super.key})
      : requestStatus = null,
        availability = null;

  @override
  Widget build(BuildContext context) {
    if (requestStatus != null) {
      return _buildRequestBadge(context, requestStatus!);
    } else if (availability != null) {
      return _buildAvailabilityBadge(context, availability!);
    } else if (condition != null) {
      return _buildConditionBadge(context, condition!);
    }
    return const SizedBox.shrink();
  }

  Widget _buildRequestBadge(BuildContext context, RequestStatus status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case RequestStatus.pending:
        bg = Colors.amber.withAlpha(40);
        fg = Colors.amber[900]!;
        icon = Icons.schedule;
        break;
      case RequestStatus.approved:
      case RequestStatus.handoverPending:
        bg = Colors.blue.withAlpha(40);
        fg = Colors.blue[800]!;
        icon = Icons.qr_code;
        break;
      case RequestStatus.active:
        bg = Colors.green.withAlpha(40);
        fg = Colors.green[800]!;
        icon = Icons.check_circle_outline;
        break;
      case RequestStatus.returnPending:
        bg = Colors.purple.withAlpha(40);
        fg = Colors.purple[800]!;
        icon = Icons.assignment_return;
        break;
      case RequestStatus.returned:
        bg = Colors.teal.withAlpha(40);
        fg = Colors.teal[800]!;
        icon = Icons.done_all;
        break;
      case RequestStatus.rejected:
      case RequestStatus.cancelled:
        bg = Colors.red.withAlpha(40);
        fg = Colors.red[800]!;
        icon = Icons.cancel_outlined;
        break;
      case RequestStatus.overdue:
        bg = Colors.deepOrange.withAlpha(40);
        fg = Colors.deepOrange[900]!;
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge(BuildContext context, ItemAvailability avail) {
    Color bg;
    Color fg;
    String label;

    switch (avail) {
      case ItemAvailability.available:
        bg = Colors.green.withAlpha(35);
        fg = Colors.green[800]!;
        label = "Available";
        break;
      case ItemAvailability.reserved:
        bg = Colors.orange.withAlpha(35);
        fg = Colors.orange[800]!;
        label = "Reserved";
        break;
      case ItemAvailability.borrowed:
        bg = Colors.grey.withAlpha(35);
        fg = Colors.grey[700]!;
        label = "Borrowed";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildConditionBadge(BuildContext context, ItemCondition cond) {
    String text;
    switch (cond) {
      case ItemCondition.likeNew:
        text = "Like New";
        break;
      case ItemCondition.excellent:
        text = "Excellent";
        break;
      case ItemCondition.good:
        text = "Good";
        break;
      case ItemCondition.fair:
        text = "Fair";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
