import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/app_config.dart';
import '../../core/network/token_store.dart';

/// Error thrown for non-2xx HTTP responses. [message] mirrors the backend
/// `ErrorResponse.message` when available so the UI can show the real cause
/// (e.g. "Email is already registered" or "Invalid credentials").
class ApiException implements Exception {
  final int status;
  final String message;

  const ApiException(this.status, this.message);

  @override
  String toString() => 'ApiException($status): $message';
}

/// Thin REST wrapper. Repositories call through this instead of `http`
/// directly so swapping base URL / adding auth headers happens in one place.
class ApiProvider {
  ApiProvider({TokenStore? tokenStore})
    : _tokenStore = tokenStore ?? MemoryTokenStore();

  final http.Client _client = http.Client();
  final TokenStore _tokenStore;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStore.read();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final headers = await _headers();
    final res = await _client.get(_uri(path), headers: headers);
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    final res = await _client.post(
      _uri(path),
      headers: headers,
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    final res = await _client.put(
      _uri(path),
      headers: headers,
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final headers = await _headers();
    final res = await _client.delete(_uri(path), headers: headers);
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    throw _error(res);
  }

  ApiException _error(http.Response res) {
    String message = 'API error ${res.statusCode}';
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        message = decoded['message'] as String;
      }
    } catch (_) {
      // keep the generic fallback when the body isn't a JSON ErrorResponse
    }
    return ApiException(res.statusCode, message);
  }
}
