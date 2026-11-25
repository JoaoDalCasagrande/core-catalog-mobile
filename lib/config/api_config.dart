import 'package:flutter/foundation.dart';

/// Endereço da API NestJS (core-catalog), que por padrão roda na porta 3001.
///
/// Ordem de prioridade:
/// 1. Endereço salvo pelo usuário na tela "Servidor da API" (ver Session).
/// 2. `--dart-define=API_URL=http://192.168.0.10:3001` na hora de rodar.
/// 3. Padrão: emulador Android usa 10.0.2.2 (o "localhost" do computador);
///    simulador iOS, web e desktop usam localhost.
class ApiConfig {
  static const _fromEnvironment = String.fromEnvironment('API_URL');

  static String get defaultBaseUrl {
    if (_fromEnvironment.isNotEmpty) return normalize(_fromEnvironment);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001';
    }
    return 'http://localhost:3001';
  }

  /// Remove espaços e a barra final: "http://x:3001/" -> "http://x:3001".
  static String normalize(String url) {
    var value = url.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
