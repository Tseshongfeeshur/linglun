import 'package:material_ui/material_ui.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:linglun/ui/utils/window_info.dart';

class SearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  const SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  bool _extended = false;
  final _groupId = Object();

  void updateExtendedState() => setState(
    () => _extended =
        widget.focusNode.hasFocus || widget.controller.text.isNotEmpty,
  );

  @override
  void initState() {
    widget.controller.addListener(updateExtendedState);
    widget.focusNode.addListener(updateExtendedState);
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(updateExtendedState);
    widget.focusNode.removeListener(updateExtendedState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(target: _extended ? 1 : 0).custom(
      duration: 200.ms,
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) => TapRegion(
        groupId: _groupId,
        child: Container(
          width:
              40 +
              (context.isWideScreen
                      ? 240
                      : (context.windowSize.width - 100) - 40) *
                  value,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer
                .withAlpha((255 * value).toInt().clamp(0, 255)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              IconButton(
                onPressed: () => widget.focusNode.requestFocus(),
                icon: Icon(Icons.search),
              ),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 40),
                child: TextField(
                  groupId: _groupId,
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  onTapOutside: (_) => widget.focusNode.unfocus(),
                  decoration: InputDecoration(
                    hintText: '搜索',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface
                          .withAlpha((160 * value).toInt()),
                      fontSize: 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: Opacity(
                  opacity: ((value - 0.5) / 0.5).clamp(0, 1),
                  child: IgnorePointer(
                    ignoring: value < 0.5,
                    child: IconButton(
                      onPressed: () {
                        if (widget.controller.text.isEmpty) {
                          widget.focusNode.unfocus();
                        } else {
                          widget.controller.clear();
                          widget.focusNode.requestFocus();
                        }
                      },
                      icon: Icon(Icons.clear),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
