import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/track.dart';

typedef PlaybackCommand = FutureOr<void> Function();
typedef PlaybackSeekCommand = FutureOr<void> Function(Duration position);
typedef PlaybackQueueCommand = FutureOr<void> Function(int index);
typedef PlaybackRepeatCommand = FutureOr<void> Function(String mode);
typedef PlaybackShuffleCommand = FutureOr<void> Function(bool enabled);

abstract interface class PlaybackMediaSession {
  void bind({
    required PlaybackCommand play,
    required PlaybackCommand pause,
    required PlaybackCommand stop,
    required PlaybackCommand next,
    required PlaybackCommand previous,
    required PlaybackSeekCommand seek,
    required PlaybackQueueCommand playQueueIndex,
    required PlaybackRepeatCommand setRepeatMode,
    required PlaybackShuffleCommand setShuffleEnabled,
  });

  void unbind();

  Future<void> publish({
    required List<Track> queue,
    required int currentIndex,
    required bool playing,
    required Duration position,
    required String repeatMode,
    required bool shuffleEnabled,
  });
}

PlaybackMediaSession playbackMediaSession = _NoopPlaybackMediaSession();

Future<void> initializePlaybackMediaSession() async {
  if (!Platform.isAndroid && !Platform.isLinux) return;
  try {
    playbackMediaSession = await AudioService.init<PlaybackMediaSessionHandler>(
      builder: PlaybackMediaSessionHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.linglun.playback',
        androidNotificationChannelName: '音乐播放',
        androidStopForegroundOnPause: false,
        preloadArtwork: true,
      ),
    );
  } on Object catch (error, stackTrace) {
    debugPrint('伶伦：媒体会话初始化失败：$error');
    debugPrintStack(stackTrace: stackTrace);
    playbackMediaSession = _NoopPlaybackMediaSession();
  }
}

class PlaybackMediaSessionHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements PlaybackMediaSession {
  PlaybackCommand? _play;
  PlaybackCommand? _pause;
  PlaybackCommand? _stop;
  PlaybackCommand? _next;
  PlaybackCommand? _previous;
  PlaybackSeekCommand? _seek;
  PlaybackQueueCommand? _playQueueIndex;
  PlaybackRepeatCommand? _setRepeatMode;
  PlaybackShuffleCommand? _setShuffleEnabled;

  String? _publishedTrackId;
  String? _publishedQueueSignature;
  bool? _publishedPlaying;
  DateTime? _lastPositionPublishAt;
  int _publishGeneration = 0;

  @override
  void bind({
    required PlaybackCommand play,
    required PlaybackCommand pause,
    required PlaybackCommand stop,
    required PlaybackCommand next,
    required PlaybackCommand previous,
    required PlaybackSeekCommand seek,
    required PlaybackQueueCommand playQueueIndex,
    required PlaybackRepeatCommand setRepeatMode,
    required PlaybackShuffleCommand setShuffleEnabled,
  }) {
    _play = play;
    _pause = pause;
    _stop = stop;
    _next = next;
    _previous = previous;
    _seek = seek;
    _playQueueIndex = playQueueIndex;
    _setRepeatMode = setRepeatMode;
    _setShuffleEnabled = setShuffleEnabled;
  }

  @override
  void unbind() {
    _play = null;
    _pause = null;
    _stop = null;
    _next = null;
    _previous = null;
    _seek = null;
    _playQueueIndex = null;
    _setRepeatMode = null;
    _setShuffleEnabled = null;
  }

  @override
  Future<void> play() => _invoke(_play);

  @override
  Future<void> pause() => _invoke(_pause);

  @override
  Future<void> stop() => _invoke(_stop);

  @override
  Future<void> skipToNext() => _invoke(_next);

  @override
  Future<void> skipToPrevious() => _invoke(_previous);

  @override
  Future<void> seek(Duration position) async {
    await _seek?.call(position);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _playQueueIndex?.call(index);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _setRepeatMode?.call(repeatMode.name);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _setShuffleEnabled?.call(shuffleMode != AudioServiceShuffleMode.none);
  }

  @override
  Future<void> publish({
    required List<Track> queue,
    required int currentIndex,
    required bool playing,
    required Duration position,
    required String repeatMode,
    required bool shuffleEnabled,
  }) async {
    if (queue.isEmpty || currentIndex < 0 || currentIndex >= queue.length) {
      return;
    }

    final generation = ++_publishGeneration;
    final track = queue[currentIndex];
    final queueSignature = queue.map((item) => item.id).join('\u0000');
    final trackChanged = _publishedTrackId != track.id;
    final playingChanged = _publishedPlaying != playing;
    final now = DateTime.now();
    final shouldPublishPosition =
        trackChanged ||
        playingChanged ||
        _lastPositionPublishAt == null ||
        now.difference(_lastPositionPublishAt!) >= const Duration(seconds: 1);

    if (_publishedQueueSignature != queueSignature) {
      this.queue.add(queue.map(_mediaItemWithoutArtwork).toList());
      _publishedQueueSignature = queueSignature;
    }

    if (trackChanged) {
      final artUri = await _writeArtwork(track);
      if (generation != _publishGeneration) return;
      mediaItem.add(_mediaItemWithoutArtwork(track).copyWith(artUri: artUri));
      _publishedTrackId = track.id;
    }

    if (!shouldPublishPosition) return;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        systemActions: const {MediaAction.seek},
        processingState: AudioProcessingState.ready,
        playing: playing,
        updatePosition: position,
        speed: 1,
        queueIndex: currentIndex,
        repeatMode: _audioServiceRepeatMode(repeatMode),
        shuffleMode: shuffleEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
    _publishedPlaying = playing;
    _lastPositionPublishAt = now;
  }

  Future<void> _invoke(PlaybackCommand? callback) async {
    await callback?.call();
  }

  MediaItem _mediaItemWithoutArtwork(Track track) {
    return MediaItem(
      id: track.id,
      title: track.title,
      album: track.album,
      artist: track.artistNames.join(' / '),
      duration: track.duration,
      playable: track.path != null,
    );
  }

  Future<Uri?> _writeArtwork(Track track) async {
    final bytes = track.coverBytes;
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final directory = await getTemporaryDirectory();
      final artworkDirectory = Directory(
        '${directory.path}/linglun_media_session',
      );
      await artworkDirectory.create(recursive: true);
      final file = File(
        '${artworkDirectory.path}/${track.id.hashCode.toUnsigned(32)}.img',
      );
      if (!await file.exists() || await file.length() != bytes.length) {
        await file.writeAsBytes(bytes, flush: true);
      }
      return file.uri;
    } on Object catch (error, stackTrace) {
      debugPrint('伶伦：写入媒体会话封面失败：$error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  AudioServiceRepeatMode _audioServiceRepeatMode(String mode) {
    return switch (mode) {
      'one' => AudioServiceRepeatMode.one,
      'all' => AudioServiceRepeatMode.all,
      _ => AudioServiceRepeatMode.none,
    };
  }
}

class _NoopPlaybackMediaSession implements PlaybackMediaSession {
  @override
  void bind({
    required PlaybackCommand play,
    required PlaybackCommand pause,
    required PlaybackCommand stop,
    required PlaybackCommand next,
    required PlaybackCommand previous,
    required PlaybackSeekCommand seek,
    required PlaybackQueueCommand playQueueIndex,
    required PlaybackRepeatCommand setRepeatMode,
    required PlaybackShuffleCommand setShuffleEnabled,
  }) {}

  @override
  Future<void> publish({
    required List<Track> queue,
    required int currentIndex,
    required bool playing,
    required Duration position,
    required String repeatMode,
    required bool shuffleEnabled,
  }) async {}

  @override
  void unbind() {}
}
