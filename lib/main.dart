import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/overlay_service.dart';
import 'services/speech_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/clipboard_service.dart';
import 'widgets/recording_indicator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HinglishDictateApp());
}

class HinglishDictateApp extends StatelessWidget {
  const HinglishDictateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hinglish Dictate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
