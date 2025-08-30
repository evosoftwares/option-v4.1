class AppUser {

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    this.photoUrl,
    required this.userType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.onesignalPlayerId,
    this.pushToken,
    this.lastActiveAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      photoUrl: json['photo_url'] as String?,
      userType: json['user_type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userId: json['user_id'] as String?,
      onesignalPlayerId: json['onesignal_player_id'] as String?,
      pushToken: json['push_token'] as String?,
      lastActiveAt: json['last_active_at'] != null 
          ? DateTime.parse(json['last_active_at'] as String) 
          : null,
    );
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String? photoUrl;
  final String userType;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;
  final String? onesignalPlayerId;
  final String? pushToken;
  final DateTime? lastActiveAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'photo_url': photoUrl,
      'user_type': userType,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'onesignal_player_id': onesignalPlayerId,
      'push_token': pushToken,
      'last_active_at': lastActiveAt?.toIso8601String(),
    };

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? photoUrl,
    String? userType,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? onesignalPlayerId,
    String? pushToken,
    DateTime? lastActiveAt,
  }) => AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      onesignalPlayerId: onesignalPlayerId ?? this.onesignalPlayerId,
      pushToken: pushToken ?? this.pushToken,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );

  // Helper methods
  bool get isPassenger => userType == 'passenger';
  bool get isDriver => userType == 'driver';
  bool get isActive => status == 'active';
  bool get isVerified => status == 'active' || status == 'verified';
  bool get canUseApp => isActive && isVerified;
}