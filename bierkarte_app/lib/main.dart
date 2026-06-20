import 'package:flutter/material.dart';

import 'screens/map_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DieBlaueApp());
}

class DieBlaueApp extends StatelessWidget {
  const DieBlaueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DieBlaueAPP',
      theme: buildAppTheme(),
      home: const MapScreen(),
    );
  }
}
