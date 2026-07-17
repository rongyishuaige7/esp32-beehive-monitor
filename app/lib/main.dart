import 'package:flutter/material.dart';

import 'ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BeehiveMonitorApp());
}

class BeehiveMonitorApp extends StatelessWidget {
  const BeehiveMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFF5A623);
    return MaterialApp(
      title: '蜂箱传感器采样原型',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          surface: const Color(0xFFFCF9F2),
        ),
        scaffoldBackgroundColor: const Color(0xFFFCF9F2),
        useMaterial3: true,
        fontFamily: 'system-ui',
      ),
      home: const HomePage(),
    );
  }
}
