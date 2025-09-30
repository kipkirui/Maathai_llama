import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'state/model_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaathaiApp());
}

class MaathaiApp extends StatelessWidget {
  const MaathaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ModelController()..initializeBackend(),
      child: MaterialApp(
        title: 'Maathai LLaMA',
        theme: AppTheme.darkTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}