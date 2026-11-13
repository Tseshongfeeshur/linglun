import 'package:material_ui/material_ui.dart';

class AlbumLib extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('专辑')),
      body: const Center(child: Text('AlbumLib')),
    );
  }
}
