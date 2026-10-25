import 'package:path_provider/path_provider.dart';

import '../models/scan_result.dart';
import '../services/history_store.dart';

import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/fabricare_api_service.dart';

class FabricTip {
  final String title;
  final String fabricType;
  final IconData icon;
  final List<String> points;
  const FabricTip({
    required this.title,
    required this.fabricType,
    required this.icon,
    required this.points,
  });
}

class UserProfile {
  String fullName;
  String email;
  String phone;
  String location;

  UserProfile({
    this.fullName = 'Mark',
    this.email = 'mark@email.com',
    this.phone = '',
    this.location = 'Davao Region, Philippines',
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.first.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
  }

  factory UserProfile.fromUser(User user) {
    return UserProfile(
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      location: user.location,
    );
  }
}

/// Profile, persistent account-scoped scan history, and static care tips.
class AppData extends ChangeNotifier {
  AppData._internal();
  static final AppData instance = AppData._internal();

  final UserProfile profile = UserProfile();

  UserProfile profileFor(User user) => UserProfile.fromUser(user);

  HistoryStore? _store;
  String? _userId;
  String? get activeUserId => _userId;
  String? storageError;
  List<ScanResult> get history => _store != null && _userId != null
      ? List.unmodifiable(_store!.forUser(_userId!))
      : const [];

  Future<void> init() async {
    try {
      _store = HistoryStore(await getApplicationSupportDirectory());
      await _store!.open();
    } catch (e) {
      _store = null;
      storageError = 'Could not open scan history: $e';
    }
  }

  void setUserId(String? value) {
    _userId = value;
    notifyListeners();
  }

  Future<ScanResult> addAnalysis(
      List<ScanImage> images, AnalyzeResponse response,
      {Map<String, dynamic> userInputs = const {},
      String? expectedUserId}) async {
    if (_store == null) {
      throw StateError(storageError ?? 'History storage unavailable');
    }
    final userId = _userId;
    if (userId == null) throw StateError('Sign in before saving a scan');
    if (expectedUserId != null && expectedUserId != userId) {
      throw StateError('Account changed during scan. Please scan again.');
    }
    final result = await _store!
        .add(response.toScanResult(images, userId, userInputs: userInputs));
    notifyListeners();
    return result;
  }

  void updateProfile(
      {String? fullName, String? email, String? phone, String? location}) {
    if (fullName != null) profile.fullName = fullName;
    if (email != null) profile.email = email;
    if (phone != null) profile.phone = phone;
    if (location != null) profile.location = location;
    notifyListeners();
  }

  Future<void> updateNotes(String id, String notes) async {
    final result = history.firstWhere((s) => s.id == id);
    result.notes = notes;
    await _store!.put(result);
    notifyListeners();
  }

  Future<void> deleteScan(String id) async {
    if (_store == null || _userId == null) return;
    await _store!.delete(_userId!, id);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    if (_store == null || _userId == null) return;
    await _store!.clear(_userId!);
    notifyListeners();
  }

  static const tips = <FabricTip>[
    FabricTip(
      title: 'How to care for Cotton',
      fabricType: 'Cotton',
      icon: Icons.crop_square_rounded,
      points: [
        'Wash in cold or warm water to prevent shrinkage.',
        'Tumble dry low or line dry to preserve shape.',
        'Iron on medium-high heat while slightly damp.',
      ],
    ),
    FabricTip(
      title: 'How to care for Silk',
      fabricType: 'Silk',
      icon: Icons.water_drop_outlined,
      points: [
        'Hand wash in cold water with a mild detergent.',
        'Never wring — roll in a towel to remove excess water.',
        'Air dry away from direct sunlight.',
      ],
    ),
    FabricTip(
      title: 'How to care for Denim',
      fabricType: 'Denim',
      icon: Icons.checkroom_outlined,
      points: [
        'Wash inside-out in cold water to protect color.',
        'Avoid frequent washing — spot clean when possible.',
        'Air dry to prevent shrinkage and fiber stress.',
      ],
    ),
    FabricTip(
      title: 'How to prevent fading',
      fabricType: 'General',
      icon: Icons.wb_sunny_outlined,
      points: [
        'Wash dark garments inside-out.',
        'Use cold water and a detergent made for colors.',
        'Dry away from direct sunlight.',
      ],
    ),
    FabricTip(
      title: 'How to avoid shrinkage',
      fabricType: 'General',
      icon: Icons.compress_rounded,
      points: [
        'Check the care label before using hot water or high heat.',
        'Prefer air drying for natural fibers like cotton and wool.',
        'Avoid over-drying in the dryer.',
      ],
    ),
    FabricTip(
      title: 'How to remove stains safely',
      fabricType: 'General',
      icon: Icons.cleaning_services_outlined,
      points: [
        'Treat stains as soon as possible — don\'t let them set.',
        'Blot, don\'t rub, to avoid spreading the stain.',
        'Test any stain remover on a hidden area first.',
      ],
    ),
  ];
}
