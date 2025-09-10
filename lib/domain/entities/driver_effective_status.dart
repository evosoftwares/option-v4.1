/// Entidade de domínio para o status efetivo do motorista
/// Combina a intenção online com a elegibilidade do motorista
class DriverEffectiveStatus {
  final String driverId;
  final bool onlineIntent;
  final DateTime intentUpdatedAt;
  final bool effectiveOnline;

  const DriverEffectiveStatus({
    required this.driverId,
    required this.onlineIntent,
    required this.intentUpdatedAt,
    required this.effectiveOnline,
  });

  DriverEffectiveStatus copyWith({
    String? driverId,
    bool? onlineIntent,
    DateTime? intentUpdatedAt,
    bool? effectiveOnline,
  }) {
    return DriverEffectiveStatus(
      driverId: driverId ?? this.driverId,
      onlineIntent: onlineIntent ?? this.onlineIntent,
      intentUpdatedAt: intentUpdatedAt ?? this.intentUpdatedAt,
      effectiveOnline: effectiveOnline ?? this.effectiveOnline,
    );
  }

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