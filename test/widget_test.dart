import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('KhetChacha splash animation screen renders premium branding and no bottom controls',
      (WidgetTester tester) async {
    // Build our app and trigger an initial frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify premium top brand "Khet" and "चाचा" exist
    expect(find.textContaining('Khet'), findsOneWidget);
    expect(find.textContaining('चाचा'), findsOneWidget);

    // Verify old taglines and action button have been completely removed
    expect(find.textContaining('Your Farming Friend'), findsNothing);
    expect(find.textContaining('દરેક ખેડૂતનો સાચો સાથી'), findsNothing);
    expect(find.textContaining('Ready for Next Step'), findsNothing);
  });
}
