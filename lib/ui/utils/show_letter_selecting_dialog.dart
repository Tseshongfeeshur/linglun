import 'package:linglun/data/utils/track_sort.dart';
import 'package:material_ui/material_ui.dart';

/// 弹出分组选择框（字母/假名/#……），返回所选分组键，取消返回 null。
Future<String?> showLetterSelectingDialog(
  BuildContext context,
  List<TrackListItemType> groupedTrackList,
  String currentLetter,
) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      final heads = groupedTrackList
          .whereType<TrackListGroupHead>()
          .map((i) => i.group)
          .toList();
      return AlertDialog(
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
            itemCount: heads.length,
            itemBuilder: (context, index) => _LetterCell(
              letter: heads[index],
              isCurrent: heads[index] == currentLetter,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      );
    },
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
        onTap: isCurrent ? null : () => Navigator.of(context).pop(letter),
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
