import 'package:solado_certo_app/core/files/upload_file.dart';

abstract class ClientInterface {
  Future<dynamic> get(String url);
  Future<dynamic> post(
    String url, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  });
  Future<dynamic> put(String url, {Map<String, dynamic>? data});
  Future<dynamic> patch(String url, {Map<String, dynamic>? data});
  Future<dynamic> delete(String url);

  /// Sends [file] as the multipart field [field], with [fields] as extra
  /// text fields.
  Future<dynamic> upload(
    String url, {
    String method = 'POST',
    required String field,
    required UploadFile file,
    Map<String, String>? fields,
  });
}
