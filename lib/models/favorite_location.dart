import 'package:flutter/material.dart';
import '../services/favorite_locations_service.dart';

enum LocationType {
  home,
  work,
  school,
  gym,
  restaurant,
  shopping,
  hospital,
  bank,
  pharmacy,
  gasStation,
  park,
  cinema,
  airport,
  hotel,
  church,
  beach,
  library,
  supermarket,
  cafe,
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
      case LocationType.hospital:
        return Icons.local_hospital;
      case LocationType.bank:
        return Icons.account_balance;
      case LocationType.pharmacy:
        return Icons.local_pharmacy;
      case LocationType.gasStation:
        return Icons.local_gas_station;
      case LocationType.park:
        return Icons.park;
      case LocationType.cinema:
        return Icons.movie;
      case LocationType.airport:
        return Icons.flight;
      case LocationType.hotel:
        return Icons.hotel;
      case LocationType.church:
        return Icons.church;
      case LocationType.beach:
        return Icons.beach_access;
      case LocationType.library:
        return Icons.library_books;
      case LocationType.supermarket:
        return Icons.store;
      case LocationType.cafe:
        return Icons.local_cafe;
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
      case LocationType.hospital:
        return 'Hospital';
      case LocationType.bank:
        return 'Banco';
      case LocationType.pharmacy:
        return 'Farmácia';
      case LocationType.gasStation:
        return 'Posto';
      case LocationType.park:
        return 'Parque';
      case LocationType.cinema:
        return 'Cinema';
      case LocationType.airport:
        return 'Aeroporto';
      case LocationType.hotel:
        return 'Hotel';
      case LocationType.church:
        return 'Igreja';
      case LocationType.beach:
        return 'Praia';
      case LocationType.library:
        return 'Biblioteca';
      case LocationType.supermarket:
        return 'Mercado';
      case LocationType.cafe:
        return 'Café';
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
      case LocationType.hospital:
        return 'Hospital ou clínica';
      case LocationType.bank:
        return 'Agência bancária';
      case LocationType.pharmacy:
        return 'Farmácia ou drogaria';
      case LocationType.gasStation:
        return 'Posto de combustível';
      case LocationType.park:
        return 'Parque ou área verde';
      case LocationType.cinema:
        return 'Cinema ou teatro';
      case LocationType.airport:
        return 'Aeroporto ou terminal';
      case LocationType.hotel:
        return 'Hotel ou pousada';
      case LocationType.church:
        return 'Igreja ou templo';
      case LocationType.beach:
        return 'Praia ou orla';
      case LocationType.library:
        return 'Biblioteca ou livraria';
      case LocationType.supermarket:
        return 'Supermercado ou mercado';
      case LocationType.cafe:
        return 'Café ou padaria';
      case LocationType.favorite:
        return 'Local favorito';
      case LocationType.other:
        return 'Outro local importante';
    }
  }
}

class FavoriteLocation {

  FavoriteLocation({
    this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.type,
    this.latitude,
    this.longitude,
    this.placeId,
    this.createdAt,
    this.updatedAt,
  });

  /// Cria uma instância a partir do SavedPlace do FavoriteLocationsService
  factory FavoriteLocation.fromSavedPlace(SavedPlace savedPlace) => FavoriteLocation(
      id: savedPlace.id,
      userId: savedPlace.userId,
      name: savedPlace.label, // Mapeia label do SavedPlace para name do FavoriteLocation
      address: savedPlace.address,
      type: savedPlace.category, // Usa a category do SavedPlace
      latitude: savedPlace.latitude,
      longitude: savedPlace.longitude,
      createdAt: savedPlace.createdAt,
      updatedAt: savedPlace.updatedAt,
    );

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) => FavoriteLocation(
      id: json['id'],
      userId: json['user_id'] ?? json['userId'] ?? 'temp-user', // Valor padrão para evitar erro
      name: json['label'] ?? json['name'] ?? 'Local', // Valor padrão
      address: json['address'] ?? 'Endereço não informado', // Valor padrão
      type: LocationType.values.firstWhere(
        (e) => e.toString() == json['category'] || e.name == json['category'] || e.toString() == json['type'] || e.name == json['type'],
        orElse: () => LocationType.other,
      ),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      placeId: json['place_id'] ?? json['placeId'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  final String? id;
  final String userId;
  final String name;
  final String address;
  final LocationType type;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FavoriteLocation copyWith({
    String? id,
    String? userId,
    String? name,
    String? address,
    LocationType? type,
    double? latitude,
    double? longitude,
    String? placeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FavoriteLocation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'label': name, // Mapeia 'name' do modelo para 'label' do banco
      'address': address,
      'category': type.name, // Mapeia 'type' do modelo para 'category' do banco
      'latitude': latitude,
      'longitude': longitude,
      'place_id': placeId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };

  /// Converte para formato de inserção no Supabase
  Map<String, dynamic> toInsertJson() => {
      'user_id': userId,
      'label': name, // Mapeia 'name' do modelo para 'label' do banco
      'address': address,
      'category': type.name, // Mapeia 'type' do modelo para 'category' do banco
      'latitude': latitude,
      'longitude': longitude,
    };
}