import 'package:dio/dio.dart';

import 'app_config.dart';
import 'token_store.dart';

/// Error thrown for failed HTTP requests. [message] mirrors the backend
/// `ErrorResponse.message` when available so the UI can show the real cause
/// (e.g. "Email is already registered" or "Invalid credentials").
class ApiException implements Exception {
  final int status;
  final String message;

  const ApiException(this.status, this.message);

  @override
  String toString() => 'ApiException($status): $message';
}

/// Dio-based REST wrapper and the single networking entry point for the app.
///
/// - Base URL comes from `AppConfig.apiBaseUrl` (set via
///   `--dart-define=API_BASE_URL=...`).
/// - JSON request/response support.
/// - Bearer auth: the stored JWT is added to every request via an interceptor;
///   tokens are never logged.
/// - Timeouts (connect/send/receive) surface as typed [ApiException]s with a
///   friendly network message.
/// - Backend `ErrorResponse` bodies are parsed so callers see the real
///   message instead of a generic "API error 400".
class ApiClient {
  ApiClient({TokenStore? tokenStore})
    : _tokenStore = tokenStore ?? MemoryTokenStore() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.json,
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStore.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final TokenStore _tokenStore;
  late final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _run(() => _dio.get<dynamic>(path, queryParameters: queryParameters));

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _run(() => _dio.post<dynamic>(path, data: body));

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _run(() => _dio.put<dynamic>(path, data: body));

  Future<dynamic> delete(String path) => _run(() => _dio.delete<dynamic>(path));

  /// Uploads a single local file to [path] as multipart form data.
  ///
  /// The [fileField] maps to the backend's `@RequestParam` name. The original
  /// file name is forwarded so the server can derive a safe storage name.
  Future<dynamic> postMultipartFile(
    String path,
    String filePath, {
    String fileField = 'file',
  }) {
    final formData = FormData.fromMap({
      fileField: MultipartFile.fromFileSync(filePath),
    });
    return _run(() => _dio.post<dynamic>(
          path,
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        ));
  }

  Future<dynamic> _run(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final status = e.response?.statusCode ?? 0;
    String message = status == 0
        ? 'Network error. Check your connection and try again.'
        : 'API error $status';

    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }
    return ApiException(status, message);
  }
}