String formatDuration(int ms) {
  var tmps = (ms ~/ 1000);
  var h = tmps ~/ 60 ~/ 60;
  var m = tmps ~/ 60 % 60;
  var s = tmps % 60;
  return '${h != 0 ? '${h.toString().padLeft(2, '0')}:' : ''}${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
