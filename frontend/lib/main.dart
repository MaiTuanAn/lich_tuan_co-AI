import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/calendar_provider.dart';
import 'screens/main_layout_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CalendarProvider(),
      child: const SchedulAIApp(),
    ),
  );
}

class SchedulAIApp extends StatelessWidget {
  const SchedulAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SchedulAI - Quản lý Lịch tuần',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      home: const MainLayoutScreen(),
    );
  }
}
