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
