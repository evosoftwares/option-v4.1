/// Modelo para o status efetivo do motorista (view driver_effective_status)
/// Combina a intenção online com os horários de trabalho para calcular o status real
class DriverEffectiveStatus {

  /// Converte de JSON do Supabase (view)
  factory DriverEffectiveStatus.fromJson(Map<String, dynamic> json) {
    return DriverEffectiveStatus(
      driverId: json['driver_id'] as String,
      onlineIntent: json['online_intent'] as bool,
      intentUpdatedAt: DateTime.parse(json['intent_updated_at'] as String),
      isWithinWorkingHours: json['is_within_working_hours'] as bool,
      effectiveOnline: json['effective_online'] as bool,
    );
  }
  const DriverEffectiveStatus({
    required this.driverId,
    required this.onlineIntent,
    required this.intentUpdatedAt,
    required this.isWithinWorkingHours,
    required this.effectiveOnline,
  });

  /// ID do motorista
  final String driverId;

  /// Intenção do motorista de ficar online (do driver_status)
  final bool onlineIntent;

  /// Data de última atualização da intenção
  final DateTime intentUpdatedAt;

  /// Se o motorista está dentro dos horários de trabalho no momento atual
  final bool isWithinWorkingHours;

  /// Status efetivo online (onlineIntent AND isWithinWorkingHours)
  final bool effectiveOnline;

  /// Converte para JSON (somente leitura, pois é uma view)
  Map<String, dynamic> toJson() => {
      'driver_id': driverId,
      'online_intent': onlineIntent,
      'intent_updated_at': intentUpdatedAt.toIso8601String(),
      'is_within_working_hours': isWithinWorkingHours,
      'effective_online': effectiveOnline,
    };

  /// Cria uma cópia com campos alterados
  DriverEffectiveStatus copyWith({
    String? driverId,
    bool? onlineIntent,
    DateTime? intentUpdatedAt,
    bool? isWithinWorkingHours,
    bool? effectiveOnline,
  }) => DriverEffectiveStatus(
      driverId: driverId ?? this.driverId,
      onlineIntent: onlineIntent ?? this.onlineIntent,
      intentUpdatedAt: intentUpdatedAt ?? this.intentUpdatedAt,
      isWithinWorkingHours: isWithinWorkingHours ?? this.isWithinWorkingHours,
      effectiveOnline: effectiveOnline ?? this.effectiveOnline,
    );

  /// Retorna uma descrição do status para exibição
  String get statusDescription {
    if (!onlineIntent) {
      return 'Offline (motorista desligou)';
    }
    if (!isWithinWorkingHours) {
      return 'Offline (fora do horário de trabalho)';
    }
    return 'Online';
  }

  /// Retorna se o motorista pode receber corridas
  bool get canReceiveTrips => effectiveOnline;

  @override
  String toString() => 'DriverEffectiveStatus(driverId: $driverId, onlineIntent: $onlineIntent, isWithinWorkingHours: $isWithinWorkingHours, effectiveOnline: $effectiveOnline)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverEffectiveStatus &&
        other.driverId == driverId &&
        other.onlineIntent == onlineIntent &&
        other.intentUpdatedAt == intentUpdatedAt &&
        other.isWithinWorkingHours == isWithinWorkingHours &&
        other.effectiveOnline == effectiveOnline;
  }

  @override
  int get hashCode => Object.hash(
      driverId,
      onlineIntent,
      intentUpdatedAt,
      isWithinWorkingHours,
      effectiveOnline,
    );
}