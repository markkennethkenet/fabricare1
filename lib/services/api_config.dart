import 'dart:io';

import 'package:flutter/foundation.dart';

/// Base URL for the FabriCare Python API (GLCM + YOLO).
///
/// - Android emulator: `10.0.2.2` maps to the host machine.
/// - iOS simulator / desktop: use `127.0.0.1`.
/// - Physical device: set [hostOverride] to your PC's LAN IP (e.g. `192.168.1.10`).
class ApiConfig {
  ApiConfig._();

  /// Set this when testing on a physical phone (same Wi‑Fi as the API server).
  static String? hostOverride;

  /// Hosted API URL, including HTTPS (set when building the app).
  static const _hostedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_hostedBaseUrl.isNotEmpty) {
      return _hostedBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    }
    final host = hostOverride ?? _defaultHost;
    return 'http://$host:5000';
  }

  static String get _defaultHost {
    if (kIsWeb) return '127.0.0.1';
    if (Platform.isAndroid) return '10.0.2.2';
    return '127.0.0.1';
  }
}
