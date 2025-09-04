class AppConfig {
  // Supabase configuration - usando valores diretos do .env
  // Para produção, use --dart-define ou variáveis de ambiente
  static const String supabaseUrl = 'https://qlbwacmavngtonauxnte.supabase.co';
  
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E';

  // Asaas configuration
  static const String asaasBaseUrl = String.fromEnvironment(
    'ASAAS_BASE_URL',
    defaultValue: 'https://api.asaas.com/v3', // API de produção
  );

  static const String asaasApiKey = String.fromEnvironment(
    'ASAAS_API_KEY',
    defaultValue: 'aact_prod_000MzkwODA2MWY2OGM3MWRlMDU2NWM3MzJlNzZmNGZhZGY6Ojg1OTI0YjdiLTk1ODEtNDc0ZS04N2YzLTY0ZDk2MGM4ZDI3Yjo6JGFhY2hfNDhlN2M3OTAtOGY4NC00ZDE2LTk0NWQtNjAwMTU4ODhkMTM3', // Token de produção
  );

  // Google Maps API
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB1WJiIpqAhWt0P_ZqlkbleZ5hUmqTQHBc',
  );
}