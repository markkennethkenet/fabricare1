import '../models/damage_detection.dart';
import '../models/scan_result.dart';

/// MAG Computes SA fabric health score, lifespan, and care guidance from confirmed damages.
class HealthScoreCalculator {
  HealthScoreCalculator._();

  static FabricHealthAssessment calculate({
    required ScanResult scan,
    required DamageDetectionResult damage,
    required Set<String> confirmedIds,
  }) {
    var score = 100;

    for (final item in damage.allItems) {
      if (!confirmedIds.contains(item.id)) continue;
      score -= _deductionFor(item);
    }

    score = score.clamp(35, 100);
    final rating = _ratingFor(score);
    final lifespan = _lifespanFor(score, confirmedIds, scan.fabricType);
    final careWarning = _careWarning(confirmedIds);
    final recommendation = _recommendation(scan, confirmedIds, score);

    return FabricHealthAssessment(
      healthScore: score,
      conditionRating: rating,
      lifespanRange: lifespan,
      careWarning: careWarning,
      recommendation: recommendation,
      confirmedDamageIds: Set.unmodifiable(confirmedIds),
    );
  }

  static int _deductionFor(DamageItem item) {
    final base = switch (item.id) {
      'stain' => 12,
      'pilling' => 8,
      'hole' => 28,
      'needlemark' => 14,
      _ => 10,
    };

    final severityMultiplier = switch (item.severity?.toLowerCase()) {
      'high' => 1.3,
      'moderate' => 1.0,
      'mild' => 0.7,
      _ => 1.0,
    };

    return (base * severityMultiplier).round();
  }

  static String _ratingFor(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Poor';
  }

  static String _lifespanFor(int score, Set<String> confirmed, String fabricType) {
    if (confirmed.contains('hole')) return '3–6 months';
    if (score >= 85) return _baseLifespan(fabricType, long: true);
    if (score >= 70) return '12–18 months';
    if (score >= 50) return '6–12 months';
    return '3–6 months';
  }

  static String _baseLifespan(String fabricType, {required bool long}) {
    switch (fabricType.toLowerCase()) {
      case 'denim':
        return long ? '24–36 months' : '18–24 months';
      case 'polyester':
        return long ? '18–24 months' : '12–18 months';
      default:
        return long ? '18–24 months' : '12–18 months';
    }
  }

  static String _careWarning(Set<String> confirmed) {
    final warnings = <String>[];

    if (confirmed.contains('stain')) {
      warnings.add('Treat stains promptly before washing');
    }
    if (confirmed.contains('pilling')) {
      warnings.add('Use a fabric shaver and wash inside-out to reduce pilling, Use Razor');
    }
    if (confirmed.contains('hole')) {
      warnings.add('Repair holes soon to prevent further tearing');
    }
    if (confirmed.contains('needlemark')) {
      warnings.add('Avoid pulling or stretching around needlemark areas');
    }

    if (warnings.isEmpty) {
      return 'Maintain gentle washing habits to preserve fabric quality.';
    }

    return 'Avoid strong washing and high heat to prevent further fabric damage. '
        '${warnings.join('. ')}.';
  }

  static String _recommendation(ScanResult scan, Set<String> confirmed, int score) {
    final parts = <String>[];

    if (score < 70 || confirmed.isNotEmpty) {
      parts.add('Use gentle wash');
    } else {
      parts.add(scan.washMethod.split(',').first.trim());
    }

    if (confirmed.contains('stain') || confirmed.contains('pilling')) {
      parts.add('avoid harsh detergent, Avoid color bleach on color, Avoid Rubbing, Avoid putting it in hot water');
    }

    if (confirmed.contains('hole') || confirmed.contains('needlemark')) {
      parts.add('air dry when possible');
    } else {
      parts.add('avoid high heat');
    }

    if (confirmed.isEmpty && score >= 85) {
      return '${scan.washMethod}. ${scan.storageTip}.';
    }

    return '${parts.join('. ')}.';
  }
}
