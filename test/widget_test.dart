import 'package:flutter_test/flutter_test.dart';
import 'package:skinit_mobile/app/app.dart';

void main() {
  testWidgets('Doca app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DocaApp());

    expect(find.text('Welcome to Doca'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}