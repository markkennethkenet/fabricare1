import 'dart:io';
import 'damage_detection.dart';

class ScanImage {
  final String view;
  final String path;
  const ScanImage({required this.view, required this.path});
  File get file => File(path);
  Map<String, dynamic> toJson() => {'view': view, 'path': path};
  factory ScanImage.fromJson(Map<String, dynamic> json) =>
      ScanImage(view: json['view'] as String, path: json['path'] as String);
}

/// Persists the full API response so future classes and fields survive restart.
/// No score, grade, severity or lifespan is computed on the client.
class ScanResult {
  final String id;
  final String userId;
  final String garmentName;
  final List<ScanImage> images;
  final DateTime dateScanned;
  final Map<String, dynamic> analysis;
  final Map<String, dynamic> userInputs;
  String notes;

  ScanResult(
      {required this.id,
      required this.userId,
      required this.garmentName,
      required this.images,
      required this.dateScanned,
      required this.analysis,
      this.userInputs = const {},
      this.notes = ''});

  File? get image => images.isEmpty ? null : images.first.file;
  String get imageAssetFallback => fabricType;
  String get fabricType => analysis['fabric_type'] as String? ?? 'Unknown';
  int get confidencePercent =>
      (analysis['fabric_confidence'] as num? ?? 0).round();
  DamageDetectionResult get damageDetection =>
      DamageDetectionResult.fromJson(analysis['damages'] as List? ?? []);
  int? get healthScore => (analysis['health_score'] as num?)?.round();
  bool get hasHealthAssessment => healthScore != null;
  bool get hasDamageDetection => analysis.containsKey('damages');
  bool get hasConditionAssessment => hasDamageDetection;
  String get healthRating =>
      analysis['condition_rating'] as String? ?? 'Not assessed';
  String get healthStatusNote =>
      'Assessment of visible damage in the supplied images.';
  String get lifespanRange =>
      analysis['estimated_lifespan'] as String? ?? 'Not assessed';
  String get usageStatus =>
      analysis['usage_status'] as String? ?? 'Usage history not supplied';
  Map<String, dynamic> get care =>
      Map<String, dynamic>.from(analysis['care_recommendation'] as Map? ?? {});
  String _care(String key) => care[key] as String? ?? 'Follow care label';
  String get washMethod => _care('care_advice');
  String get dryMethod => _care('dry_method');
  String get ironLevel => _care('iron_level');
  String get bleachWarning => _care('bleach_warning');
  String get detergentSuggestion => _care('detergent');
  String get storageTip => _care('storage');
  String get laundryMode => _care('laundry_mode');
  String get laundryReason => _care('care_advice');
  String? get careWarning => care['risk_warning'] as String?;
  String? get healthRecommendation => care['care_advice'] as String?;
  List<String> get riskWarnings => [if (careWarning != null) careWarning!];

  ScanResult withImages(List<ScanImage> value) => ScanResult(
      id: id,
      userId: userId,
      garmentName: garmentName,
      images: value,
      dateScanned: dateScanned,
      analysis: analysis,
      userInputs: userInputs,
      notes: notes);

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'garment_name': garmentName,
        'images': images.map((i) => i.toJson()).toList(),
        'timestamp': dateScanned.toIso8601String(),
        'analysis': analysis,
        'user_inputs': userInputs,
        'notes': notes
      };
  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        garmentName: json['garment_name'] as String,
        images: (json['images'] as List)
            .map((i) => ScanImage.fromJson(Map<String, dynamic>.from(i as Map)))
            .toList(),
        dateScanned: DateTime.parse(json['timestamp'] as String),
        analysis: Map<String, dynamic>.from(json['analysis'] as Map),
        userInputs:
            Map<String, dynamic>.from(json['user_inputs'] as Map? ?? {}),
        notes: json['notes'] as String? ?? '',
      );
}
