import 'dart:io';

import 'package:supabase/supabase.dart';

import 'test_constants.dart';

class SupabaseTestHelper {
  // Use separate clients: public (anon) for app/service behavior, admin (service role) for setup/teardown
  static SupabaseClient? _publicClient;
  static SupabaseClient? _adminClient;

  static Future<void> initialize() async {
    if (_publicClient != null || _adminClient != null) return;
    final creds = await _resolveSupabaseCreds();
    final url = creds.url;
    final anonKey = creds.anonKey;
    final serviceKey = creds.serviceKey;

    if (url.isEmpty || (anonKey.isEmpty && serviceKey.isEmpty)) {
      throw StateError(
        'Supabase credentials not provided. Define SUPABASE_URL and SUPABASE_ANON_KEY (or SUPABASE_SERVICE_ROLE_KEY) via --dart-define or .env.',
      );
    }

    if (anonKey.isNotEmpty) {
      _publicClient = SupabaseClient(url, anonKey);
    } else if (serviceKey.isNotEmpty) {
      // Fallback: if anon key is not provided, use service key also as public
      _publicClient = SupabaseClient(url, serviceKey);
    }

    if (serviceKey.isNotEmpty) {
      _adminClient = SupabaseClient(url, serviceKey);
    }
  }

  // Client used by services under test (prefer anon)
  static SupabaseClient get client => _publicClient ?? _adminClient!;

  static Future<void> cleanDatabase() async {
    // Ordem importa por causa de FKs
    await _safeDeleteAll('driver_offers', 'id');
    await _safeDeleteAll('trips', 'id');
    await _safeDeleteAll('trip_requests', 'id');
    await _safeDeleteAll('drivers', 'id');
    await _safeDeleteAll('passengers', 'id');
    await _safeDeleteAll('app_users', 'id');
  }

  static Future<void> _safeDeleteAll(String table, String idColumn) async {
    try {
      final db = _adminClient ?? client;
      await db
          .from(table)
          .delete()
          .neq(idColumn, '00000000-0000-0000-0000-000000000000');
    } catch (_) {
      // Ignorar erros de tabela ou coluna inexistente em ambientes locais divergentes
    }
  }

  static Future<({String userId, String passengerId})> seedPassenger({
    String email = 'passenger.test@example.com',
    String fullName = 'Passenger Test',
  }) async {
    final db = _adminClient ?? client;
    final user = await db
        .from('app_users')
        .insert({
          'email': email,
          'full_name': fullName,
          'user_type': 'passenger',
          'status': 'active',
        })
        .select()
        .single();

    final passenger = await db
        .from('passengers')
        .insert({
          'user_id': user['id'],
          'consecutive_cancellations': 0,
          'total_trips': 0,
          'average_rating': 5.0,
        })
        .select()
        .single();

    return (userId: user['id'] as String, passengerId: passenger['id'] as String);
  }

  static Future<({String userId, String driverId})> seedDriver() async {
    final db = _adminClient ?? client;
    final user = await db
        .from('app_users')
        .insert({
          'email': 'driver.test@example.com',
          'full_name': 'Driver Test',
          'user_type': 'driver',
          'status': 'active',
        })
        .select()
        .single();

    // Alguns campos são obrigatórios segundo o serviço de driver
    final driver = await db
        .from('drivers')
        .insert({
          'user_id': user['id'],
          'cnh_number': 'ABC123456',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Preto',
          'vehicle_plate': 'TEST1234',
          'vehicle_category': 'standard',
          'approval_status': 'approved',
          'is_online': true,
          'accepts_pet': true,
          'accepts_grocery': true,
          'accepts_condo': true,
        })
        .select()
        .single();

    return (userId: user['id'] as String, driverId: driver['id'] as String);
  }

  static Future<({String url, String anonKey, String serviceKey})> _resolveSupabaseCreds() async {
    final url = _envOrDotEnv('SUPABASE_URL') ?? TestConstants.supabaseUrl;
    final anon = _envOrDotEnv('SUPABASE_ANON_KEY') ?? TestConstants.supabaseAnonKey;
    final service = _envOrDotEnv('SUPABASE_SERVICE_ROLE_KEY') ?? TestConstants.supabaseServiceRoleKey;
    return (url: url, anonKey: anon, serviceKey: service);
  }

  static String? _envOrDotEnv(String key) {
    final fromEnv = Platform.environment[key];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) return fromEnv;

    try {
      final file = File('.env');
      if (!file.existsSync()) return null;
      for (final raw in file.readAsLinesSync()) {
        final line = raw.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final idx = line.indexOf('=');
        if (idx < 0) continue;
        final k = line.substring(0, idx).trim();
        if (k != key) continue;
        var v = line.substring(idx + 1).trim();
        if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
          v = v.substring(1, v.length - 1);
        }
        return v;
      }
    } catch (_) {}
    return null;
  }
}