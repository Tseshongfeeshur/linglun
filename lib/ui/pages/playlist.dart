import 'package:material_ui/material_ui.dart';

class Playlist extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('播放列表')),
      body: const Center(child: Text('Playlist')),
    );
  }
}
