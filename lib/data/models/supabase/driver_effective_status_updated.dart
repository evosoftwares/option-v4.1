/// Modelo para o status efetivo do motorista (view driver_effective_status)
/// Nova lógica: motorista só fica online se todos os documentos estão validados
class DriverEffectiveStatus {
  const DriverEffectiveStatus({
    required this.driverId,
    required this.onlineIntent,
    required this.intentUpdatedAt,
    required this.documentsValidated,
    required this.effectiveOnline,
  });

  /// Converte de JSON do Supabase (view)
  factory DriverEffectiveStatus.fromJson(Map<String, dynamic> json) {
    return DriverEffectiveStatus(
      driverId: json['driver_id'] as String,
      onlineIntent: json['online_intent'] as bool,
      intentUpdatedAt: DateTime.parse(json['intent_updated_at'] as String),
      documentsValidated: json['documents_validated'] as bool,
      effectiveOnline: json['effective_online'] as bool,
    );
  }

  /// ID do motorista
  final String driverId;

  /// Intenção do motorista de ficar online (do driver_status)
  final bool onlineIntent;

  /// Data de última atualização da intenção
  final DateTime intentUpdatedAt;

  /// Se todos os documentos obrigatórios estão validados
  /// (CNH, CRLV aprovados + driver aprovado)
  final bool documentsValidated;

  /// Status efetivo online (onlineIntent AND documentsValidated)
  final bool effectiveOnline;

  /// Converte para JSON (somente leitura, pois é uma view)
  Map<String, dynamic> toJson() => {
        'driver_id': driverId,
        'online_intent': onlineIntent,
        'intent_updated_at': intentUpdatedAt.toIso8601String(),
        'documents_validated': documentsValidated,
        'effective_online': effectiveOnline,
      };

  /// Cria uma cópia com campos alterados
  DriverEffectiveStatus copyWith({
    String? driverId,
    bool? onlineIntent,
    DateTime? intentUpdatedAt,
    bool? documentsValidated,
    bool? effectiveOnline,
  }) =>
      DriverEffectiveStatus(
        driverId: driverId ?? this.driverId,
        onlineIntent: onlineIntent ?? this.onlineIntent,
        intentUpdatedAt: intentUpdatedAt ?? this.intentUpdatedAt,
        documentsValidated: documentsValidated ?? this.documentsValidated,
        effectiveOnline: effectiveOnline ?? this.effectiveOnline,
      );

  /// Retorna uma descrição do status para exibição
  String get statusDescription {
    if (!onlineIntent) {
      return 'Offline (motorista desligou)';
    }

    if (!documentsValidated) {
      return 'Offline (documentos pendentes de aprovação)';
    }

    return 'Online';
  }

  /// Retorna se o motorista pode receber corridas
  bool get canReceiveTrips => effectiveOnline;

  /// Retorna a razão pela qual o motorista não está online (se aplicável)
  String? get offlineReason {
    if (effectiveOnline) return null;

    if (!onlineIntent) {
      return 'Motorista escolheu ficar offline';
    }

    if (!documentsValidated) {
      return 'Documentos não estão aprovados. Verifique CNH, CRLV e status de aprovação.';
    }

    return 'Status desconhecido';
  }

  /// Indica se o problema é relacionado à documentação
  bool get hasDocumentIssues => !documentsValidated;

  @override
  String toString() =>
      'DriverEffectiveStatus(driverId: $driverId, onlineIntent: $onlineIntent, documentsValidated: $documentsValidated, effectiveOnline: $effectiveOnline)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverEffectiveStatus &&
        other.driverId == driverId &&
        other.onlineIntent == onlineIntent &&
        other.intentUpdatedAt == intentUpdatedAt &&
        other.documentsValidated == documentsValidated &&
        other.effectiveOnline == effectiveOnline;
  }

  @override
  int get hashCode => Object.hash(
        driverId,
        onlineIntent,
        intentUpdatedAt,
        documentsValidated,
        effectiveOnline,
      );
}
