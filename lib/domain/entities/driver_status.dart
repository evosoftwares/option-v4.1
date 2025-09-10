/// Entidade de domínio para status de intenção online do motorista
/// Representa a intenção do motorista (toggle) separadamente do status efetivo
class DriverStatus {
  final String driverId;
  final bool onlineIntent;
  final DateTime updatedAt;

  const DriverStatus({
    required this.driverId,
    required this.onlineIntent,
    required this.updatedAt,
  });

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
}