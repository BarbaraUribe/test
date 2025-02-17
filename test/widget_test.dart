import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:redparking/screens/ingresar_auto.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('IngresoAutoPage real API tests', () {
    testWidgets('Test input and submit with valid data', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: IngresoAutoPage()));

      final patenteField = find.byKey(Key('patenteInput'));
      await tester.enterText(patenteField, 'ABC1234');

      final submitButton = find.byType(ElevatedButton);
      await tester.tap(submitButton);

      await tester.pumpAndSettle();

      final response = await http.get(Uri.parse('https://<tu-api-id>.execute-api.<region>.amazonaws.com/empresa/1/movimientos/ABC1234'));
      expect(response.statusCode, 200);

      expect(find.text('Detalles del Ingreso'), findsOneWidget);
      expect(find.text('Patente: ABC1234'), findsOneWidget);
    });

    testWidgets('Test error handling on API failure', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: IngresoAutoPage()));

      final patenteField = find.byKey(Key('patenteInput'));
      await tester.enterText(patenteField, 'INVALID123');

      final submitButton = find.byType(ElevatedButton);
      await tester.tap(submitButton);

      await tester.pumpAndSettle();

      final response = await http.get(Uri.parse('https://<tu-api-id>.execute-api.<region>.amazonaws.com/empresa/1/movimientos/INVALID123'));
      expect(response.statusCode, 404);

      expect(find.text('No se encontró el movimiento para la patente ingresada.'), findsOneWidget);
    });

    testWidgets('Test empty input field', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: IngresoAutoPage()));

      final patenteField = find.byKey(Key('patenteInput'));
      await tester.enterText(patenteField, '');

      final submitButton = find.byType(ElevatedButton);
      await tester.tap(submitButton);

      await tester.pumpAndSettle();
      expect(find.text('Por favor, ingrese una patente.'), findsOneWidget);
    });
  });
}
