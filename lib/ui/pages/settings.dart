import 'package:material_ui/material_ui.dart';

class Settings extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: const Center(child: Text('Settings')),
    );
  }
}
