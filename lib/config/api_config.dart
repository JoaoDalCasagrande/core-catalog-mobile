import 'package:flutter/foundation.dart';

class ApiConfig {
  static const _fromEnvironment = String.fromEnvironment('API_URL');

  static String get defaultBaseUrl {
    if (_fromEnvironment.isNotEmpty) return normalize(_fromEnvironment);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001';
    }
    return 'http://localhost:3001';
  }

  static String normalize(String url) {
    var value = url.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
