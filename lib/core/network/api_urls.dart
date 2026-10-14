import 'package:solado_certo_app/core/config/envs.dart';

/// Resolves a URL returned by the API against [baseUrl].
///
/// Uploaded files come as paths such as `/files/public/ads/<name>.png`, so the
/// same database row works from the emulator, a device or the browser.
/// Absolute URLs (the seed's placeholders) are returned unchanged.
String resolveApiUrl(String url, {String baseUrl = Envs.apiBaseUrl}) =>
    Uri.parse(baseUrl).resolve(url).toString();
