enum DriverOnlineStatus {
  online,
  offline,
  transitioning,
}

class DriverStatus {
  final DriverOnlineStatus status;
  final double todayEarnings;
  final int tripsCompleted;
  final Duration onlineTime;
  final DateTime lastStatusChange;

  const DriverStatus({
    required this.status,
    required this.todayEarnings,
    required this.tripsCompleted,
    required this.onlineTime,
    required this.lastStatusChange,
  });

  factory DriverStatus.initial() {
    return DriverStatus(
      status: DriverOnlineStatus.offline,
      todayEarnings: 0.0,
      tripsCompleted: 0,
      onlineTime: Duration.zero,
      lastStatusChange: DateTime.now(),
    );
  }

  DriverStatus copyWith({
    DriverOnlineStatus? status,
    double? todayEarnings,
    int? tripsCompleted,
    Duration? onlineTime,
    DateTime? lastStatusChange,
  }) {
    return DriverStatus(
      status: status ?? this.status,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      tripsCompleted: tripsCompleted ?? this.tripsCompleted,
      onlineTime: onlineTime ?? this.onlineTime,
      lastStatusChange: lastStatusChange ?? this.lastStatusChange,
    );
  }

  bool get isOnline => status == DriverOnlineStatus.online;
  bool get isOffline => status == DriverOnlineStatus.offline;
  bool get isTransitioning => status == DriverOnlineStatus.transitioning;

  String get statusDisplayText {
    switch (status) {
      case DriverOnlineStatus.online:
        return 'Você está online';
      case DriverOnlineStatus.offline:
        return 'Você está offline';
      case DriverOnlineStatus.transitioning:
        return 'Conectando...';
    }
  }

  String get earningsDisplayText {
    return 'R\$ ${todayEarnings.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}