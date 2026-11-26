import 'package:flutter/services.dart';

String groupThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  return buffer.toString();
}

String formatMoney(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final reais = groupThousands(abs ~/ 100);
  final centavos = (abs % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}R\$ $reais,$centavos';
}

String formatMark(num cents) {
  final reais = cents / 100;
  if (reais == 0) return 'R\$ 0';
  if (reais >= 1000) {
    final thousands = ((reais / 1000) * 10).round() / 10;
    final whole = thousands.truncate();
    final decimal = ((thousands - whole) * 10).round();
    final text = decimal == 0
        ? groupThousands(whole)
        : '${groupThousands(whole)},$decimal';
    return 'R\$ $text mil';
  }
  return formatMoney(cents.round());
}

String formatDateBr(String? iso) {
  if (iso == null || iso.length < 10) return '—';
  final parts = iso.substring(0, 10).split('-');
  if (parts.length != 3) return '—';
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

String toIsoDate(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$m-$d';
}

String initialsOf(String name) {
  final parts = name.split(' ').where((p) => p.isNotEmpty).take(2);
  return parts.map((p) => p[0]).join().toUpperCase();
}

int parseCents(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}

class CentsInputFormatter extends TextInputFormatter {
  static const maxDigits = 11;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) {
      digits = digits.substring(0, maxDigits);
    }
    final cents = digits.isEmpty ? 0 : int.parse(digits);
    final text = formatMoney(cents);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
