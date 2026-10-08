import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/features/profile/data/models/address_model.dart';
import 'package:solado_certo_app/features/profile/data/models/podological_profile_model.dart';
import 'package:solado_certo_app/features/profile/data/models/profile_model.dart';
import 'package:solado_certo_app/features/profile/domain/entities/new_address.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile_update.dart';
import 'package:solado_certo_app/features/profile/domain/enum/footstrike_type.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';

void main() {
  group('ProfileModel', () {
    test('maps API fields to the entity', () {
      final entity = ProfileModel.fromJson({
        'name': 'Maria Souza',
        'email': 'maria@example.com',
        'phone': '19999999999',
        'avatar_url': 'https://example.com/a.png',
      }).toEntity();

      expect(entity.name, 'Maria Souza');
      expect(entity.email, 'maria@example.com');
      expect(entity.phone, '19999999999');
      expect(entity.avatarUrl, 'https://example.com/a.png');
    });

    test('rejects a payload with a missing required field', () {
      expect(
        () => ProfileModel.fromJson({'name': 'Maria'}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  test('profileToJson sends the API field names', () {
    final json = profileToJson(
      ProfileEntity(
        name: 'Maria',
        email: 'maria@example.com',
        phone: '19999999999',
        avatarUrl: '',
      ),
    );

    expect(json, {
      'name': 'Maria',
      'email': 'maria@example.com',
      'phone': '19999999999',
      'avatar_url': '',
    });
  });

  test('newAddressToJson sends the API field names, nulls and country', () {
    final json = newAddressToJson(
      const NewAddress(
        receiver: 'Maria',
        zipCode: '13010111',
        street: 'Rua A',
        number: '10',
        district: 'Centro',
        city: 'Campinas',
        state: 'SP',
        isDefault: true,
      ),
    );

    expect(json, {
      'label': null,
      'receiver': 'Maria',
      'zip_code': '13010111',
      'street': 'Rua A',
      'number': '10',
      'complement': null,
      'district': 'Centro',
      'city': 'Campinas',
      'state': 'SP',
      'country': 'BR',
      'is_default': true,
    });
  });

  group('AddressModel', () {
    Map<String, dynamic> json() => {
      'id': 'a1',
      'label': null,
      'receiver': 'Maria',
      'zip_code': '13000-000',
      'street': 'Rua A',
      'number': '10',
      'complement': null,
      'district': 'Centro',
      'city': 'Campinas',
      'state': 'SP',
      'country': 'BR',
      'is_default': true,
    };

    test('maps API fields, including nullable ones', () {
      final entity = AddressModel.fromJson(json()).toEntity();

      expect(entity.zipCode, '13000-000');
      expect(entity.label, isNull);
      expect(entity.complement, isNull);
      expect(entity.isDefault, isTrue);
    });

    test('defaults is_default to false when absent', () {
      final entity = AddressModel.fromJson(
        json()..remove('is_default'),
      ).toEntity();

      expect(entity.isDefault, isFalse);
    });

    test('rejects a field with the wrong type', () {
      expect(
        () => AddressModel.fromJson(json()..['number'] = 10),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('PodologicalProfileModel', () {
    test('maps an empty profile', () {
      final entity = PodologicalProfileModel.fromJson({
        'footstrike_type': null,
        'clinical_condition': null,
        'obs': null,
        'updated_at': null,
      }).toEntity();

      expect(entity.footstrikeType, isNull);
      expect(entity.painPoints, isEmpty);
      expect(entity.updatedAt, isNull);
    });

    test('parses the footstrike type, pain points and updated_at', () {
      final entity = PodologicalProfileModel.fromJson({
        'footstrike_type': 'pronated',
        'pain_points': [
          {'id': 'p1', 'name': 'Calcanhar', 'description': null},
        ],
        'updated_at': '2026-10-01T12:00:00Z',
      }).toEntity();

      expect(entity.footstrikeType, FootstrikeType.pronated);
      expect(entity.painPoints.single.name, 'Calcanhar');
      expect(entity.updatedAt, DateTime.utc(2026, 10, 1, 12));
    });

    test('ignores a footstrike type the app does not know', () {
      final entity = PodologicalProfileModel.fromJson({
        'footstrike_type': 'pronada',
      }).toEntity();

      expect(entity.footstrikeType, isNull);
    });

    test('podologicalProfileUpdateToJson sends the API field names', () {
      expect(
        podologicalProfileUpdateToJson(
          const PodologicalProfileUpdate(
            footstrikeType: FootstrikeType.supinated,
            painPointIds: ['p1', 'p2'],
            obs: 'corre 3x por semana',
          ),
        ),
        {
          'footstrike_type': 'supinated',
          'pain_point_ids': ['p1', 'p2'],
          'clinical_condition': null,
          'obs': 'corre 3x por semana',
        },
      );
    });
  });
}
