import '../../domain/entities/user.dart';

class UserModel extends User {
  final bool profileComplete; // Whether user has completed registration stepper

  UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.phone,
    super.photoUrl,
    required super.userType,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    this.profileComplete = false,
  });

  /// Cria um UserModel a partir de um Map (dados do Supabase)
  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String?,
      photoUrl: map['photo_url'] as String?,
      userType: map['user_type'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      profileComplete: map['profile_complete'] as bool? ?? false,
    );

  /// Cria um UserModel a partir de JSON (deserialização)
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);

  /// Converte o UserModel para um Map (para enviar ao Supabase)
  Map<String, dynamic> toMap() => {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'photo_url': photoUrl,
      'user_type': userType,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'profile_complete': profileComplete,
    };

  /// Converte para Map apenas com campos necessários para inserção
  Map<String, dynamic> toInsertMap() => {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'photo_url': photoUrl,
      'user_type': userType,
      'status': status,
      'profile_complete': profileComplete,
    };

  /// Cria uma cópia do UserModel com campos atualizados
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? photoUrl,
    String? userType,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? profileComplete,
  }) => UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileComplete: profileComplete ?? this.profileComplete,
    );

  @override
  String toString() => 'UserModel(id: $id, email: $email, fullName: $fullName, userType: $userType, status: $status, profileComplete: $profileComplete)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Converte o UserModel para JSON (serialização)
  Map<String, dynamic> toJson() => toMap();

  /// Verifica se o usuário está ativo
  bool get isActive => status == 'active';

  /// Verifica se o usuário completou o processo de registro
  bool get hasCompletedRegistration => profileComplete;

  /// Verifica se o usuário precisa completar o stepper de registro
  bool get needsToCompleteRegistration => !profileComplete;
  
  /// Converte para entidade de domínio
  User toEntity() => User(
    id: id,
    email: email,
    fullName: fullName,
    phone: phone,
    photoUrl: photoUrl,
    userType: userType,
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}