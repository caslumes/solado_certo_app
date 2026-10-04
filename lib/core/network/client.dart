abstract class ClientInterface {
  Future<dynamic> get(String url);
  Future<dynamic> post(String url, {Map<String, dynamic>? data});
  Future<void> put(String url, {Map<String, dynamic>? data});
  Future<void> delete(String url);
}
