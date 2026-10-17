import 'dart:convert';

typedef FieldValidator = String? Function(String? value);

abstract final class FieldValidators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phoneAllowedPattern = RegExp(r'^\+?[\d\s().-]+$');

  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;

  static FieldValidator maxLength(int max) =>
      (value) => (value?.trim().length ?? 0) > max
      ? 'Máximo de $max caracteres'
      : null;

  /// Accepts money typed as `89,90`, `89.90` or `1.234,56`; empty passes, so
  /// combine with [required] when needed.
  static String? decimal(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return parseDecimal(text) == null ? 'Valor inválido (ex.: 89,90)' : null;
  }

  static final _decimalPattern = RegExp(r'^\d{1,8}(\.\d{1,2})?$');

  /// Normalizes money typed in pt-BR to the API format (`"1234.56"`), or
  /// returns null when it isn't a valid amount.
  static String? parseDecimal(String value) {
    var text = value.trim().replaceAll(' ', '');
    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }
    return _decimalPattern.hasMatch(text) ? text : null;
  }

  static FieldValidator intRange(int min, int max) => (value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number == null || number < min || number > max
        ? 'Informe um número entre $min e $max'
        : null;
  };

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail';
    if (email.length > 255 || !_emailPattern.hasMatch(email)) {
      return 'E-mail inválido';
    }
    return null;
  }

  static String? phone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Informe seu telefone';
    if (!_phoneAllowedPattern.hasMatch(phone)) return 'Telefone inválido';

    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (phone.startsWith('+')) {
      if (!digits.startsWith('55')) return 'Apenas números do Brasil (+55)';
      digits = digits.substring(2);
    } else if (digits.length > 11 && digits.startsWith('55')) {
      digits = digits.substring(2);
    }

    return digits.length == 10 || digits.length == 11
        ? null
        : 'Informe DDD e número';
  }

  static const states = {
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', //
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', //
    'SP', 'SE', 'TO',
  };

  static String zipCodeDigits(String value) =>
      value.replaceAll(RegExp(r'[\s.-]'), '');

  static String? zipCode(String? value) {
    final zipCode = zipCodeDigits(value?.trim() ?? '');
    if (zipCode.isEmpty) return 'Informe o CEP';
    return RegExp(r'^\d{8}$').hasMatch(zipCode)
        ? null
        : 'CEP deve ter 8 dígitos';
  }

  static String? state(String? value) {
    final state = value?.trim().toUpperCase() ?? '';
    if (state.isEmpty) return 'Informe a UF';
    return states.contains(state) ? null : 'UF inválida';
  }

  static String digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  /// Accepts a CPF with or without punctuation and checks its two check
  /// digits.
  static String? cpf(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe seu CPF';
    final cpf = digits(text);
    if (!RegExp(r'^[\d.\s-]+$').hasMatch(text) ||
        cpf.length != 11 ||
        RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'CPF inválido';
    }

    int checkDigit(int length) {
      var sum = 0;
      for (var i = 0; i < length; i++) {
        sum += int.parse(cpf[i]) * (length + 1 - i);
      }
      final rest = sum * 10 % 11;
      return rest == 10 ? 0 : rest;
    }

    return checkDigit(9) == int.parse(cpf[9]) &&
            checkDigit(10) == int.parse(cpf[10])
        ? null
        : 'CPF inválido';
  }

  static String? cardNumber(String? value) {
    final number = (value ?? '').replaceAll(' ', '');
    if (number.isEmpty) return 'Informe o número do cartão';
    return RegExp(r'^\d{13,19}$').hasMatch(number)
        ? null
        : 'Número de cartão inválido';
  }

  /// Reads an expiry typed as `MM/AA` or `MM/AAAA` into a two-digit month and
  /// a four-digit year, or returns null.
  static ({String month, String year})? parseCardExpiry(String value) {
    final match = RegExp(
      r'^(\d{1,2})\s*/\s*(\d{2}|\d{4})$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    final month = int.parse(match.group(1)!);
    if (month < 1 || month > 12) return null;
    final year = match.group(2)!;
    return (
      month: month.toString().padLeft(2, '0'),
      year: year.length == 2 ? '20$year' : year,
    );
  }

  /// A card is valid until the end of its expiry month.
  static FieldValidator cardExpiry([DateTime Function() now = DateTime.now]) =>
      (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Informe a validade';
        final expiry = parseCardExpiry(text);
        if (expiry == null) return 'Use o formato MM/AA';
        final today = now();
        final year = int.parse(expiry.year);
        final month = int.parse(expiry.month);
        return year < today.year || (year == today.year && month < today.month)
            ? 'Cartão vencido'
            : null;
      };

  static String? cvv(String? value) {
    final cvv = value?.trim() ?? '';
    if (cvv.isEmpty) return 'Informe o CVV';
    return RegExp(r'^\d{3,4}$').hasMatch(cvv) ? null : 'CVV inválido';
  }

  static String? password(String? value) {
    final length = utf8.encode(value ?? '').length;
    if (length < 8) return 'A senha deve ter pelo menos 8 caracteres';
    if (length > 72) return 'A senha deve ter no máximo 72 caracteres';
    return null;
  }

  static FieldValidator combine(List<FieldValidator> validators) => (value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  };
}
