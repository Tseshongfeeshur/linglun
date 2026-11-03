import 'package:material_ui/material_ui.dart';

import 'package:linglun/ui/frame/page_model.dart';

class ArtistLib extends StatelessWidget implements PageModel {
  const ArtistLib({super.key});

  @override
  String get title => '艺术家';

  @override
  IconData get icon => Icons.person_outline;

  @override
  IconData get selectedIcon => Icons.person;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('ArtistLib')),
    );
  }
}
