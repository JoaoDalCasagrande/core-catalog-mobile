import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/models.dart';

/// Sessão do usuário: token JWT e endereço da API, salvos no aparelho.
/// Equivale ao `auth_service.ts` do web (localStorage "auth_token").
class Session extends ChangeNotifier {
  Session._();

  static final Session instance = Session._();

  static const _tokenKey = 'auth_token';
  static const _apiUrlKey = 'api_url';

  SharedPreferences? _prefs;
  String? _token;
  SessionUser? _user;
  String _baseUrl = ApiConfig.defaultBaseUrl;
  bool _expired = false;

  String? get token => _token;
  SessionUser? get user => _user;
  String get baseUrl => _baseUrl;
  bool get isAuthenticated => _token != null;

  /// Verdadeiro quando a sessão caiu por token expirado/inválido (HTTP 401).
  bool get expired => _expired;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _baseUrl = _prefs!.getString(_apiUrlKey) ?? ApiConfig.defaultBaseUrl;

    final saved = _prefs!.getString(_tokenKey);
    if (saved != null) {
      final payload = decodeJwtPayload(saved);
      if (payload != null && !_isExpired(payload)) {
        _token = saved;
        _user = _userFrom(payload);
      } else {
        await _prefs!.remove(_tokenKey);
      }
    }
  }

  Future<void> signIn(String token) async {
    final payload = decodeJwtPayload(token);
    _token = token;
    _user = payload != null ? _userFrom(payload) : null;
    _expired = false;
    await _prefs?.setString(_tokenKey, token);
    notifyListeners();
  }

  Future<void> signOut({bool expired = false}) async {
    if (_token == null) return;
    _token = null;
    _user = null;
    _expired = expired;
    await _prefs?.remove(_tokenKey);
    notifyListeners();
  }

  Future<void> setBaseUrl(String? url) async {
    final value = url == null || url.trim().isEmpty
        ? ApiConfig.defaultBaseUrl
        : ApiConfig.normalize(url);
    _baseUrl = value;
    if (url == null || url.trim().isEmpty) {
      await _prefs?.remove(_apiUrlKey);
    } else {
      await _prefs?.setString(_apiUrlKey, value);
    }
    notifyListeners();
  }

  /// Lê o payload do JWT (parte do meio, em base64url) sem validar a assinatura.
  static Map<String, dynamic>? decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final json = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(json);
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      return null;
    }
  }

  static bool _isExpired(Map<String, dynamic> payload) {
    final exp = payload['exp'];
    if (exp is! num) return false;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    return DateTime.now().isAfter(expiresAt);
  }

  static SessionUser? _userFrom(Map<String, dynamic> payload) {
    final sub = payload['sub'];
    if (sub is! num) return null;
    return SessionUser(
      id: sub.toInt(),
      name: '${payload['name'] ?? ''}',
      email: '${payload['email'] ?? ''}',
    );
  }
}
