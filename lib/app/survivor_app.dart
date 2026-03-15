import 'package:flutter/material.dart';

import 'survivor_shell.dart';

class SurvivorApp extends StatelessWidget {
  const SurvivorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Survivor Prototype',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8BC34A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF111315),
      ),
      home: const SurvivorShell(),
    );
  }
}
