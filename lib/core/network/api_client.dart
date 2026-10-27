import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solado_certo_app/core/config/envs.dart';
import 'package:solado_certo_app/core/network/client.dart';
import 'package:solado_certo_app/core/files/downloaded_file.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/storage/storage_keys.dart';

class ApiClient implements ClientInterface {
  ApiClient(this.localStorage)
    : dio = Dio(
        BaseOptions(
          baseUrl: Envs.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await attachAuthorizationHeader(options);

          return handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode != 401 ||
              e.requestOptions.path.startsWith('/auth/') ||
              e.requestOptions.extra[_retriedKey] == true) {
            return handler.next(e);
          }

          await refreshToken(handler, e);
        },
      ),
    );
  }

  final Dio dio;
  final FlutterSecureStorage localStorage;

  static final ApiClient instance = ApiClient(getIt<FlutterSecureStorage>());

  @override
  Future<dynamic> delete(String url) async {
    Response response = await dio.delete(url);
    return response.data;
  }

  @override
  Future<dynamic> get(String url) async {
    Response response = await dio.get(url);
    return response.data;
  }

  @override
  Future<DownloadedFile> download(String url) async {
    final Response<List<int>> response = await dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': '*/*'},
        receiveTimeout: _uploadTimeout,
      ),
    );
    return DownloadedFile(
      bytes: response.data ?? const [],
      contentType:
          response.headers.value(Headers.contentTypeHeader) ??
          'application/octet-stream',
    );
  }

  @override
  Future<dynamic> post(
    String url, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    Response response = await dio.post(
      url,
      data: data,
      options: Options(headers: headers),
    );
    return response.data;
  }

  @override
  Future<dynamic> put(String url, {Map<String, dynamic>? data}) async {
    Response response = await dio.put(url, data: data);
    return response.data;
  }

  @override
  Future<dynamic> patch(String url, {Map<String, dynamic>? data}) async {
    Response response = await dio.patch(url, data: data);
    return response.data;
  }

  @override
  Future<dynamic> upload(
    String url, {
    String method = 'POST',
    required String field,
    required UploadFile file,
    Map<String, String>? fields,
  }) async {
    final formData = FormData.fromMap({
      ...?fields,
      field: MultipartFile.fromBytes(file.bytes, filename: file.filename),
    });
    Response response = await dio.request(
      url,
      data: formData,
      options: Options(method: method, sendTimeout: _uploadTimeout),
    );
    return response.data;
  }

  static const _uploadTimeout = Duration(seconds: 60);

  static const _retriedKey = 'retried_after_refresh';

  Future<void> attachAuthorizationHeader(RequestOptions options) async {
    final String accessToken =
        await localStorage.read(key: StorageKeys.accessToken) ?? '';
    if (accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
  }

  Future<String?>? _refreshInFlight;

  Future<String?> _refreshAccessToken() => _refreshInFlight ??=
      _performRefresh().whenComplete(() => _refreshInFlight = null);

  Future<String?> _performRefresh() async {
    final String refreshToken =
        await localStorage.read(key: StorageKeys.refreshToken) ?? '';
    if (refreshToken.isEmpty) {
      return null;
    }

    try {
      final response = await dio.post(
        '/auth/refresh-token',
        data: {'refresh_token': refreshToken},
      );
      final String newAccessToken = response.data['access_token'];
      final newRefreshToken = response.data['refresh_token'];
      await localStorage.write(
        key: StorageKeys.accessToken,
        value: newAccessToken,
      );
      await localStorage.write(
        key: StorageKeys.refreshToken,
        value: newRefreshToken,
      );
      return newAccessToken;
    } catch (refreshError) {
      await localStorage.delete(key: StorageKeys.accessToken);
      await localStorage.delete(key: StorageKeys.refreshToken);
      debugPrint('Erro ao atualizar token de acesso: $refreshError');
      return null;
    }
  }

  Future<void> refreshToken(
    ErrorInterceptorHandler handler,
    DioException e,
  ) async {
    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      return handler.next(e);
    }

    final requestOptions = e.requestOptions;
    requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
    requestOptions.extra[_retriedKey] = true;
    if (requestOptions.data case final FormData formData) {
      requestOptions.data = formData.clone();
    }
    try {
      final retryResponse = await dio.fetch(requestOptions);
      return handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }
}
