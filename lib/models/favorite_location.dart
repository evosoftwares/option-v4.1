import 'package:flutter/material.dart';

enum LocationType {
  home,
  work,
  school,
  gym,
  restaurant,
  shopping,
  favorite,
  other,
}

extension LocationTypeExtension on LocationType {
  IconData get icon {
    switch (this) {
      case LocationType.home:
        return Icons.home;
      case LocationType.work:
        return Icons.work;
      case LocationType.school:
        return Icons.school;
      case LocationType.gym:
        return Icons.fitness_center;
      case LocationType.restaurant:
        return Icons.restaurant;
      case LocationType.shopping:
        return Icons.shopping_cart;
      case LocationType.favorite:
        return Icons.favorite;
      case LocationType.other:
        return Icons.place;
    }
  }

  String get label {
    switch (this) {
      case LocationType.home:
        return 'Casa';
      case LocationType.work:
        return 'Trabalho';
      case LocationType.school:
        return 'Escola';
      case LocationType.gym:
        return 'Academia';
      case LocationType.restaurant:
        return 'Restaurante';
      case LocationType.shopping:
        return 'Shopping';
      case LocationType.favorite:
        return 'Favorito';
      case LocationType.other:
        return 'Outro';
    }
  }

  String get description {
    switch (this) {
      case LocationType.home:
        return 'Sua residência';
      case LocationType.work:
        return 'Seu local de trabalho';
      case LocationType.school:
        return 'Sua escola ou universidade';
      case LocationType.gym:
        return 'Sua academia';
      case LocationType.restaurant:
        return 'Seu restaurante favorito';
      case LocationType.shopping:
        return 'Seu shopping favorito';
      case LocationType.favorite:
        return 'Local favorito';
      case LocationType.other:
        return 'Outro local importante';
    }
  }
}

class FavoriteLocation {

  FavoriteLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    this.latitude,
    this.longitude,
    this.placeId,
  });

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) {
    return FavoriteLocation(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      type: LocationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => LocationType.other,
      ),
      latitude: json['latitude'],
      longitude: json['longitude'],
      placeId: json['placeId'],
    );
  }
  final String id;
  final String name;
  final String address;
  final LocationType type;
  final double? latitude;
  final double? longitude;
  final String? placeId;

  FavoriteLocation copyWith({
    String? id,
    String? name,
    String? address,
    LocationType? type,
    double? latitude,
    double? longitude,
    String? placeId,
  }) => FavoriteLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
    );

  Map<String, dynamic> toJson() => {
      'id': id,
      'name': name,
      'address': address,
      'type': type.toString(),
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
    };
}