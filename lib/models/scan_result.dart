import 'dart:io';

import 'damage_detection.dart';

/// Everything produced by one fabric scan — classification, optional condition
/// assessment, care recommendation, laundry mode, and risk warnings.
class ScanResult {
  final String id;
  final String garmentName;
  final File? image; // null when no photo was attached to the scan
  final String imageAssetFallback;
  final DateTime dateScanned;

  // Classification
  final String fabricType;
  final int confidencePercent;

  // Damage detection (YOLO model output — populated after "Analyze Damage")
  final DamageDetectionResult? damageDetection;
  final Set<String> confirmedDamageIds;
  final String? careWarning;
  final String? healthRecommendation;

  // Condition assessment (legacy map — derived from confirmed damages when available)
  final Map<String, String> conditions;

  // Health score — null until user confirms damages and calculates score.
  final int? healthScore; // 0-100
  bool get hasHealthAssessment => healthScore != null;
  bool get hasDamageDetection => damageDetection != null;

  String get healthRating {
    if (healthScore == null) return 'Not assessed';
    if (healthScore! >= 85) return 'Excellent';
    if (healthScore! >= 70) return 'Good';
    if (healthScore! >= 50) return 'Fair';
    return 'Poor';
  }

  String get healthStatusNote {
    if (healthScore == null) {
      return 'Confirm detected damages to calculate fabric health score.';
    }
    if (healthScore! >= 85) return 'Like-new condition. Keep up the current care routine.';
    if (healthScore! >= 70) return 'Still usable but needs proper care.';
    if (healthScore! >= 50) return 'Showing wear — adjust care habits to extend its life.';
    return 'Heavily worn. Consider retiring or repairing this garment.';
  }

  bool get hasConditionAssessment =>
      damageDetection != null || conditions.isNotEmpty;

  // Lifespan
  final String lifespanRange;
  final String usageStatus;

  // Care recommendation
  final String washMethod;
  final String dryMethod;
  final String ironLevel;
  final String bleachWarning;
  final String detergentSuggestion;
  final String storageTip;

  // Laundry mode
  final String laundryMode;
  final String laundryReason;

  // Risk warnings
  final List<String> riskWarnings;

  // Notes / profile
  String notes;

  ScanResult({
    required this.id,
    required this.garmentName,
    this.image,
    this.imageAssetFallback = '',
    required this.dateScanned,
    required this.fabricType,
    required this.confidencePercent,
    this.damageDetection,
    this.confirmedDamageIds = const {},
    this.careWarning,
    this.healthRecommendation,
    this.conditions = const {},
    this.healthScore,
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
    this.notes = '',
  });

  ScanResult copyWith({
    String? id,
    String? garmentName,
    File? image,
    String? imageAssetFallback,
    DateTime? dateScanned,
    String? fabricType,
    int? confidencePercent,
    DamageDetectionResult? damageDetection,
    Set<String>? confirmedDamageIds,
    String? careWarning,
    String? healthRecommendation,
    Map<String, String>? conditions,
    int? healthScore,
    String? lifespanRange,
    String? usageStatus,
    String? washMethod,
    String? dryMethod,
    String? ironLevel,
    String? bleachWarning,
    String? detergentSuggestion,
    String? storageTip,
    String? laundryMode,
    String? laundryReason,
    List<String>? riskWarnings,
    String? notes,
    bool clearDamageDetection = false,
    bool clearHealthScore = false,
  }) {
    return ScanResult(
      id: id ?? this.id,
      garmentName: garmentName ?? this.garmentName,
      image: image ?? this.image,
      imageAssetFallback: imageAssetFallback ?? this.imageAssetFallback,
      dateScanned: dateScanned ?? this.dateScanned,
      fabricType: fabricType ?? this.fabricType,
      confidencePercent: confidencePercent ?? this.confidencePercent,
      damageDetection: clearDamageDetection ? null : (damageDetection ?? this.damageDetection),
      confirmedDamageIds: confirmedDamageIds ?? this.confirmedDamageIds,
      careWarning: careWarning ?? this.careWarning,
      healthRecommendation: healthRecommendation ?? this.healthRecommendation,
      conditions: conditions ?? this.conditions,
      healthScore: clearHealthScore ? null : (healthScore ?? this.healthScore),
      lifespanRange: lifespanRange ?? this.lifespanRange,
      usageStatus: usageStatus ?? this.usageStatus,
      washMethod: washMethod ?? this.washMethod,
      dryMethod: dryMethod ?? this.dryMethod,
      ironLevel: ironLevel ?? this.ironLevel,
      bleachWarning: bleachWarning ?? this.bleachWarning,
      detergentSuggestion: detergentSuggestion ?? this.detergentSuggestion,
      storageTip: storageTip ?? this.storageTip,
      laundryMode: laundryMode ?? this.laundryMode,
      laundryReason: laundryReason ?? this.laundryReason,
      riskWarnings: riskWarnings ?? this.riskWarnings,
      notes: notes ?? this.notes,
    );
  }
}
