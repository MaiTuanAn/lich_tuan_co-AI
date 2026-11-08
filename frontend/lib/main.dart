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
    final themeMode = context.select<CalendarProvider, ThemeMode>((p) => p.themeMode);

    return MaterialApp(
      title: 'SchedulAI - Quản lý Lịch tuần AI',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      home: const MainLayoutScreen(),
    );
  }
}