import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'session.dart';

/// Erro devolvido pela API (ou de conexão), com a mensagem pronta para a tela.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

/// Cliente HTTP genérico: monta a URL, envia o Bearer token e trata erros
/// do mesmo jeito que o web (junta `message` quando vem como lista).
class ApiClient {
  ApiClient(this.session, {http.Client? client})
      : _client = client ?? http.Client();

  final Session session;
  final http.Client _client;

  static const _timeout = Duration(seconds: 15);

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  Future<dynamic> patch(String path, [Object? body]) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, {Object? body}) async {
    final token = session.token;

    http.Response response;
    try {
      final request =
          http.Request(method, Uri.parse('${session.baseUrl}$path'));
      request.headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        'A API demorou para responder. Verifique o endereço do servidor.',
      );
    } catch (_) {
      throw const ApiException(
        'Erro de conexão. Verifique se a API está rodando.',
      );
    }

    // O corpo pode vir vazio (ex.: GET /profiles/me sem perfil responde null)
    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    dynamic data;
    if (text.trim().isNotEmpty) {
      try {
        data = jsonDecode(text);
      } catch (_) {
        data = text;
      }
    }

    final status = response.statusCode;
    if (status >= 200 && status < 300) return data;

    // Token expirado ou inválido: encerra a sessão, como o web faz no 401
    if (status == 401 && token != null) {
      await session.signOut(expired: true);
      throw const ApiException(
        'Sua sessão expirou. Entre novamente.',
        statusCode: 401,
      );
    }

    throw ApiException(_messageFrom(data, status), statusCode: status);
  }

  static String _messageFrom(dynamic data, int status) {
    if (status >= 500) {
      return 'Erro interno na API ($status). Confira os dados: o registro pode já existir.';
    }
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) return message.join(', ');
      return '$message';
    }
    if (data is String && data.isNotEmpty) return data;
    return 'Não foi possível concluir a operação ($status).';
  }
}
