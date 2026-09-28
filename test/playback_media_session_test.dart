import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/features/player/application/playback_media_session.dart';
import 'package:linglun/src/features/player/domain/track.dart';

void main() {
  test('媒体会话发布曲目信息并把系统控制转发给播放器', () async {
    final handler = PlaybackMediaSessionHandler();
    var played = false;
    var paused = false;
    var next = false;
    var seekPosition = Duration.zero;
    handler.bind(
      play: () => played = true,
      pause: () => paused = true,
      stop: () {},
      next: () => next = true,
      previous: () {},
      seek: (position) => seekPosition = position,
      playQueueIndex: (_) {},
      setRepeatMode: (_) {},
      setShuffleEnabled: (_) {},
    );

    await handler.publish(
      queue: demoTracks,
      currentIndex: 1,
      playing: true,
      position: const Duration(seconds: 18),
      repeatMode: 'all',
      shuffleEnabled: true,
    );
    await handler.play();
    await handler.pause();
    await handler.skipToNext();
    await handler.seek(const Duration(seconds: 42));

    expect(handler.mediaItem.value?.title, demoTracks[1].title);
    expect(handler.mediaItem.value?.artist, demoTracks[1].artist);
    expect(handler.playbackState.value.playing, isTrue);
    expect(handler.playbackState.value.queueIndex, 1);
    expect(handler.playbackState.value.repeatMode, AudioServiceRepeatMode.all);
    expect(
      handler.playbackState.value.shuffleMode,
      AudioServiceShuffleMode.all,
    );
    expect(played, isTrue);
    expect(paused, isTrue);
    expect(next, isTrue);
    expect(seekPosition, const Duration(seconds: 42));
  });
}
