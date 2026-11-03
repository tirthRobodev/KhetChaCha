import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetchacha/animation/splash_animation_screen.dart';
import 'package:khetchacha/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'helpers/fake_video_player_platform.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    FakeVideoPlayerPlatform.registerWith();
  });

  testWidgets(
    'KhetChacha splash animation screen renders pure intro video without duplicate text overlays or bottom controls',
    (WidgetTester tester) async {
      // Build our app and trigger an initial frame.
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify SplashAnimationScreen is mounted
      expect(find.byType(SplashAnimationScreen), findsOneWidget);

      // 2. Verify VideoPlayer widget is present
      expect(find.byType(VideoPlayer), findsWidgets);

      // 3. Verify no duplicate artificial brand text overlays are drawn over the video
      expect(find.textContaining('Your Farming Friend'), findsNothing);
      expect(find.textContaining('દરેક ખેડૂતનો સાચો સાથી'), findsNothing);
      expect(find.textContaining('Ready for Next Step'), findsNothing);

      // 4. Verify no bottom control buttons or spinners
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'SplashAnimationScreen adapts to different mobile screen sizes (HD, FHD, tall 20:9)',
    (WidgetTester tester) async {
      // 720p HD screen
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: SplashAnimationScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VideoPlayer), findsWidgets);

      // Tall 20:9 FHD+ screen (1080 x 2400)
      tester.view.physicalSize = const Size(1080, 2400);
      await tester.pumpWidget(
        const MaterialApp(home: SplashAnimationScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VideoPlayer), findsWidgets);
    },
  );
}
