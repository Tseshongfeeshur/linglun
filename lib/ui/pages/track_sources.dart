import 'package:material_ui/material_ui.dart';

class TrackSources extends StatelessWidget {
  const TrackSources({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('歌曲来源')),
      body: Center(child: Text('MusicSources')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        isExtended: true,
        icon: Icon(Icons.refresh),
        label: Text('刷新曲库'),
      ),
    );
  }
}
