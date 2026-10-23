// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/legacy.dart';

// Project Imports
import 'package:lendnborrow/core/models/community.dart';

class CommunityService extends ChangeNotifier {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal() {
    _initSeedCommunities();
  }

  final List<Community> _communities = [];

  List<Community> get allCommunities => List.unmodifiable(_communities);

  void _initSeedCommunities() {
    _communities.addAll([
      const Community(
        id: "comm_greenfield",
        name: "Greenfield Heights Resident Association",
        description:
            "A collaborative apartment community of 450+ flats sharing tools, ladders, party furniture, and children's sports equipment.",
        type: CommunityType.apartment,
        location: "Koramangala, Bangalore",
        memberCount: 230,
        activeItemsCount: 42,
        isPrivate: false,
        icon: "apartment",
        isJoined: true,
      ),
      const Community(
        id: "comm_techmakers",
        name: "Tech Valley Maker Space",
        description:
            "Hardware builders, 3D printing enthusiasts, and electronics tinkerers sharing soldering stations, oscilloscopes, and sensors.",
        type: CommunityType.hobby,
        location: "HSR Layout, Bangalore",
        memberCount: 115,
        activeItemsCount: 38,
        isPrivate: false,
        icon: "handyman",
        isJoined: true,
      ),
      const Community(
        id: "comm_campus_hub",
        name: "Campus Resource Exchange Hub",
        description:
            "College students and lab assistants sharing engineering textbooks, drafters, scientific calculators, and seminar dongles.",
        type: CommunityType.college,
        location: "Engineering Campus North Gate",
        memberCount: 540,
        activeItemsCount: 95,
        isPrivate: false,
        icon: "school",
        isJoined: true,
      ),
      const Community(
        id: "comm_downtown",
        name: "Downtown Sharing Circle",
        description:
            "Neighborhood sharing group for camping gear, travel accessories, high-pressure washers, and seasonal items.",
        type: CommunityType.neighborhood,
        location: "Indiranagar, Bangalore",
        memberCount: 310,
        activeItemsCount: 56,
        isPrivate: false,
        icon: "diversity_3",
        isJoined: false,
      ),
    ]);
  }

  void toggleJoinCommunity(String communityId) {
    final index = _communities.indexWhere((c) => c.id == communityId);
    if (index != -1) {
      final current = _communities[index];
      final newJoined = !current.isJoined;
      _communities[index] = current.copyWith(
        isJoined: newJoined,
        memberCount: newJoined ? current.memberCount + 1 : current.memberCount - 1,
      );
      notifyListeners();
    }
  }

  List<Community> getMyJoinedCommunities() {
    return _communities.where((c) => c.isJoined).toList();
  }
}

final communityServiceProvider = ChangeNotifierProvider<CommunityService>((ref) {
  return CommunityService();
});
