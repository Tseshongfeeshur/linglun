import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/player_controller.dart';
import '../domain/lyrics.dart';

class LyricsPage extends ConsumerStatefulWidget {
  const LyricsPage({super.key});

  @override
  ConsumerState<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends ConsumerState<LyricsPage> {
  final _scrollController = ScrollController();
  String? _trackId;
  int _activeLine = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerControllerProvider);
    final track = player.currentTrack;
    final document = track.lyricsDocument;
    final currentLine = _lineAt(document, player.position);
    final lyricPosition = player.position - document.offset;

    if (_trackId != track.id) {
      _trackId = track.id;
      _activeLine = currentLine;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToLine(currentLine);
      });
    } else if (_activeLine != currentLine && currentLine >= 0) {
      _activeLine = currentLine;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToLine(currentLine);
      });
    }

    final Widget lyricsContent;
    if (document.lines.isEmpty && document.plainLines.isEmpty) {
      lyricsContent = const _EmptyLyrics();
    } else if (document.hasTimestamps) {
      lyricsContent = ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(48, 24, 48, 80),
        itemCount: document.lines.length,
        itemBuilder: (context, index) {
          final line = document.lines[index];
          final active = index == currentLine;
          return _LyricLineTile(
            line: line,
            active: active,
            position: lyricPosition,
          );
        },
      );
    } else {
      lyricsContent = ListView.builder(
        padding: const EdgeInsets.fromLTRB(48, 24, 48, 80),
        itemCount: document.plainLines.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            document.plainLines[index],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 20,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        _Header(trackTitle: track.title, artist: track.artist),
        Expanded(child: lyricsContent),
      ],
    );
  }

  int _lineAt(LyricsDocument document, Duration position) {
    final adjusted = position - document.offset;
    var index = -1;
    for (var i = 0; i < document.lines.length; i++) {
      if (document.lines[i].start <= adjusted) index = i;
    }
    return index;
  }

  void _scrollToLine(int index) {
    if (index < 0 || !_scrollController.hasClients) return;
    final target = (index * 66.0 - 160).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.trackTitle, required this.artist});

  final String trackTitle;
  final String artist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 12),
      child: Row(
        children: [
          Text('歌词', style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          Text(
            '$trackTitle  ·  $artist',
            style: const TextStyle(color: Colors.white60),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LyricLineTile extends StatelessWidget {
  const _LyricLineTile({
    required this.line,
    required this.active,
    required this.position,
  });

  final LyricLine line;
  final bool active;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Colors.white38;
    final style = TextStyle(
      color: color,
      fontSize: active ? 25 : 19,
      height: 1.45,
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 220),
        style: style,
        child: Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              line.isWordSynchronized
                  ? _WordSynchronizedText(line: line, position: position)
                  : Text(line.text, textAlign: TextAlign.center),
              if (line.translation != null) ...[
                const SizedBox(height: 4),
                Text(
                  line.translation!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              for (final variant in line.variants) ...[
                const SizedBox(height: 4),
                Text(
                  variant.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WordSynchronizedText extends StatelessWidget {
  const _WordSynchronizedText({required this.line, required this.position});

  final LyricLine line;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          for (final word in line.words)
            TextSpan(
              text: word.text,
              style: TextStyle(
                color: word.start <= position
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white38,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyLyrics extends StatelessWidget {
  const _EmptyLyrics();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('当前歌曲没有可用歌词', style: TextStyle(color: Colors.white54)),
    );
  }
}
