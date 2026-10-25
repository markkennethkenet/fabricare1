import 'package:fabricare/services/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const configuredUrl = String.fromEnvironment('API_BASE_URL');

  tearDown(() => ApiConfig.hostOverride = null);

  test('app connects to the hosted API unless a URL was configured', () {
    expect(
      ApiConfig.baseUrl,
      configuredUrl.isEmpty
          ? ApiConfig.productionBaseUrl
          : configuredUrl.replaceFirst(RegExp(r'/+$'), ''),
    );
  });

  test('explicit local host works while a configured API URL takes priority',
      () {
    ApiConfig.hostOverride = '192.168.1.42';
    expect(
      ApiConfig.baseUrl,
      configuredUrl.isEmpty
          ? 'http://192.168.1.42:5000'
          : configuredUrl.replaceFirst(RegExp(r'/+$'), ''),
    );
  });
}
