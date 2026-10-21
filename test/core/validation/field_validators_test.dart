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

  group('decimal', () {
    test('normalizes money typed in pt-BR or with a point', () {
      expect(FieldValidators.parseDecimal('89,9'), '89.9');
      expect(FieldValidators.parseDecimal(' 89.90 '), '89.90');
      expect(FieldValidators.parseDecimal('1.234,56'), '1234.56');
      expect(FieldValidators.parseDecimal('12'), '12');
    });

    test('rejects what the API would refuse', () {
      expect(FieldValidators.parseDecimal('89,999'), isNull);
      expect(FieldValidators.parseDecimal('-1'), isNull);
      expect(FieldValidators.parseDecimal('abc'), isNull);
      expect(FieldValidators.parseDecimal('123456789'), isNull);
    });

    test('lets an empty value pass', () {
      expect(FieldValidators.decimal(''), isNull);
      expect(FieldValidators.decimal('9,90'), isNull);
      expect(FieldValidators.decimal('9,9,9'), isNotNull);
    });
  });

  test('intRange accepts whole numbers inside the range', () {
    final validator = FieldValidators.intRange(0, 90);
    expect(validator('0'), isNull);
    expect(validator('90'), isNull);
    expect(validator('91'), isNotNull);
    expect(validator('-1'), isNotNull);
    expect(validator('1,5'), isNotNull);
    expect(validator(''), isNotNull);
  });

  group('cpf', () {
    test('accepts valid CPFs with or without the mask', () {
      expect(FieldValidators.cpf('529.982.247-25'), isNull);
      expect(FieldValidators.cpf(' 11144477735 '), isNull);
    });

    test('rejects empty values, wrong check digits and repeated digits', () {
      expect(FieldValidators.cpf(''), 'Informe seu CPF');
      expect(FieldValidators.cpf('529.982.247-24'), 'CPF inválido');
      expect(FieldValidators.cpf('5299822472'), 'CPF inválido');
      expect(FieldValidators.cpf('111.111.111-11'), 'CPF inválido');
      expect(FieldValidators.cpf('529a982b247c25'), 'CPF inválido');
    });
  });

  group('card', () {
    test('number needs 13 to 19 digits, spaces allowed', () {
      expect(FieldValidators.cardNumber('4444 4444 4444 4444'), isNull);
      expect(FieldValidators.cardNumber(''), 'Informe o número do cartão');
      expect(FieldValidators.cardNumber('4444'), 'Número de cartão inválido');
      expect(
        FieldValidators.cardNumber('4444-4444-4444-4444'),
        'Número de cartão inválido',
      );
    });

    test('reads the expiry as MM/AA or MM/AAAA', () {
      expect(FieldValidators.parseCardExpiry('5/30'), (
        month: '05',
        year: '2030',
      ));
      expect(FieldValidators.parseCardExpiry('12 / 2031'), (
        month: '12',
        year: '2031',
      ));
      expect(FieldValidators.parseCardExpiry('13/30'), isNull);
      expect(FieldValidators.parseCardExpiry('0530'), isNull);
    });

    test('a card is valid until the end of its expiry month', () {
      final validator = FieldValidators.cardExpiry(
        () => DateTime(2026, 10, 15),
      );
      expect(validator('10/26'), isNull);
      expect(validator('01/27'), isNull);
      expect(validator('09/26'), 'Cartão vencido');
      expect(validator('1026'), 'Use o formato MM/AA');
      expect(validator(''), 'Informe a validade');
    });

    test('CVV has 3 or 4 digits', () {
      expect(FieldValidators.cvv('123'), isNull);
      expect(FieldValidators.cvv('1234'), isNull);
      expect(FieldValidators.cvv('12'), 'CVV inválido');
      expect(FieldValidators.cvv(''), 'Informe o CVV');
    });
  });

  group('tracking code', () {
    test('is stored without spaces and in upper case', () {
      expect(
        FieldValidators.trackingCode(' aa 123 456 789 br '),
        'AA123456789BR',
      );
    });

    test('Correios codes have two letters, nine digits and BR', () {
      final validator = FieldValidators.trackingCodeFor('Correios (PAC)');
      expect(validator('aa123456789br'), isNull);
      expect(validator('AA 123456789 BR'), isNull);
      expect(validator('AA12345678BR'), isNotNull);
      expect(validator('AA123456789US'), isNotNull);
      expect(validator(''), 'Campo obrigatório');
    });

    test('other carriers take 8 to 40 letters, digits or hyphens', () {
      final validator = FieldValidators.trackingCodeFor('Jadlog');
      expect(validator('10084512345678'), isNull);
      expect(validator('lg-2026-abc'), isNull);
      expect(validator('1234567'), isNotNull);
      expect(validator('A' * 41), isNotNull);
      expect(validator('ABC/12345'), isNotNull);
    });
  });
}
