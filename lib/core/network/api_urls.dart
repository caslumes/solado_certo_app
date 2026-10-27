import 'package:solado_certo_app/core/config/envs.dart';

String resolveApiUrl(String url, {String baseUrl = Envs.apiBaseUrl}) =>
    Uri.parse(baseUrl).resolve(url).toString();
