class Review {
  final String id;
  final String transactionId;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerAvatarUrl;
  final String targetUserId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String itemTitle;

  const Review({
    required this.id,
    required this.transactionId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerAvatarUrl,
    required this.targetUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.itemTitle,
  });
}
