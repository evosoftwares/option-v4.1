class AppConfig {
  // Supabase keys are already initialized in main.dart for this project.
  // Keeping here for consistency if needed elsewhere.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // Asaas configuration
  static const String asaasBaseUrl = String.fromEnvironment(
    'ASAAS_BASE_URL',
    defaultValue: '',
  );

  static const String asaasApiKey = String.fromEnvironment(
    'ASAAS_API_KEY',
    defaultValue: '',
  );
}