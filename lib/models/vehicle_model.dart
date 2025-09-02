import 'package:flutter/foundation.dart';

@immutable
class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.name,
    required this.code,
    required this.brandId,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json, int brandId) => VehicleModel(
        id: json['codigo'] as int,
        name: json['nome'] as String,
        code: json['codigo'].toString(),
        brandId: brandId,
      );

  final int id;
  final String name;
  final String code;
  final int brandId;

  Map<String, dynamic> toJson() => {
        'codigo': id,
        'nome': name,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is VehicleModel && 
           other.id == id && 
           other.name == name && 
           other.brandId == brandId;
  }

  @override
  int get hashCode => Object.hash(id, name, brandId);

  @override
  String toString() => name;
}