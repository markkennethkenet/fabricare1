import 'dart:io';

import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/scan_result.dart';

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
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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

/// In-memory app state: profile, scan history, and static care tips.
class AppData extends ChangeNotifier {
  AppData._internal();
  static final AppData instance = AppData._internal();

  final UserProfile profile = UserProfile();

  UserProfile profileFor(User user) => UserProfile.fromUser(user);

  final List<ScanResult> _history = [];
  List<ScanResult> get history => List.unmodifiable(_history.reversed);

  ScanResult buildScanResultFromClassification({
    required File image,
    required String fabricType,
    required int confidencePercent,
    String? garmentName,
  }) {
    final care = _careGuideFor(fabricType);

    final result = ScanResult(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      garmentName: garmentName ?? '$fabricType Garment',
      image: image,
      imageAssetFallback: fabricType,
      dateScanned: DateTime.now(),
      fabricType: fabricType,
      confidencePercent: confidencePercent,
      lifespanRange: care.lifespanRange,
      usageStatus: care.usageStatus,
      washMethod: care.washMethod,
      dryMethod: care.dryMethod,
      ironLevel: care.ironLevel,
      bleachWarning: care.bleachWarning,
      detergentSuggestion: care.detergentSuggestion,
      storageTip: care.storageTip,
      laundryMode: care.laundryMode,
      laundryReason: care.laundryReason,
      riskWarnings: care.riskWarnings,
    );

    _history.add(result);
    notifyListeners();
    return result;
  }

  static _FabricCareGuide _careGuideFor(String fabricType) {
    switch (fabricType.toLowerCase()) {
      case 'cotton':
        return const _FabricCareGuide(
          lifespanRange: '12–24 months with regular use',
          usageStatus: 'Suitable for everyday wear',
          washMethod: 'Normal or gentle wash, cold or warm water',
          dryMethod: 'Tumble dry low or line dry',
          ironLevel: 'Medium-high heat while slightly damp',
          bleachWarning: 'Non-chlorine bleach only when needed',
          detergentSuggestion: 'Standard liquid detergent',
          storageTip: 'Fold or hang in a cool, dry place',
          laundryMode: 'Normal Wash',
          laundryReason: 'Cotton handles standard machine care well.',
          riskWarnings: [
            'Risk of shrinkage in hot water or high heat drying',
          ],
        );
      case 'denim':
        return const _FabricCareGuide(
          lifespanRange: '18–36 months with regular use',
          usageStatus: 'Suitable for regular wear',
          washMethod: 'Normal wash, cold water, inside-out',
          dryMethod: 'Air dry or tumble dry low',
          ironLevel: 'Medium heat if needed',
          bleachWarning: 'Avoid bleach to preserve color',
          detergentSuggestion: 'Standard liquid detergent',
          storageTip: 'Hang or fold; wash inside-out to reduce fading',
          laundryMode: 'Normal Wash',
          laundryReason: 'Denim is durable but fades with harsh washing.',
          riskWarnings: [
            'Risk of color fading with frequent washing',
            'Risk of shrinkage in hot water',
          ],
        );
      case 'polyester':
        return const _FabricCareGuide(
          lifespanRange: '12–24 months with regular use',
          usageStatus: 'Suitable for regular wear',
          washMethod: 'Gentle or normal wash, cold water',
          dryMethod: 'Tumble dry low or air dry',
          ironLevel: 'Low heat, steam if needed',
          bleachWarning: 'Do not use bleach',
          detergentSuggestion: 'Standard liquid detergent',
          storageTip: 'Hang or fold in a cool, dry place',
          laundryMode: 'Gentle Wash',
          laundryReason: 'Polyester can deform or melt under high heat.',
          riskWarnings: [
            'Risk of heat damage from high-temperature drying or ironing',
          ],
        );
      default:
        return _FabricCareGuide(
          lifespanRange: 'Varies by garment use and care',
          usageStatus: 'Follow care label instructions',
          washMethod: 'Check garment care label',
          dryMethod: 'Check garment care label',
          ironLevel: 'Check garment care label',
          bleachWarning: 'Check garment care label',
          detergentSuggestion: 'Mild detergent recommended',
          storageTip: 'Store in a cool, dry place',
          laundryMode: 'Follow care label',
          laundryReason: 'No specific guidance for "$fabricType" in the model.',
          riskWarnings: const [],
        );
    }
  }

  void updateProfile({String? fullName, String? email, String? phone, String? location}) {
    if (fullName != null) profile.fullName = fullName;
    if (email != null) profile.email = email;
    if (phone != null) profile.phone = phone;
    if (location != null) profile.location = location;
    notifyListeners();
  }

  void updateNotes(String id, String notes) {
    final r = _history.firstWhere((e) => e.id == id);
    r.notes = notes;
    notifyListeners();
  }

  void updateScanResult(ScanResult updated) {
    final index = _history.indexWhere((e) => e.id == updated.id);
    if (index >= 0) {
      _history[index] = updated;
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
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

class _FabricCareGuide {
  final String lifespanRange;
  final String usageStatus;
  final String washMethod;
  final String dryMethod;
  final String ironLevel;
  final String bleachWarning;
  final String detergentSuggestion;
  final String storageTip;
  final String laundryMode;
  final String laundryReason;
  final List<String> riskWarnings;

  const _FabricCareGuide({
    required this.lifespanRange,
    required this.usageStatus,
    required this.washMethod,
    required this.dryMethod,
    required this.ironLevel,
    required this.bleachWarning,
    required this.detergentSuggestion,
    required this.storageTip,
    required this.laundryMode,
    required this.laundryReason,
    required this.riskWarnings,
  });
}
