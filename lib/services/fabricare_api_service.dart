import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/damage_detection.dart';
import '../models/scan_result.dart';
import 'api_config.dart';

class AnalyzeResponse {
  final Map<String, dynamic> json;
  const AnalyzeResponse(this.json);
  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) =>
      AnalyzeResponse(json);
  String get fabricType => json['fabric_type'] as String;
  double? get fabricConfidence =>
      (json['fabric_confidence'] as num?)?.toDouble();
  DamageDetectionResult toDamageDetectionResult() =>
      DamageDetectionResult.fromJson(json['damages'] as List? ?? []);
  ScanResult toScanResult(List<ScanImage> images, String userId,
          {Map<String, dynamic> userInputs = const {}}) =>
      ScanResult(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          userId: userId,
          garmentName: '$fabricType Garment',
          images: images,
          dateScanned: DateTime.now(),
          analysis: json,
          userInputs: Map<String, dynamic>.from(
              json['user_inputs'] as Map? ?? userInputs));
}

class FabricCareApiService {
  FabricCareApiService._();
  static final FabricCareApiService instance = FabricCareApiService._();
  bool isReady = false;
  String? loadError;
  List<String> fabricLabels = [];
  List<String> damageLabels = [];

  Future<void> init() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw Exception('API returned ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      fabricLabels = List<String>.from(body['fabric_labels'] as List? ?? []);
      damageLabels = List<String>.from(body['damage_labels'] as List? ?? []);
      isReady = true;
      loadError = null;
    } catch (e) {
      isReady = false;
      loadError = e.toString();
    }
  }

  // Retain the original single-image API contract for existing callers.
  Future<AnalyzeResponse> analyze(File image) async => AnalyzeResponse.fromJson(
      await _upload('/analyze', [ScanImage(view: 'front', path: image.path)],
          legacy: true));

  Future<List<Map<String, dynamic>>> checkQuality(
      List<ScanImage> images) async {
    final body = await _upload('/quality', images);
    return (body['per_image'] as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  Future<AnalyzeResponse> analyzeImages(List<ScanImage> images,
          {bool allowLowQuality = false,
          Map<String, dynamic> userInputs = const {}}) async =>
      AnalyzeResponse.fromJson(await _upload('/analyze', images, fields: {
        'allow_low_quality': allowLowQuality.toString(),
        'user_inputs': jsonEncode(userInputs)
      }));

  Future<Map<String, dynamic>> _upload(String endpoint, List<ScanImage> images,
      {bool legacy = false, Map<String, String> fields = const {}}) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('${ApiConfig.baseUrl}$endpoint'));
    request.fields.addAll(fields);
    if (!legacy) {
      request.fields['views'] = jsonEncode(images.map((i) => i.view).toList());
    }
    for (final image in images) {
      request.files.add(await http.MultipartFile.fromPath(
          legacy ? 'image' : 'images', image.path));
    }
    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamed)
        .timeout(const Duration(seconds: 30));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Request failed');
    }
    return body;
  }
}
