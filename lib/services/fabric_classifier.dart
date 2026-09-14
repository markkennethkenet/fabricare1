import 'dart:io';

import 'fabricare_api_service.dart';

class FabricResult {
  final String label;
  final double confidencePercent;

  FabricResult({
    required this.label,
    required this.confidencePercent,
  });
}

/// Fabric classification via the Python API (GLCM + decision tree).
/// Replaces the old on-device TFLite model (fabric_classifier.tflite).
class FabricClassifier {
  static final FabricClassifier instance = FabricClassifier._internal();

  FabricClassifier._internal();

  factory FabricClassifier() => instance;

  bool get isReady => FabricCareApiService.instance.isReady;
  String? get loadError => FabricCareApiService.instance.loadError;

  Future<void> loadModel() => FabricCareApiService.instance.init();

  Future<FabricResult> classify(File imageFile) async {
    final response = await FabricCareApiService.instance.analyze(imageFile);
    final confidence = response.fabricConfidence ?? 0;

    return FabricResult(
      label: response.fabricType,
      confidencePercent: confidence,
    );
  }

  Future<Map<String, dynamic>> predict(File imageFile) async {
    final result = await classify(imageFile);
    return {
      'label': result.label,
      'confidence': result.confidencePercent,
    };
  }
}
