import 'package:flutter_test/flutter_test.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';

void main() {
  group('zipCode', () {
    test('accepts 8 digits with or without the mask', () {
      expect(FieldValidators.zipCode('13010111'), isNull);
      expect(FieldValidators.zipCode(' 13010-111 '), isNull);
      expect(FieldValidators.zipCode('13.010-111'), isNull);
    });

    test('rejects empty, short and non-numeric values', () {
      expect(FieldValidators.zipCode(''), 'Informe o CEP');
      expect(FieldValidators.zipCode('1301011'), isNotNull);
      expect(FieldValidators.zipCode('1301011a'), isNotNull);
    });

    test('strips the mask', () {
      expect(FieldValidators.zipCodeDigits('13.010-111'), '13010111');
    });
  });

  group('state', () {
    test('accepts Brazilian states in any case', () {
      expect(FieldValidators.state('SP'), isNull);
      expect(FieldValidators.state(' rj '), isNull);
    });

    test('rejects empty and unknown states', () {
      expect(FieldValidators.state(''), 'Informe a UF');
      expect(FieldValidators.state('XX'), 'UF inválida');
      expect(FieldValidators.state('SPA'), 'UF inválida');
    });
  });

  group('required', () {
    test('rejects null, empty and blank values', () {
      expect(FieldValidators.required(null), isNotNull);
      expect(FieldValidators.required(''), isNotNull);
      expect(FieldValidators.required('   '), isNotNull);
    });

    test('accepts non-blank values', () {
      expect(FieldValidators.required('Maria'), isNull);
    });
  });

  group('maxLength', () {
    test('counts trimmed characters', () {
      final validator = FieldValidators.maxLength(5);
      expect(validator('  abcde  '), isNull);
      expect(validator('abcdef'), isNotNull);
    });
  });

  group('email', () {
    test('accepts valid addresses with surrounding spaces', () {
      expect(FieldValidators.email('maria@example.com'), isNull);
      expect(FieldValidators.email('  maria@example.com '), isNull);
    });

    test('rejects missing or malformed addresses', () {
      expect(FieldValidators.email(''), isNotNull);
      expect(FieldValidators.email('maria'), isNotNull);
      expect(FieldValidators.email('maria@example'), isNotNull);
      expect(FieldValidators.email('ma ria@example.com'), isNotNull);
    });

    test('rejects addresses longer than 255 characters', () {
      final email = '${'a' * 250}@example.com';
      expect(FieldValidators.email(email), isNotNull);
    });
  });

  group('phone', () {
    test('accepts 10 and 11 digit numbers with common formatting', () {
      expect(FieldValidators.phone('(19) 99999-9999'), isNull);
      expect(FieldValidators.phone('19 3333.4444'), isNull);
      expect(FieldValidators.phone('+55 19 99999-9999'), isNull);
      expect(FieldValidators.phone('5519999999999'), isNull);
    });

    test('rejects wrong lengths, letters and foreign prefixes', () {
      expect(FieldValidators.phone(''), isNotNull);
      expect(FieldValidators.phone('99999-9999'), isNotNull);
      expect(FieldValidators.phone('(19) 9999A-9999'), isNotNull);
      expect(FieldValidators.phone('+1 415 555 0100'), isNotNull);
    });
  });

  group('password', () {
    test('requires between 8 and 72 bytes', () {
      expect(FieldValidators.password('1234567'), isNotNull);
      expect(FieldValidators.password('12345678'), isNull);
      expect(FieldValidators.password('a' * 72), isNull);
      expect(FieldValidators.password('a' * 73), isNotNull);
    });

    test('counts multi-byte characters as bytes, like the backend', () {
      expect(FieldValidators.password('é' * 36), isNull);
      expect(FieldValidators.password('é' * 37), isNotNull);
    });
  });

  group('combine', () {
    test('returns the first error', () {
      final validator = FieldValidators.combine([
        FieldValidators.required,
        FieldValidators.maxLength(3),
      ]);
      expect(validator(''), FieldValidators.required(''));
      expect(validator('abcd'), FieldValidators.maxLength(3)('abcd'));
      expect(validator('abc'), isNull);
    });
  });
}
