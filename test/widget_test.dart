import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('KhetChacha splash animation screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger an initial frame.
    await tester.pumpWidget(const MyApp());

    // Verify taglines and action button exist
    expect(find.textContaining('Your Farming Friend'), findsOneWidget);
    expect(find.textContaining('દરેક ખેડૂતનો સાચો સાથી'), findsOneWidget);
    expect(find.textContaining('Ready for Next Step'), findsOneWidget);
  });
}
