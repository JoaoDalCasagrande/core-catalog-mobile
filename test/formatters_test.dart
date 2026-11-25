import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core_catalog_mobile/utils/formatters.dart';

void main() {
  group('formatMoney', () {
    test('formata centavos em reais (pt-BR)', () {
      expect(formatMoney(0), 'R\$ 0,00');
      expect(formatMoney(99), 'R\$ 0,99');
      expect(formatMoney(189900), 'R\$ 1.899,00');
      expect(formatMoney(800000), 'R\$ 8.000,00');
      expect(formatMoney(123456789), 'R\$ 1.234.567,89');
      expect(formatMoney(-5000), '-R\$ 50,00');
    });
  });

  group('formatMark', () {
    test('rótulos da escala da régua', () {
      expect(formatMark(0), 'R\$ 0');
      expect(formatMark(200000), 'R\$ 2 mil');
      expect(formatMark(250000), 'R\$ 2,5 mil');
      expect(formatMark(80000), 'R\$ 800,00');
    });
  });

  test('formatDateBr', () {
    expect(formatDateBr('1990-01-15T00:00:00.000Z'), '15/01/1990');
    expect(formatDateBr('2003-05-10'), '10/05/2003');
    expect(formatDateBr(null), '—');
  });

  test('initialsOf', () {
    expect(initialsOf('Fulano da Silva'), 'FD');
    expect(initialsOf('joão'), 'J');
  });

  test('parseCents lê só os dígitos', () {
    expect(parseCents('R\$ 8.000,00'), 800000);
    expect(parseCents(''), 0);
  });

  test('CentsInputFormatter: os dois últimos dígitos são centavos', () {
    final formatter = CentsInputFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '189900'),
    );
    expect(result.text, 'R\$ 1.899,00');
  });
}
