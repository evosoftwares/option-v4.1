import '../entities/driver_status.dart';
import '../entities/driver_effective_status.dart';

/// Interface do repositório para gerenciamento de status de motoristas
/// Define os contratos para operações relacionadas ao status online/offline
abstract class DriverStatusRepository {
  /// Busca o status de intenção online do motorista
  Future<DriverStatus?> getDriverStatus(String driverId);

  /// Busca o status efetivo do motorista (da view calculada)
  Future<DriverEffectiveStatus?> getDriverEffectiveStatus(String driverId);

  /// Atualiza a intenção online do motorista
  Future<DriverStatus> updateOnlineIntent(String driverId, bool onlineIntent);

  /// Liga o motorista (define intenção como true)
  Future<DriverStatus> setDriverOnline(String driverId);

  /// Desliga o motorista (define intenção como false)
  Future<DriverStatus> setDriverOffline(String driverId);

  /// Verifica se o motorista pode ficar online agora
  /// (documentos aprovados e elegível)
  Future<bool> canDriverGoOnlineNow(String driverId);

  /// Verifica se todos os documentos obrigatórios estão aprovados
  Future<Map<String, dynamic>> checkRequiredDocumentsApproved(String driverId);

  /// Busca todos os motoristas efetivamente online
  Future<List<DriverEffectiveStatus>> getOnlineDrivers();

  /// Busca motoristas com intenção online mas fora do horário
  Future<List<DriverEffectiveStatus>> getDriversWithIntentButOffline();

  /// Remove o status do motorista (usado quando motorista é excluído)
  Future<void> deleteDriverStatus(String driverId);

  /// Inicializa o status do motorista (usado quando motorista é criado)
  Future<DriverStatus> initializeDriverStatus(
    String driverId, {
    bool initialOnlineIntent = false,
  });

  /// Busca estatísticas de status dos motoristas
  Future<Map<String, int>> getDriverStatusStats();

  /// Atualiza timestamp da última notificação do motorista
  Future<void> updateLastNotificationAt(String driverId);
}