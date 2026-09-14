import 'dart:io';

import '../models/damage_detection.dart';
import 'fabricare_api_service.dart';

/// Damage detection via the Python API (YOLOv8 best.pt).
class DamageDetector {
  DamageDetector._();
  static final DamageDetector instance = DamageDetector._();

  bool get isReady => FabricCareApiService.instance.isReady;
  String? get loadError => FabricCareApiService.instance.loadError;

  Future<void> loadModel() => FabricCareApiService.instance.init();

  Future<DamageDetectionResult> analyze(File image) async {
    final response = await FabricCareApiService.instance.analyze(image);
    return response.toDamageDetectionResult();
  }
}
