import 'package:flutter/foundation.dart';

@immutable
class VehicleBrand {
  const VehicleBrand({
    required this.id,
    required this.name,
    required this.code,
  });

  factory VehicleBrand.fromJson(Map<String, dynamic> json) => VehicleBrand(
        id: json['codigo'] as int,
        name: json['nome'] as String,
        code: json['codigo'].toString(),
      );

  final int id;
  final String name;
  final String code;

  Map<String, dynamic> toJson() => {
        'codigo': id,
        'nome': name,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is VehicleBrand && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => name;
}