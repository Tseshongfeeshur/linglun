import 'package:material_ui/material_ui.dart';

class ArtistLib extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('艺术家')),
      body: const Center(child: Text('ArtistLib')),
    );
  }
}
