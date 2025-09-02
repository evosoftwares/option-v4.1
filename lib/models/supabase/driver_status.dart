/// Modelo para status de intenção online do motorista
/// Separa a intenção do motorista (toggle) do status efetivo (calculado pela view)
class DriverStatus {
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

  /// Converte de JSON do Supabase
  factory DriverStatus.fromJson(Map<String, dynamic> json) {
    return DriverStatus(
      driverId: json['driver_id'] as String,
      onlineIntent: json['online_intent'] as bool,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converte para JSON do Supabase
  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'online_intent': onlineIntent,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria uma cópia com campos alterados
  DriverStatus copyWith({
    String? driverId,
    bool? onlineIntent,
    DateTime? updatedAt,
  }) {
    return DriverStatus(
      driverId: driverId ?? this.driverId,
      onlineIntent: onlineIntent ?? this.onlineIntent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DriverStatus(driverId: $driverId, onlineIntent: $onlineIntent, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverStatus &&
        other.driverId == driverId &&
        other.onlineIntent == onlineIntent &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(driverId, onlineIntent, updatedAt);
  }
}