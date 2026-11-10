import 'package:linglun/data/models/track_info_model.dart';
import 'package:linglun/ui/utils/window_info.dart';
import 'package:material_ui/material_ui.dart';

Future<String?> showLetterSelectingDialog(
  BuildContext context,
  Map<String, List<TrackInfo>> groupedTrackList,
  String currentLetter,
) async {
  List<String> allLetters = [
    '#',
    ...List.generate(
      26,
      (index) => String.fromCharCode('A'.codeUnitAt(0) + index),
    ),
  ];

  return showDialog<String>(
    context: context,
    builder: ((context) => AlertDialog(
      title: Text('选择分组'),
      content: SingleChildScrollView(
        clipBehavior: Clip.hardEdge,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width:
                  (() {
                    if (context.windowSize.width >= 600) {
                      return 6;
                    } else if (context.windowSize.width >= 368) {
                      return 5;
                    } else if (context.windowSize.width >= 320) {
                      return 4;
                    } else {
                      return 3;
                    }
                  })() *
                  (48),
              child: Wrap(
                children: [
                  for (final letter in allLetters)
                    _LetterCell(
                      letter: letter,
                      isCurrent: letter == currentLetter,
                      isValid: groupedTrackList.containsKey(letter),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),
      ],
    )),
  );
}

class _LetterCell extends StatelessWidget {
  final String letter;
  final bool isCurrent;
  final bool isValid;

  const _LetterCell({
    required this.letter,
    required this.isCurrent,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 48,
      height: 48,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: isCurrent ? scheme.primary : null,
            shape: BoxShape.circle,
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: isValid ? () => Navigator.of(context).pop(letter) : null,
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  color: isCurrent
                      ? scheme.onPrimary
                      : (isValid ? null : scheme.onSurface.withAlpha(100)),
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
