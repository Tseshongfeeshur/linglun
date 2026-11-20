import 'package:material_ui/material_ui.dart';
import 'package:linglun/data/models/track_info.dart';

Future<String?> showLetterSelectingDialog(
  BuildContext context,
  Map<String, List<TrackInfo>> groupedTrackList,
  String currentLetter,
) async {
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
          itemCount: groupedTrackList.length,
          itemBuilder: (context, index) => _LetterCell(
            letter: groupedTrackList.keys.toList()[index],
            isCurrent: groupedTrackList.keys.toList()[index] == currentLetter,
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

  const new({required this.letter, required this.isCurrent});

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
        onTap: () => Navigator.of(context).pop(letter),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              color: isCurrent ? scheme.onPrimary : null,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
