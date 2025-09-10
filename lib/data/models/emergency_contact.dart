/// Modelo para contato de emergência
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.userId,
    required this.contactUserId,
    required this.contactName,
    required this.contactPhone,
    required this.relationship,
    required this.isActive,
    required this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: json['id'],
        userId: json['user_id'],
        contactUserId: json['contact_user_id'],
        contactName: json['contact_name'],
        contactPhone: json['contact_phone'],
        relationship: json['relationship'] ?? '',
        isActive: json['is_active'] ?? true,
        createdAt: DateTime.parse(json['created_at']),
      );

  final String id;
  final String userId;
  final String contactUserId;
  final String contactName;
  final String contactPhone;
  final String relationship;
  final bool isActive;
  final DateTime createdAt;

  String get name => contactName;
  String get phone => contactPhone;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'contact_user_id': contactUserId,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'relationship': relationship,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };
}