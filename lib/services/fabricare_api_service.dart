import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/damage_detection.dart';
import 'api_config.dart';

/// Parsed response from POST /analyze (GLCM fabric + YOLO damage).
class AnalyzeResponse {
  final String fabricType;
  final double? fabricConfidence;
  final List<Map<String, dynamic>> damages;
  final int healthScore;
  final String conditionRating;
  final String estimatedLifespan;
  final Map<String, dynamic> careRecommendation;

  const AnalyzeResponse({
    required this.fabricType,
    required this.fabricConfidence,
    required this.damages,
    required this.healthScore,
    required this.conditionRating,
    required this.estimatedLifespan,
    required this.careRecommendation,
  });

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return AnalyzeResponse(
      fabricType: json['fabric_type'] as String,
      fabricConfidence: (json['fabric_confidence'] as num?)?.toDouble(),
      damages: (json['damages'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>(),
      healthScore: (json['health_score'] as num?)?.round() ?? 0,
      conditionRating: json['condition_rating'] as String? ?? 'Not assessed',
      estimatedLifespan: json['estimated_lifespan'] as String? ?? '',
      careRecommendation:
          (json['care_recommendation'] as Map<String, dynamic>?) ?? {},
    );
  }

  DamageDetectionResult toDamageDetectionResult() {
    return DamageDetectionResult(
      stain: _damageItem('stain', 'Stain'),
      pilling: _damageItem('pilling', 'Pilling'),
      hole: _damageItem('hole', 'Hole'),
      needlemark: _damageItem('needlemark', 'Needlemark'),
    );
  }

  DamageItem _damageItem(String id, String label) {
    Map<String, dynamic>? match;
    for (final entry in damages) {
      if ((entry['label'] as String?)?.toLowerCase() == id) {
        match = entry;
        break;
      }
    }

    if (match == null) {
      return DamageItem(
        id: id,
        label: label,
        confidencePercent: 0,
        status: DamageStatus.notDetected,
      );
    }

    final confidence = (match['confidence'] as num?)?.round() ?? 0;
    final statusLabel = match['status'] as String? ?? 'Not detected';
    final status = switch (statusLabel) {
      'Detected' => DamageStatus.detected,
      'Possible' => DamageStatus.possible,
      _ => DamageStatus.notDetected,
    };

    return DamageItem(
      id: id,
      label: label,
      confidencePercent: confidence,
      status: status,
      severity: match['severity'] as String?,
    );
  }
}

/// HTTP client for fabricare_api.py (GLCM decision tree + YOLO damage model).
class FabricCareApiService {
  FabricCareApiService._();
  static final FabricCareApiService instance = FabricCareApiService._();

  bool isReady = false;
  String? loadError;

  AnalyzeResponse? _cachedResponse;
  String? _cachedImagePath;

  Future<void> init() async {
    loadError = null;
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('API returned status ${response.statusCode}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint(
        'FabriCare API ready: ${body['fabric_model']} + ${body['damage_model']}',
      );
      isReady = true;
    } catch (e) {
      isReady = false;
      loadError = e.toString();
      debugPrint('FabriCare API unavailable: $e');
    }
  }

  Future<AnalyzeResponse> analyze(File image) async {
    if (!isReady) {
      throw StateError(
        loadError != null
            ? 'FabriCare API is not reachable.\n\n$loadError'
            : 'FabriCare API is not reachable. Start fabricare_api.py on ${ApiConfig.baseUrl}',
      );
    }

    if (_cachedImagePath == image.path && _cachedResponse != null) {
      return _cachedResponse!;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/analyze'),
    );
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        message = errorBody['error'] as String? ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    final parsed = AnalyzeResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    _cachedImagePath = image.path;
    _cachedResponse = parsed;
    return parsed;
  }

  void clearCache() {
    _cachedImagePath = null;
    _cachedResponse = null;
  }
}
