import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solado_certo_app/common/envs.dart';
import 'package:solado_certo_app/common/network/client.dart';
import 'package:solado_certo_app/config/dependencies.dart';

class ApiClient implements ClientInterface {
  ApiClient._(this.localStorage)
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
          if (e.response?.statusCode != 401) {
            return handler.next(e);
          }

          await refreshToken(handler, e);

          return handler.next(e);
        },
      ),
    );
  }

  final Dio dio;
  final FlutterSecureStorage localStorage;

  static final ApiClient instance = ApiClient._(getIt<FlutterSecureStorage>());

  @override
  Future<void> delete(String url) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<dynamic> get(String url) async {
    Response response = await dio.get(url);
    return response.data;
  }

  @override
  Future<dynamic> post(String url, {Map<String, dynamic>? data}) async {
    Response response = await dio.post(url, data: data);
    return response.data;
  }

  @override
  Future<void> put(String url, {Map<String, dynamic>? data}) {
    // TODO: implement put
    throw UnimplementedError();
  }

  Future<void> attachAuthorizationHeader(RequestOptions options) async {
    final String accessToken = (await localStorage.read(
      key: 'access_token',
    )).toString();
    if (accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
  }

  Future<void> refreshToken(
    ErrorInterceptorHandler handler,
    DioException e,
  ) async {
    final String refreshToken = (await localStorage.read(
      key: 'refresh_token',
    )).toString();
    if (refreshToken.isEmpty) {
      return handler.next(e);
    }

    try {
      final response = await dio.post(
        '/auth/refresh-token',
        data: {'refresh_token': refreshToken},
      );
      final newAccessToken = response.data['access_token'];
      await localStorage.write(key: 'access_token', value: newAccessToken);

      final requestOptions = e.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await dio.fetch(requestOptions);
      return handler.resolve(retryResponse);
    } catch (refreshError) {
      print('Erro ao atualizar token de acesso: $refreshError');
    }
  }
}
