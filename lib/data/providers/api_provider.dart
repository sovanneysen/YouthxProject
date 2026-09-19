import '../../core/network/api_client.dart';
import '../../core/network/token_store.dart';

export '../../core/network/api_client.dart' show ApiException;

/// Thin REST facade that repositories call through.
///
/// Internally delegates to the Dio-based [ApiClient] so base URL, bearer auth,
/// timeouts and error handling all live in one place. This class keeps its
/// historical constructor and method signatures so existing repositories and
/// dependency injection keep working unchanged.
class ApiProvider {
  ApiProvider({TokenStore? tokenStore})
    : _client = ApiClient(tokenStore: tokenStore ?? MemoryTokenStore());

  final ApiClient _client;

  Future<dynamic> get(String path) => _client.get(path);

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _client.post(path, body);

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _client.put(path, body);

  Future<dynamic> delete(String path) => _client.delete(path);

  Future<dynamic> postMultipartFile(
    String path,
    String filePath, {
    String fileField = 'file',
  }) => _client.postMultipartFile(path, filePath, fileField: fileField);
}