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
}
