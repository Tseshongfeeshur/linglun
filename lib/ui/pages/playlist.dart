import 'package:material_ui/material_ui.dart';

class Playlist extends StatelessWidget {
  const Playlist({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('播放列表')),
      body: Center(child: Text('Playlist')),
    );
  }
}
