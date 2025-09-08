// ARQUIVO REMOVIDO - Locais salvos não são mais suportados
// Este arquivo existe apenas para evitar erros de compilação
// TODO: Remover todas as referências a FavoriteLocation do projeto

@Deprecated('Locais salvos foram removidos do projeto')
class FavoriteLocation {
  FavoriteLocation({
    this.id,
    this.userId,
    this.name = '',
    this.address = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.placeId,
    this.type = LocationType.other,
    this.createdAt,
  });

  final String? id;
  final String? userId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;
  final LocationType type;
  final DateTime? createdAt;

  factory FavoriteLocation.fromMap(Map<String, dynamic> map) {
    throw UnsupportedError('Locais salvos foram removidos do projeto');
  }

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) {
    throw UnsupportedError('Locais salvos foram removidos do projeto');
  }

  Map<String, dynamic> toMap() {
    throw UnsupportedError('Locais salvos foram removidos do projeto');
  }

  Map<String, dynamic> toJson() {
    throw UnsupportedError('Locais salvos foram removidos do projeto');
  }

  FavoriteLocation copyWith({
    String? id,
    String? userId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? placeId,
    LocationType? type,
    DateTime? createdAt,
  }) {
    throw UnsupportedError('Locais salvos foram removidos do projeto');
  }
}

@Deprecated('Locais salvos foram removidos do projeto')
enum LocationType {
  home,
  work,
  other,
  favorite;

  String get label {
    throw UnsupportedError('Locais salvos foram removidos do projeto');
  }

  String get description {
    throw UnsupportedError('Locais salvos foram removidos do projeto');
  }

  dynamic get icon {
    throw UnsupportedError('Locais salvos foram removidos do projeto');
  }
}