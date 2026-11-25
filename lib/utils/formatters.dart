import 'package:flutter/services.dart';

/// Agrupa os milhares com ponto: 1234567 -> "1.234.567".
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

/// Formata centavos como moeda brasileira: 189900 -> "R$ 1.899,00".
/// Mesmo resultado do `Intl.NumberFormat("pt-BR", { currency: "BRL" })` do web.
String formatMoney(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final reais = groupThousands(abs ~/ 100);
  final centavos = (abs % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}R\$ $reais,$centavos';
}

/// Rótulos da escala da régua: "R$ 0", "R$ 2 mil", "R$ 2,5 mil", "R$ 800,00".
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

/// "1990-01-15T00:00:00.000Z" ou "1990-01-15" -> "15/01/1990".
String formatDateBr(String? iso) {
  if (iso == null || iso.length < 10) return '—';
  final parts = iso.substring(0, 10).split('-');
  if (parts.length != 3) return '—';
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

/// Converte um DateTime para "AAAA-MM-DD" (formato enviado para a API).
String toIsoDate(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$m-$d';
}

/// Iniciais para o avatar: "Fulano da Silva" -> "FD".
String initialsOf(String name) {
  final parts = name.split(' ').where((p) => p.isNotEmpty).take(2);
  return parts.map((p) => p[0]).join().toUpperCase();
}

/// Lê só os dígitos de um texto de moeda: "R$ 8.000,00" -> 800000 centavos.
int parseCents(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}

/// Campo de moeda em que se digita só números: os dois últimos são os centavos
/// (mesmo comportamento dos campos de preço/orçamento do web).
class CentsInputFormatter extends TextInputFormatter {
  /// Limite de dígitos para não estourar o tamanho de um inteiro na API.
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
