import 'package:solado_certo_app/core/files/downloaded_file.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';

abstract class ClientInterface {
  Future<dynamic> get(String url);
  Future<DownloadedFile> download(String url);
  Future<dynamic> post(
    String url, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  });
  Future<dynamic> put(String url, {Map<String, dynamic>? data});
  Future<dynamic> patch(String url, {Map<String, dynamic>? data});
  Future<dynamic> delete(String url);

  Future<dynamic> upload(
    String url, {
    String method = 'POST',
    required String field,
    required UploadFile file,
    Map<String, String>? fields,
  });
}
