import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/calendar_provider.dart';
import 'screens/main_layout_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );
  await _testSupabase(); // tạm thời, test xong thì xóa

  runApp(
    ChangeNotifierProvider(
      create: (_) => CalendarProvider(),
      child: const SchedulAIApp(),
    ),
  );
}

Future<void> _testSupabase() async {
  final client = Supabase.instance.client;
  try {
    if (client.auth.currentSession == null) {
      await client.auth.signInAnonymously();
    }
    final user = client.auth.currentUser;
    debugPrint('✅ Auth OK - user: ${user?.id} (ẩn danh: ${user?.isAnonymous})');

    final cats = await client.from('categories').select('name, color');
    debugPrint('✅ Database OK - ${cats.length} danh mục: $cats');
  } catch (e) {
    debugPrint('❌ Supabase lỗi: $e');
  }
}

class SchedulAIApp extends StatelessWidget {
  const SchedulAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<CalendarProvider, ThemeMode>((p) => p.themeMode);

    return MaterialApp(
      title: 'Chân Đèn 16 - Quản lý Lịch tuần',
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