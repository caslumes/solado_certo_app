import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/features/auth/data/models/auth_tokens_model.dart';

void main() {
  test('maps token fields to the entity', () {
    final entity = AuthTokensModel.fromJson({
      'access_token': 'access',
      'refresh_token': 'refresh',
    }).toEntity();

    expect(entity.accessToken, 'access');
    expect(entity.refreshToken, 'refresh');
  });

  test('keeps missing tokens as null for the use case to reject', () {
    final entity = AuthTokensModel.fromJson({}).toEntity();

    expect(entity.accessToken, isNull);
    expect(entity.refreshToken, isNull);
  });
}
