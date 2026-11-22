import 'package:linglun/data/utils/track_sort.dart';
import 'package:material_ui/material_ui.dart';

/// 弹出分组选择框（字母/假名/#……），返回所选分组键，取消返回 null。
// TODO: 函数体就一个 return showDialog，`async` 是多余的。
Future<String?> showLetterSelectingDialog(
  BuildContext context,
  List<TrackListItemType> groupedTrackList,
  String currentLetter,
) async {
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
            // TODO: 每个格子里 groupedTrackList.keys.toList() 被调用了两次（O(分组数²)），
            // 在 builder 外先 final keys = groupedTrackList.keys.toList() 一次即可。
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
      // TODO: InkWell 的水波纹画在最近的 Material 上，会被外层 Container 的
      // 背景色盖住（当前分组的格子看不到水波纹）。改用 Material/Ink 来画背景。
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
