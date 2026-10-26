enum RequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
  handoverPending,
  active,
  returnPending,
  returned,
  overdue,
}

class BorrowRequest {
  final String id;
  final String listingId;
  final String itemTitle;
  final String? itemImageUrl;
  final String borrowerId;
  final String borrowerName;
  final String? borrowerAvatarUrl;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatarUrl;
  final DateTime requestDate;
  final DateTime startDate;
  final DateTime endDate;
  final RequestStatus status;
  final String? message;
  final String? handoverQrToken;
  final String? returnQrToken;
  final String? notes;
  final double? depositAmount;

  const BorrowRequest({
    required this.id,
    required this.listingId,
    required this.itemTitle,
    this.itemImageUrl,
    required this.borrowerId,
    required this.borrowerName,
    this.borrowerAvatarUrl,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatarUrl,
    required this.requestDate,
    required this.startDate,
    required this.endDate,
    this.status = RequestStatus.pending,
    this.message,
    this.handoverQrToken,
    this.returnQrToken,
    this.notes,
    this.depositAmount,
  });

  BorrowRequest copyWith({
    String? id,
    RequestStatus? status,
    String? handoverQrToken,
    String? returnQrToken,
    String? notes,
    bool clearHandoverToken = false,
    bool clearReturnToken = false,
  }) {
    return BorrowRequest(
      id: id ?? this.id,
      listingId: listingId,
      itemTitle: itemTitle,
      itemImageUrl: itemImageUrl,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowerAvatarUrl: borrowerAvatarUrl,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerAvatarUrl: ownerAvatarUrl,
      requestDate: requestDate,
      startDate: startDate,
      endDate: endDate,
      status: status ?? this.status,
      message: message,
      handoverQrToken: clearHandoverToken
          ? null
          : (handoverQrToken ?? this.handoverQrToken),
      returnQrToken: clearReturnToken
          ? null
          : (returnQrToken ?? this.returnQrToken),
      notes: notes ?? this.notes,
      depositAmount: depositAmount,
    );
  }

  String get statusDisplay {
    switch (status) {
      case RequestStatus.pending:
        return "Requested";
      case RequestStatus.approved:
        return "Approved";
      case RequestStatus.rejected:
        return "Declined";
      case RequestStatus.cancelled:
        return "Cancelled";
      case RequestStatus.handoverPending:
        return "Ready for Handover";
      case RequestStatus.active:
        return "Active Loan";
      case RequestStatus.returnPending:
        return "Return Pending";
      case RequestStatus.returned:
        return "Returned";
      case RequestStatus.overdue:
        return "Overdue";
    }
  }

  int get durationDays {
    final diff = endDate.difference(startDate).inDays;
    return diff <= 0 ? 1 : diff;
  }
}
