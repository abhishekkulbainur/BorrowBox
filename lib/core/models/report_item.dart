// Flutter / Dart Imports
import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus { pending, reviewed, dismissed, resolved }

class ReportItem {
  final String id;
  final String reporterId;
  final String reporterName;
  final String? targetUserId;
  final String? targetListingId;
  final String? targetListingTitle;
  final String reason;
  final String details;
  final DateTime createdAt;
  final ReportStatus status;

  const ReportItem({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    this.targetUserId,
    this.targetListingId,
    this.targetListingTitle,
    required this.reason,
    required this.details,
    required this.createdAt,
    this.status = ReportStatus.pending,
  });

  factory ReportItem.fromMap(String id, Map<String, dynamic> data) {
    return ReportItem(
      id: id,
      reporterId: data['reporterId'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? 'User',
      targetUserId: data['targetUserId'] as String?,
      targetListingId: data['targetListingId'] as String?,
      targetListingTitle: data['targetListingTitle'] as String?,
      reason: data['reason'] as String? ?? 'General Concern',
      details: data['details'] as String? ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: ReportStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String? ?? 'pending'),
        orElse: () => ReportStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      'targetUserId': targetUserId,
      'targetListingId': targetListingId,
      'targetListingTitle': targetListingTitle,
      'reason': reason,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status.name,
    };
  }

  String get type => targetListingId != null ? 'item' : 'user';
}
