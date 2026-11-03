import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/frame/page_model.dart';

class Settings extends StatelessWidget implements PageModel {
  const Settings({super.key});

  @override
  String get title => '设置';

  @override
  IconData get icon => Icons.settings_outlined;

  @override
  IconData get selectedIcon => Icons.settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Settings')),
    );
  }
}
