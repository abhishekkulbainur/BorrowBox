enum CommunityType { apartment, neighborhood, college, hobby, general }

class Community {
  final String id;
  final String name;
  final String description;
  final CommunityType type;
  final String location;
  final int memberCount;
  final int activeItemsCount;
  final bool isPrivate;
  final String icon;
  final bool isJoined;

  const Community({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.location,
    this.memberCount = 1,
    this.activeItemsCount = 0,
    this.isPrivate = false,
    this.icon = "groups",
    this.isJoined = false,
  });

  Community copyWith({bool? isJoined, int? memberCount}) {
    return Community(
      id: id,
      name: name,
      description: description,
      type: type,
      location: location,
      memberCount: memberCount ?? this.memberCount,
      activeItemsCount: activeItemsCount,
      isPrivate: isPrivate,
      icon: icon,
      isJoined: isJoined ?? this.isJoined,
    );
  }

  String get typeDisplay {
    switch (type) {
      case CommunityType.apartment:
        return "Apartment Society";
      case CommunityType.neighborhood:
        return "Neighborhood";
      case CommunityType.college:
        return "College Campus";
      case CommunityType.hobby:
        return "Hobby / Makers";
      case CommunityType.general:
        return "Open Community";
    }
  }
}
