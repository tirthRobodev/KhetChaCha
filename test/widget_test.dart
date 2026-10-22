import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/main.dart';

void main() {
  testWidgets('KhetChacha splash animation screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger an initial frame.
    await tester.pumpWidget(const MyApp());

    // Verify brand title elements exist
    expect(find.text('Khet', findRichText: true), findsOneWidget);
    expect(find.text('चाचा', findRichText: true), findsOneWidget);
  });
}


