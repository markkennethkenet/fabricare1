/// Confidence describes detection certainty. Severity is supplied by the backend.
enum DamageStatus { detected, possible, notDetected }

class DamageItem {
  final String id;
  final String label;
  final int confidencePercent;
  final DamageStatus status;
  final String? severity;
  final double areaRatio;
  final List<double> bbox;
  final int imageIndex;
  final String view;

  const DamageItem(
      {required this.id,
      required this.label,
      required this.confidencePercent,
      required this.status,
      this.severity,
      this.areaRatio = 0,
      this.bbox = const [],
      this.imageIndex = 0,
      this.view = 'front'});

  factory DamageItem.fromJson(Map<String, dynamic> json, int index) =>
      DamageItem(
        id: json['id'] as String? ?? '0:$index',
        label: (json['type'] ?? json['label'] ?? 'Unknown').toString(),
        confidencePercent: (json['confidence'] as num? ?? 0).round(),
        status: json['status'] == 'Detected'
            ? DamageStatus.detected
            : DamageStatus.possible,
        severity: json['severity'] as String?,
        areaRatio: (json['area_ratio'] as num? ?? 0).toDouble(),
        bbox: (json['bbox'] as List? ?? [])
            .map((v) => (v as num).toDouble())
            .toList(),
        imageIndex: (json['image_index'] as num? ?? 0).toInt(),
        view: json['view'] as String? ?? 'front',
      );

  String get statusLabel => switch (status) {
        DamageStatus.detected => 'Detected',
        DamageStatus.possible => 'Possible',
        DamageStatus.notDetected => 'Not detected',
      };
  String get statusDisplay => statusLabel;
  bool get isConfirmable => status != DamageStatus.notDetected;
  bool get defaultConfirmed => status == DamageStatus.detected;
}

/// Every instance is retained, including repeated and future damage classes.
class DamageDetectionResult {
  final List<DamageItem> items;
  const DamageDetectionResult({required this.items});
  factory DamageDetectionResult.fromJson(List<dynamic> values) =>
      DamageDetectionResult(
        items: [
          for (var i = 0; i < values.length; i++)
            DamageItem.fromJson(Map<String, dynamic>.from(values[i] as Map), i)
        ],
      );
  List<DamageItem> get allItems => items;
  List<DamageItem> get confirmableItems =>
      items.where((i) => i.isConfirmable).toList();
  Set<String> get defaultConfirmedIds =>
      items.where((i) => i.defaultConfirmed).map((i) => i.id).toSet();
}
