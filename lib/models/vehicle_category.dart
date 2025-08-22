/// Enum que define as categorias de veículos disponíveis no sistema
/// Baseado na coluna vehicle_category das tabelas drivers e trips
enum VehicleCategory {
  /// Categoria econômica para viagens simples
  economico('economico', 'Econômico', 'Viagem simples e econômica'),
  
  /// Categoria standard com conforto equilibrado
  standard('standard', 'Standard', 'Conforto equilibrado'),
  
  /// Categoria premium com veículos de luxo
  premium('premium', 'Premium', 'Veículos de luxo'),
  
  /// Categoria SUV para veículos espaçosos
  suv('suv', 'SUV', 'Veículos espaçosos'),
  
  /// Categoria executiva premium
  executivo('executivo', 'Executivo', 'Categoria executiva'),
  
  /// Categoria van para grupos e bagagens
  van('van', 'Van', 'Grupos e bagagens');

  const VehicleCategory(this.id, this.displayName, this.description);

  /// Identificador único da categoria
  final String id;
  
  /// Nome para exibição
  final String displayName;
  
  /// Descrição da categoria
  final String description;

  /// Retorna a categoria baseada no ID
  static VehicleCategory? fromId(String? id) {
    if (id == null) {
      return null;
    }
    try {
      return VehicleCategory.values.firstWhere((cat) => cat.id == id);
    } on Exception {
      return null;
    }
  }

  /// Retorna todas as categorias disponíveis
  static List<VehicleCategory> get allCategories => VehicleCategory.values;

  /// Retorna as categorias mais comuns (para UI)
  static List<VehicleCategory> get popularCategories => [
    VehicleCategory.economico,
    VehicleCategory.standard,
    VehicleCategory.premium,
    VehicleCategory.suv,
  ];
}

/// Dados detalhados de uma categoria de veículo
/// Inclui informações de preços e disponibilidade
class VehicleCategoryData {
  final VehicleCategory category;
  final double basePricePerKm;
  final double basePricePerMinute;
  final double surgeMultiplier;
  final int availableDrivers;
  final String estimatedArrival;
  final bool isAvailable;

  const VehicleCategoryData({
    required this.category,
    required this.basePricePerKm,
    required this.basePricePerMinute,
    this.surgeMultiplier = 1.0,
    this.availableDrivers = 0,
    this.estimatedArrival = '5-10 min',
    this.isAvailable = true,
  });

  /// Calcula o preço estimado para uma distância e tempo
  double calculateEstimatedPrice(double distanceKm, int durationMinutes) {
    final basePrice = (basePricePerKm * distanceKm) + (basePricePerMinute * durationMinutes);
    return basePrice * surgeMultiplier;
  }

  /// Cria uma instância com dados padrão para desenvolvimento
  factory VehicleCategoryData.defaultForCategory(VehicleCategory category) {
    switch (category) {
      case VehicleCategory.economico:
        return VehicleCategoryData(
          category: category,
          basePricePerKm: 1.2,
          basePricePerMinute: 0.15,
          availableDrivers: 12,
          estimatedArrival: '3-8 min',
        );
      case VehicleCategory.standard:
        return VehicleCategoryData(
          category: category,
          basePricePerKm: 1.5,
          basePricePerMinute: 0.20,
          availableDrivers: 8,
          estimatedArrival: '5-10 min',
        );
      case VehicleCategory.premium:
        return VehicleCategoryData(
          category: category,
          basePricePerKm: 2.2,
          basePricePerMinute: 0.35,
          availableDrivers: 3,
          estimatedArrival: '8-15 min',
        );
      case VehicleCategory.suv:
        return VehicleCategoryData(
          category: category,
          basePricePerKm: 1.8,
          basePricePerMinute: 0.25,
          availableDrivers: 5,
          estimatedArrival: '6-12 min',
        );
      case VehicleCategory.executivo:
        return VehicleCategoryData(
          category: category,
          basePricePerKm: 2.8,
          basePricePerMinute: 0.45,
          availableDrivers: 2,
          estimatedArrival: '10-20 min',
        );
      case VehicleCategory.van:
        return VehicleCategoryData(
          category: category,
          basePricePerKm: 2.0,
          basePricePerMinute: 0.30,
          availableDrivers: 1,
          estimatedArrival: '15-25 min',
        );
    }
  }

  /// Cria uma cópia com novos valores
  VehicleCategoryData copyWith({
    VehicleCategory? category,
    double? basePricePerKm,
    double? basePricePerMinute,
    double? surgeMultiplier,
    int? availableDrivers,
    String? estimatedArrival,
    bool? isAvailable,
  }) {
    return VehicleCategoryData(
      category: category ?? this.category,
      basePricePerKm: basePricePerKm ?? this.basePricePerKm,
      basePricePerMinute: basePricePerMinute ?? this.basePricePerMinute,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      availableDrivers: availableDrivers ?? this.availableDrivers,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  String toString() => 'VehicleCategoryData(${category.displayName}, drivers: $availableDrivers)';
}