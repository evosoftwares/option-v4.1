/// Modelo para o status efetivo do motorista (view driver_effective_status)
/// Combina a intenção online com a elegibilidade do motorista
class DriverEffectiveStatus {

  /// Converte de JSON do Supabase (view)
  factory DriverEffectiveStatus.fromJson(Map<String, dynamic> json) {
    return DriverEffectiveStatus(
      driverId: json['driver_id'] as String,
      onlineIntent: json['online_intent'] as bool,
      intentUpdatedAt: DateTime.parse(json['intent_updated_at'] as String),
      effectiveOnline: json['effective_online'] as bool,
    );
  }
  const DriverEffectiveStatus({
    required this.driverId,
    required this.onlineIntent,
    required this.intentUpdatedAt,
    required this.effectiveOnline,
  });

  /// ID do motorista
  final String driverId;

  /// Intenção do motorista de ficar online (do driver_status)
  final bool onlineIntent;

  /// Data de última atualização da intenção
  final DateTime intentUpdatedAt;

  /// Status efetivo online (baseado na intenção e elegibilidade)
  final bool effectiveOnline;

  /// Converte para JSON (somente leitura, pois é uma view)
  Map<String, dynamic> toJson() => {
      'driver_id': driverId,
      'online_intent': onlineIntent,
      'intent_updated_at': intentUpdatedAt.toIso8601String(),
      'effective_online': effectiveOnline,
    };

  /// Cria uma cópia com campos alterados
  DriverEffectiveStatus copyWith({
    String? driverId,
    bool? onlineIntent,
    DateTime? intentUpdatedAt,
    bool? effectiveOnline,
  }) => DriverEffectiveStatus(
      driverId: driverId ?? this.driverId,
      onlineIntent: onlineIntent ?? this.onlineIntent,
      intentUpdatedAt: intentUpdatedAt ?? this.intentUpdatedAt,
      effectiveOnline: effectiveOnline ?? this.effectiveOnline,
    );

  /// Retorna uma descrição do status para exibição
  String get statusDescription {
    if (!onlineIntent) {
      return 'Offline (motorista desligou)';
    }
    if (!effectiveOnline) {
      return 'Offline (não elegível)';
    }
    return 'Online';
  }

  /// Retorna se o motorista pode receber corridas
  bool get canReceiveTrips => effectiveOnline;

  @override
  String toString() => 'DriverEffectiveStatus(driverId: $driverId, onlineIntent: $onlineIntent, effectiveOnline: $effectiveOnline)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverEffectiveStatus &&
        other.driverId == driverId &&
        other.onlineIntent == onlineIntent &&
        other.intentUpdatedAt == intentUpdatedAt &&
        other.effectiveOnline == effectiveOnline;
  }

  @override
  int get hashCode => Object.hash(
      driverId,
      onlineIntent,
      intentUpdatedAt,
      effectiveOnline,
    );
}