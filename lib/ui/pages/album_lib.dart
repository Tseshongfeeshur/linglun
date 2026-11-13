import 'package:material_ui/material_ui.dart';

class AlbumLib extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('专辑')),
      body: Center(child: Text('AlbumLib')),
    );
  }
}
