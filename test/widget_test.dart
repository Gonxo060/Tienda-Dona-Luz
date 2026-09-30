import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_dona_luz/main.dart';

void main() {
  testWidgets(
    'Tienda Doña Luz muestra el splash y luego el inicio',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TiendaDonaLuzApp());

      expect(find.text('Tienda Doña Luz'), findsOneWidget);
      expect(
        find.text('Todo lo que necesitas, cerca de ti'),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 2400));
      await tester.pumpAndSettle();

      expect(find.text('Buenos días ??'), findsOneWidget);
      expect(find.text('Ventas de hoy'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Acciones rápidas'),
        500,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Acciones rápidas'), findsOneWidget);
    },
  );
}

