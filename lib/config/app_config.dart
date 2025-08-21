class AppConfig {
  // Supabase configuration - usando valores diretos do .env
  // Para produção, use --dart-define ou variáveis de ambiente
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qlbwacmavngtonauxnte.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E',
  );

  // Asaas configuration
  static const String asaasBaseUrl = String.fromEnvironment(
    'ASAAS_BASE_URL',
    defaultValue: '',
  );

  static const String asaasApiKey = String.fromEnvironment(
    'ASAAS_API_KEY',
    defaultValue: '',
  );

  // Google Maps API
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB1WJiIpqAhWt0P_ZqlkbleZ5hUmqTQHBc',
  );
}