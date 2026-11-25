class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://klgzodpbaxwvbyqcgyte.supabase.co',
  );

  // Dán anon/publishable key vào defaultValue (hoặc truyền qua --dart-define)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_NXZMGFwC0dTBNl_f_jBV5g_S7pEK5JT',
  );
}