/// Damage detection status derived from model confidence.
enum DamageStatus {
  detected,
  possible,
  notDetected,
}

/// A single damage type detected (or not) by the YOLO damage model.
class DamageItem {
  final String id;
  final String label;
  final int confidencePercent;
  final DamageStatus status;
  final String? severity;

  const DamageItem({
    required this.id,
    required this.label,
    required this.confidencePercent,
    required this.status,
    this.severity,
  });

  static DamageStatus statusFromConfidence(int confidence) {
    if (confidence >= 80) return DamageStatus.detected;
    if (confidence >= 60) return DamageStatus.possible;
    return DamageStatus.notDetected;
  }

  String get statusLabel {
    switch (status) {
      case DamageStatus.detected:
        return 'Detected';
      case DamageStatus.possible:
        return 'Possible';
      case DamageStatus.notDetected:
        return 'Not detected';
    }
  }

  String get statusDisplay {
    switch (status) {
      case DamageStatus.detected:
        return 'Detected';
      case DamageStatus.possible:
        return 'Possible detection';
      case DamageStatus.notDetected:
        return 'Not detected';
    }
  }

  bool get isConfirmable => status != DamageStatus.notDetected;

  bool get defaultConfirmed => status == DamageStatus.detected;
}

/// Full damage detection output for one fabric scan.
class DamageDetectionResult {
  final DamageItem stain;
  final DamageItem pilling;
  final DamageItem hole;
  final DamageItem needlemark;

  const DamageDetectionResult({
    required this.stain,
    required this.pilling,
    required this.hole,
    required this.needlemark,
  });

  List<DamageItem> get allItems => [stain, pilling, hole, needlemark];

  List<DamageItem> get confirmableItems =>
      allItems.where((item) => item.isConfirmable).toList();

  Set<String> get defaultConfirmedIds =>
      allItems.where((item) => item.defaultConfirmed).map((e) => e.id).toSet();
}

/// Health score output after user confirms detected damages.
class FabricHealthAssessment {
  final int healthScore;
  final String conditionRating;
  final String lifespanRange;
  final String careWarning;
  final String recommendation;
  final Set<String> confirmedDamageIds;

  const FabricHealthAssessment({
    required this.healthScore,
    required this.conditionRating,
    required this.lifespanRange,
    required this.careWarning,
    required this.recommendation,
    required this.confirmedDamageIds,
  });
}
