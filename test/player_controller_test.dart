import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglun/src/features/player/application/player_controller.dart';
import 'package:linglun/src/features/player/domain/track.dart';

void main() {
  test('随机和循环控制更新播放状态', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(playerControllerProvider.notifier);

    controller.toggleShuffle();
    expect(container.read(playerControllerProvider).shuffleEnabled, isTrue);

    controller.cycleRepeatMode();
    expect(container.read(playerControllerProvider).repeatMode, RepeatMode.all);
    controller.cycleRepeatMode();
    expect(container.read(playerControllerProvider).repeatMode, RepeatMode.one);
    controller.cycleRepeatMode();
    expect(container.read(playerControllerProvider).repeatMode, RepeatMode.off);
  });

  test('关闭循环时队列末尾不回绕，列表循环时回到开头', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(playerControllerProvider.notifier);

    for (var index = 1; index < demoTracks.length; index++) {
      controller.skipNext();
    }
    expect(container.read(playerControllerProvider).currentIndex, 3);

    controller.skipNext();
    expect(container.read(playerControllerProvider).currentIndex, 3);

    controller.cycleRepeatMode();
    controller.skipNext();
    expect(container.read(playerControllerProvider).currentIndex, 0);
  });

  test('单曲循环队列的下一曲操作重新打开当前曲目', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(playerControllerProvider.notifier);
    controller.replaceQueue([demoTracks.first]);
    controller.cycleRepeatMode();

    controller.skipNext();

    expect(
      container.read(playerControllerProvider).currentTrack.id,
      demoTracks.first.id,
    );
    expect(container.read(playerControllerProvider).position, Duration.zero);
  });

  test('从浏览列表播放时建立完整队列并将点击曲目置于首位', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(playerControllerProvider.notifier);

    await controller.playFromList([
      demoTracks[2],
      demoTracks[0],
      demoTracks[3],
    ], demoTracks[0]);

    final state = container.read(playerControllerProvider);
    expect(state.queue.map((track) => track.id).toList(), [
      demoTracks[2].id,
      demoTracks[0].id,
      demoTracks[3].id,
    ]);
    expect(state.currentIndex, 1);
    expect(state.currentTrack.id, demoTracks[0].id);
  });

  test('开启随机播放时只重排一次并保持当前曲目为首项', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(playerControllerProvider.notifier);
    final currentId = container.read(playerControllerProvider).currentTrack.id;

    controller.toggleShuffle();

    final state = container.read(playerControllerProvider);
    expect(state.shuffleEnabled, isTrue);
    expect(state.currentIndex, 0);
    expect(state.currentTrack.id, currentId);
    expect(
      state.queue.map((track) => track.id).toSet(),
      demoTracks.map((track) => track.id).toSet(),
    );

    final shuffledIds = state.queue.map((track) => track.id).toList();
    controller.skipNext();
    expect(container.read(playerControllerProvider).currentIndex, 1);
    expect(
      container.read(playerControllerProvider).currentTrack.id,
      shuffledIds[1],
    );

    controller.skipNext();
    expect(container.read(playerControllerProvider).currentIndex, 2);
    expect(
      container.read(playerControllerProvider).currentTrack.id,
      shuffledIds[2],
    );

    controller.previous();
    expect(container.read(playerControllerProvider).currentIndex, 1);
    expect(
      container.read(playerControllerProvider).currentTrack.id,
      shuffledIds[1],
    );
  });

  test('随机队列按洗牌后的顺序播放且下一曲不会越过队尾', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(playerControllerProvider.notifier);

    controller.toggleShuffle();
    final shuffledIds = container
        .read(playerControllerProvider)
        .queue
        .map((track) => track.id)
        .toList();

    for (var index = 1; index < shuffledIds.length; index++) {
      controller.skipNext();
      final state = container.read(playerControllerProvider);
      expect(state.currentIndex, index);
      expect(state.currentTrack.id, shuffledIds[index]);
    }

    final lastIndex = container.read(playerControllerProvider).currentIndex;
    controller.skipNext();
    final endedState = container.read(playerControllerProvider);
    expect(endedState.currentIndex, lastIndex);
    expect(endedState.currentTrack.id, shuffledIds[lastIndex]);
  });
}
