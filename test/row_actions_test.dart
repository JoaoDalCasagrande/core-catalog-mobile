import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core_catalog_mobile/widgets/common.dart';

void main() {
  testWidgets('RowActions chama editar e excluir', (tester) async {
    var edited = 0;
    var deleted = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RowActions(
            onEdit: () => edited++,
            onDelete: () => deleted++,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Editar'));
    await tester.tap(find.byTooltip('Excluir'));
    await tester.tap(find.byTooltip('Excluir'));

    expect(edited, 1);
    expect(deleted, 2);
  });

  testWidgets('confirmDialog devolve true só ao confirmar', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await confirmDialog(
                context,
                title: 'Excluir build',
                message: 'Excluir a build "PC"?',
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir a build "PC"?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
