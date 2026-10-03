import 'package:flutter_test/flutter_test.dart';
import 'package:tica/main.dart';

void main() {
  testWidgets('TicaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TicaApp());
    expect(find.byType(TicaApp), findsOneWidget);
  });
}
