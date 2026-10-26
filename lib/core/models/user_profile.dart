class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String bio;
  final String location;
  final double rating;
  final int reviewCount;
  final int completedLoans;
  final DateTime joinedDate;
  final bool isVerified;
  final bool isAdmin;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio = "",
    this.location = "Local Community",
    this.rating = 5.0,
    this.reviewCount = 0,
    this.completedLoans = 0,
    required this.joinedDate,
    this.isVerified = true,
    this.isAdmin = false,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? bio,
    String? location,
    double? rating,
    int? reviewCount,
    int? completedLoans,
    bool? isVerified,
    bool? isAdmin,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      completedLoans: completedLoans ?? this.completedLoans,
      joinedDate: joinedDate,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'location': location,
      'rating': rating,
      'reviewCount': reviewCount,
      'completedLoans': completedLoans,
      'joinedDate': joinedDate.toIso8601String(),
      'isVerified': isVerified,
      'isAdmin': isAdmin,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      bio: map['bio'] as String? ?? "",
      location: map['location'] as String? ?? "Local Community",
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: map['reviewCount'] as int? ?? 0,
      completedLoans: map['completedLoans'] as int? ?? 0,
      joinedDate: map['joinedDate'] != null
          ? DateTime.parse(map['joinedDate'] as String)
          : DateTime.now(),
      isVerified: map['isVerified'] as bool? ?? true,
      isAdmin: map['isAdmin'] as bool? ?? false,
    );
  }
}
