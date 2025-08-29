import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart';
import '../models/driver_wallet.dart';
import '../models/wallet_transaction.dart';

class DriverWalletService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Busca a carteira do motorista pelo ID do usuário
  static Future<DriverWallet?> getDriverWallet(String userId) async {
    try {
      // Primeiro busca o driver_id pelo user_id
      final driverResponse = await _supabase
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (driverResponse == null) {
        throw DatabaseException('Motorista não encontrado para o usuário: $userId');
      }

      final driverId = driverResponse['id'] as String;

      // Busca a carteira do motorista
      final walletResponse = await _supabase
          .from('driver_wallets')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();

      if (walletResponse == null) {
        return null;
      }

      return DriverWallet.fromMap(walletResponse);
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erro ao buscar carteira do motorista: $e');
    }
  }

  /// Busca o ID do motorista pelo ID do usuário
  static Future<String?> getDriverId(String userId) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      throw DatabaseException('Erro ao buscar ID do motorista: $e');
    }
  }

  /// Busca as transações da carteira do motorista
  static Future<List<WalletTransaction>> getDriverWalletTransactions(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final driverId = await getDriverId(userId);
      if (driverId == null) {
        throw DatabaseException('Motorista não encontrado para o usuário: $userId');
      }

      // Busca a carteira do motorista
      final walletResponse = await _supabase
          .from('driver_wallets')
          .select('id')
          .eq('driver_id', driverId)
          .maybeSingle();

      if (walletResponse == null) {
        return [];
      }

      final walletId = walletResponse['id'] as String;

      // Busca as transações da carteira
      final transactionsResponse = await _supabase
          .from('wallet_transactions')
          .select()
          .eq('wallet_id', walletId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return transactionsResponse
          .map(WalletTransaction.fromMap)
          .toList();
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erro ao buscar transações da carteira: $e');
    }
  }

  /// Cria uma carteira para o motorista (se não existir)
  static Future<DriverWallet> createDriverWallet(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_wallets')
          .insert({
            'driver_id': driverId,
            'available_balance': 0.0,
            'pending_balance': 0.0,
            'total_earned': 0.0,
            'total_withdrawn': 0.0,
          })
          .select()
          .single();

      return DriverWallet.fromMap(response);
    } catch (e) {
      throw DatabaseException('Erro ao criar carteira do motorista: $e');
    }
  }

  /// Busca ou cria a carteira do motorista
  static Future<DriverWallet> getOrCreateDriverWallet(String userId) async {
    try {
      final driverId = await getDriverId(userId);
      if (driverId == null) {
        throw DatabaseException('Motorista não encontrado para o usuário: $userId');
      }

      // Tenta buscar a carteira existente
      final existingWallet = await getDriverWallet(userId);
      if (existingWallet != null) {
        return existingWallet;
      }

      // Se não existe, cria uma nova
      return await createDriverWallet(driverId);
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erro ao buscar ou criar carteira do motorista: $e');
    }
  }

  /// Adiciona ganhos ao motorista usando a função SQL
  static Future<void> addDriverEarnings({
    required String driverId,
    required double amount,
    required String description,
    String? referenceType,
    String? referenceId,
  }) async {
    try {
      await _supabase.rpc('add_driver_earnings', params: {
        'p_driver_id': driverId,
        'p_amount': amount,
        'p_description': description,
        'p_reference_type': referenceType,
        'p_reference_id': referenceId,
      });
    } catch (e) {
      throw DatabaseException('Erro ao adicionar ganhos do motorista: $e');
    }
  }

  /// Processa o pagamento de uma viagem para o motorista
  static Future<void> processTripPayment({
    required String driverId,
    required String tripId,
    required double tripAmount,
    double platformCommissionPercent = 0.10, // 10% padrão
  }) async {
    try {
      // Calcula o valor líquido para o motorista (após comissão)
      final platformCommission = tripAmount * platformCommissionPercent;
      final driverEarnings = tripAmount - platformCommission;

      // Adiciona os ganhos do motorista
      await addDriverEarnings(
        driverId: driverId,
        amount: driverEarnings,
        description: 'Ganho de viagem #$tripId',
        referenceType: 'trip',
        referenceId: tripId,
      );

      // Registra a comissão da plataforma (opcional, para auditoria)
      await _recordPlatformCommission(
        tripId: tripId,
        amount: platformCommission,
        percentage: platformCommissionPercent,
      );
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erro ao processar pagamento da viagem: $e');
    }
  }

  /// Registra a comissão da plataforma (método privado)
  static Future<void> _recordPlatformCommission({
    required String tripId,
    required double amount,
    required double percentage,
  }) async {
    try {
      await _supabase.from('platform_commissions').insert({
        'trip_id': tripId,
        'amount': amount,
        'percentage': percentage,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Não falha o processo principal se não conseguir registrar a comissão
      print('Aviso: Não foi possível registrar comissão da plataforma: $e');
    }
  }

  /// Calcula estatísticas da carteira do motorista
  static Future<Map<String, dynamic>> getDriverWalletStats(String userId) async {
    try {
      final wallet = await getDriverWallet(userId);
      if (wallet == null) {
        return {
          'available_balance': 0.0,
          'pending_balance': 0.0,
          'total_earned': 0.0,
          'total_withdrawn': 0.0,
          'total_trips': 0,
          'average_trip_earning': 0.0,
        };
      }

      // Busca estatísticas adicionais
      final transactions = await getDriverWalletTransactions(userId, limit: 1000);
      final tripEarnings = transactions
          .where((t) => t.type == WalletTransactionType.tripEarning)
          .toList();

      final totalTrips = tripEarnings.length;
      final averageTripEarning = totalTrips > 0 
          ? tripEarnings.map((t) => t.amount).reduce((a, b) => a + b) / totalTrips
          : 0.0;

      return {
        'available_balance': wallet.availableBalance,
        'pending_balance': wallet.pendingBalance,
        'total_earned': wallet.totalEarned,
        'total_withdrawn': wallet.totalWithdrawn,
        'total_trips': totalTrips,
        'average_trip_earning': averageTripEarning,
      };
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Erro ao calcular estatísticas da carteira: $e');
    }
  }
}