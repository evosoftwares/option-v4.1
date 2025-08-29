class Passenger {

  Passenger({
    required this.id,
    required this.userId,
    required this.rating,
    required this.totalTrips,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.devicePlatform,
    this.lastNotificationAt,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) => Passenger(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      rating: json['rating']?.toDouble() ?? 0.0,
      totalTrips: json['total_trips'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      fcmToken: json['fcm_token'] as String?,
      devicePlatform: json['device_platform'] as String?,
      lastNotificationAt: json['last_notification_at'] != null
          ? DateTime.parse(json['last_notification_at'] as String)
          : null,
    );
  final String id;
  final String userId;
  final double rating;
  final int totalTrips;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  final String? devicePlatform;
  final DateTime? lastNotificationAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'rating': rating,
      'total_trips': totalTrips,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'fcm_token': fcmToken,
      'device_platform': devicePlatform,
      'last_notification_at': lastNotificationAt?.toIso8601String(),
    };

  Passenger copyWith({
    String? id,
    String? userId,
    double? rating,
    int? totalTrips,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    String? devicePlatform,
    DateTime? lastNotificationAt,
  }) => Passenger(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      devicePlatform: devicePlatform ?? this.devicePlatform,
      lastNotificationAt: lastNotificationAt ?? this.lastNotificationAt,
    );
}