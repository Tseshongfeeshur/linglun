import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglun/src/features/library/application/library_scanner.dart';

void main() {
  test('Opus 时长使用 48 kHz 粒度时钟而非输入采样率', () async {
    final directory = await Directory.systemTemp.createTemp('linglun-opus-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/duration.opus');
    await file.writeAsBytes(_opusFixture());

    final tracks = await LibraryScanner().scan([directory.path]);

    expect(tracks, hasLength(1));
    expect(tracks.single.duration.inMicroseconds, closeTo(261929188, 1));
    expect(tracks.single.metadata['时长'], '0:04:21.929188');
  });
}

Uint8List _opusFixture() {
  const serial = 1398944743;
  const finalGranule = 12572601;
  final opusHead = Uint8List(19)
    ..setRange(0, 8, 'OpusHead'.codeUnits)
    ..[8] = 1
    ..[9] = 2
    ..[10] = 0x38
    ..[11] = 0x01
    ..[12] = 0x44
    ..[13] = 0xAC
    ..[14] = 0x00
    ..[15] = 0x00;
  final opusTags = <int>[
    ...'OpusTags'.codeUnits,
    ..._littleEndian(0, 4),
    ..._littleEndian(0, 4),
  ];

  return Uint8List.fromList([
    ..._oggPage(
      payload: opusHead,
      serial: serial,
      headerType: 0x02,
      granule: 0,
    ),
    ..._oggPage(
      payload: Uint8List.fromList(opusTags),
      serial: serial,
      headerType: 0,
      granule: 0,
    ),
    ..._oggPage(
      payload: [0],
      serial: serial,
      headerType: 0x04,
      granule: finalGranule,
    ),
  ]);
}

List<int> _oggPage({
  required List<int> payload,
  required int serial,
  required int headerType,
  required int granule,
}) {
  final header = Uint8List(27)
    ..setRange(0, 4, 'OggS'.codeUnits)
    ..[4] = 0
    ..[5] = headerType
    ..setRange(6, 14, _littleEndian(granule, 8))
    ..setRange(14, 18, _littleEndian(serial, 4))
    ..[26] = 1;
  return [...header, payload.length, ...payload];
}

List<int> _littleEndian(int value, int length) => [
  for (var index = 0; index < length; index++) (value >> (index * 8)) & 0xFF,
];
