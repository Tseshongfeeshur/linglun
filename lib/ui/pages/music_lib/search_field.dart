import 'package:material_ui/material_ui.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:linglun/ui/utils/window_info.dart';

class SearchField extends StatefulWidget {
  final TextEditingController controller;
  const SearchField({super.key, required this.controller});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  bool _isExtended = false;

  @override
  Widget build(BuildContext context) {
    return Animate(target: _isExtended ? 1 : 0).custom(
      duration: 200.ms,
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) => Container(
        width:
            48 +
            (context.isLandscape || context.isWideScreen
                    ? 240
                    : (context.screenSize.width - 100) - 48) *
                value,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer
              .withAlpha((255 * value).toInt()),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _isExtended = !_isExtended),
                icon: Icon(Icons.search),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  decoration: InputDecoration(
                    hint: Text(
                      '搜索',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface
                            .withAlpha((160 * value).toInt()),
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              value > 0.5
                  ? IconButton(
                      onPressed: () => widget.controller.text == ''
                          ? setState(() => _isExtended = false)
                          : widget.controller.clear(),
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).colorScheme.onSurface
                            .withAlpha(
                              (255 * (value - 0.5) / (1 - 0.5)).toInt(),
                            ),
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
