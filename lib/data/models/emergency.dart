/// Tipos de emergência
enum EmergencyType {
  panic,
  accident,
  medical,
  security,
  other,
}

/// Modelo de emergência
class Emergency {
  const Emergency({
    required this.id,
    required this.userId,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    this.description,
    this.isResolved = false,
    this.resolvedAt,
    this.emergencyContacts,
  });

  factory Emergency.fromJson(Map<String, dynamic> json) => Emergency(
        id: json['id'],
        userId: json['user_id'],
        type: EmergencyType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => EmergencyType.other,
        ),
        latitude: json['latitude']?.toDouble() ?? 0.0,
        longitude: json['longitude']?.toDouble() ?? 0.0,
        address: json['address'] ?? '',
        timestamp: DateTime.parse(json['timestamp']),
        description: json['description'],
        isResolved: json['is_resolved'] ?? false,
        resolvedAt: json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'])
            : null,
        emergencyContacts: json['emergency_contacts'] != null
            ? List<String>.from(json['emergency_contacts'])
            : null,
      );

  final String id;
  final String userId;
  final EmergencyType type;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final String? description;
  final bool isResolved;
  final DateTime? resolvedAt;
  final List<String>? emergencyContacts;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type.name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'timestamp': timestamp.toIso8601String(),
        'description': description,
        'is_resolved': isResolved,
        'resolved_at': resolvedAt?.toIso8601String(),
        'emergency_contacts': emergencyContacts,
      };
}