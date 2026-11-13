import 'package:linglun/data/models/track_info_model.dart';
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
      title: const Text('选择分组'),
      content: SizedBox(
        width: 300,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 48,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: allLetters.length,
          itemBuilder: (context, index) => _LetterCell(
            letter: allLetters[index],
            isCurrent: allLetters[index] == currentLetter,
            isValid: groupedTrackList.containsKey(allLetters[index]),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    )),
  );
}

class _LetterCell extends StatelessWidget {
  final String letter;
  final bool isCurrent;
  final bool isValid;

  const new({
    required this.letter,
    required this.isCurrent,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
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
    );
  }
}
