import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Test mock implementation of [VideoPlayerPlatform] for headless Flutter widget tests.
///
/// Emits mock initialization events to allow [VideoPlayerController] to initialize
/// and render in tests without requiring native Android/iOS platform channels.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _controllers = {};
  int _nextPlayerId = 1;

  /// Registers [FakeVideoPlayerPlatform] as the active platform interface.
  static void registerWith() {
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  }

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    final id = _nextPlayerId++;
    _controllers[id] = StreamController<VideoEvent>.broadcast();
    return id;
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    return create(options.dataSource);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final controller = _controllers[playerId] ??=
        StreamController<VideoEvent>.broadcast();
    scheduleMicrotask(() {
      if (!controller.isClosed) {
        controller.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(seconds: 3),
            size: const Size(1920, 1080),
          ),
        );
      }
    });
    return controller.stream;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildView(int playerId) => const SizedBox(width: 1920, height: 1080);

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox(width: 1920, height: 1080);

  @override
  Future<void> dispose(int playerId) async {
    await _controllers[playerId]?.close();
    _controllers.remove(playerId);
  }
}
