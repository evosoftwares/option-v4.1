import '../../../domain/entities/driver_status.dart' as domain;

/// Modelo para status de intenção online do motorista
/// Separa a intenção do motorista (toggle) do status efetivo (calculado pela view)
class DriverStatus {

  /// Converte de JSON do Supabase
  factory DriverStatus.fromJson(Map<String, dynamic> json) {
    return DriverStatus(
      driverId: json['driver_id'] as String,
      onlineIntent: json['online_intent'] as bool,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  const DriverStatus({
    required this.driverId,
    required this.onlineIntent,
    required this.updatedAt,
  });

  /// ID do motorista (chave primária)
  final String driverId;

  /// Intenção do motorista de ficar online (controlado pelo toggle)
  final bool onlineIntent;

  /// Data de última atualização
  final DateTime updatedAt;

  /// Converte para JSON do Supabase
  Map<String, dynamic> toJson() => {
      'driver_id': driverId,
      'online_intent': onlineIntent,
      'updated_at': updatedAt.toIso8601String(),
    };

  /// Cria uma cópia com campos alterados
  DriverStatus copyWith({
    String? driverId,
    bool? onlineIntent,
    DateTime? updatedAt,
  }) => DriverStatus(
      driverId: driverId ?? this.driverId,
      onlineIntent: onlineIntent ?? this.onlineIntent,
      updatedAt: updatedAt ?? this.updatedAt,
    );

  @override
  String toString() => 'DriverStatus(driverId: $driverId, onlineIntent: $onlineIntent, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverStatus &&
        other.driverId == driverId &&
        other.onlineIntent == onlineIntent &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(driverId, onlineIntent, updatedAt);

  /// Converte para entidade de domínio
  domain.DriverStatus toEntity() => domain.DriverStatus(
    driverId: driverId,
    onlineIntent: onlineIntent,
    updatedAt: updatedAt,
  );
}