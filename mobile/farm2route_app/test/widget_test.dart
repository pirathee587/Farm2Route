import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm2route_app/app/app.dart';

void main() {
  testWidgets('Farm2RouteApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: Farm2RouteApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.byType(Farm2RouteApp), findsOneWidget);
  });
}
