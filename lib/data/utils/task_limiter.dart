import 'dart:async';

/// 节流器，减少由并发产生的卡顿
class TaskLimiter {
  final int maxRunning;
  new({required this.maxRunning}) : assert(maxRunning > 0);

  // 并行任务数
  var _running = 0;
  // 等待栈，后进先出，防止一直滑动时后等前
  final _taskStack = <Completer>[];

  Future<T> run<T>(Future<T> Function() task) async {
    // 如果并行任务未满
    if (_running < maxRunning) {
      _running++;
      // 立即执行 try-finally
    } else {
      // 无法继续并行，因此创建等待器
      final completer = Completer<void>();
      _taskStack.add(completer);
      // 等待等待器被结束
      await completer.future;
    }

    try {
      return await task();
    } finally {
      // 如果还有任务在排队
      if (_taskStack.isNotEmpty) {
        // 立刻结束等待器，从而转交名额，因此 _running 不变
        _taskStack.removeLast().complete();
      } else {
        _running--;
      }
    }
  }
}
