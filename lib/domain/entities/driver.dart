class Driver {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String licenseNumber;
  final String licensePlate;
  final String category;
  final bool isOnline;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  Driver({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.licensePlate,
    required this.category,
    required this.isOnline,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  Driver copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    String? licenseNumber,
    String? licensePlate,
    String? category,
    bool? isOnline,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licensePlate: licensePlate ?? this.licensePlate,
      category: category ?? this.category,
      isOnline: isOnline ?? this.isOnline,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}