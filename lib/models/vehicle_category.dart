/// Enum que define as categorias de veículos disponíveis no sistema
/// Baseado na coluna category da tabela platform_settings (referenciada por drivers.vehicle_category)
/// ATENÇÃO: Os IDs devem corresponder exatamente aos valores na tabela platform_settings
enum VehicleCategory {
  /// Categoria comum (mais básica e popular)
  /// Corresponde ao valor 'common_car' na base de dados
  commonCar('common_car', 'Carro Comum', 'Categoria padrão para veículos de passeio'),
  
  /// Categoria frete/carga para transporte de mercadorias
  /// Corresponde ao valor 'freight' na base de dados
  freight('freight', 'Frete', 'Transporte de mercadorias e cargas'),
  
  /// Categoria guincho para reboques e assistência
  /// Corresponde ao valor 'tow_truck' na base de dados
  towTruck('tow_truck', 'Guincho', 'Veículos de reboque e assistência');

  const VehicleCategory(this.id, this.displayName, this.description);

  /// Identificador único da categoria
  final String id;
  
  /// Nome para exibição
  final String displayName;
  
  /// Descrição da categoria
  final String description;

  /// Retorna a categoria baseada no ID
  /// Inclui mapeamento para compatibilidade com dados em português do Supabase
  static VehicleCategory? fromId(String? id) {
    if (id == null) {
      return null;
    }
    
    // Mapeamento para compatibilidade com dados do Supabase em português
    final mappedId = _mapPortugueseToEnglish(id);
    
    try {
      return VehicleCategory.values.firstWhere((cat) => cat.id == mappedId);
    } on Exception {
      return null;
    }
  }
  
  /// Mapeia categorias em português do Supabase para IDs em inglês
  static String _mapPortugueseToEnglish(String id) {
    switch (id.toLowerCase()) {
      case 'comum':
        return 'common_car';
      case 'freight':
        return 'freight';
      case 'tow_truck':
        return 'tow_truck';
      default:
        return id; // Retorna o ID original se não houver mapeamento
    }
  }
  
  /// Mapeia IDs em inglês para categorias em português do Supabase
  static String mapEnglishToPortuguese(String id) {
    switch (id.toLowerCase()) {
      case 'common_car':
        return 'Comum';
      case 'freight':
        return 'freight';
      case 'tow_truck':
        return 'tow_truck';
      default:
        return id; // Retorna o ID original se não houver mapeamento
    }
  }

  /// Retorna todas as categorias disponíveis
  static List<VehicleCategory> get allCategories => VehicleCategory.values;

  /// Retorna as categorias mais comuns (para UI)
  static List<VehicleCategory> get popularCategories => [
    VehicleCategory.commonCar,
    VehicleCategory.freight,
    VehicleCategory.towTruck,
  ];
}

/// Dados detalhados de uma categoria de veículo 
/// Carregados dinamicamente do Supabase platform_settings
class VehicleCategoryData {

  const VehicleCategoryData({
    required this.categoryId,
    required this.categoryName,
    required this.basePricePerKm,
    required this.basePricePerMinute,
    this.surgeMultiplier = 1.0,
    this.availableDrivers = 0,
    this.isAvailable = true,
    this.minFare,
  });

  /// Cria uma instância a partir dos dados do platform_settings do Supabase
  factory VehicleCategoryData.fromPlatformSettings({
    required Map<String, dynamic> platformSettings,
    int availableDrivers = 0,
  }) {
    return VehicleCategoryData(
      categoryId: platformSettings['category'] as String,
      categoryName: platformSettings['category'] as String,
      basePricePerKm: (platformSettings['base_price_per_km'] as num).toDouble(),
      basePricePerMinute: (platformSettings['base_price_per_minute'] as num).toDouble(),
      minFare: (platformSettings['min_fare'] as num?)?.toDouble(),
      availableDrivers: availableDrivers,
      isAvailable: availableDrivers > 0,
    );
  }

  /// ⚠️ DEPRECATED: Cria uma instância com dados hardcoded APENAS para desenvolvimento
  /// SEMPRE use fromPlatformSettings() em produção para obter dados do Supabase
  @Deprecated('Use fromPlatformSettings() to get data from Supabase platform_settings')
  factory VehicleCategoryData.defaultForCategory(VehicleCategory category) {
    switch (category) {
      case VehicleCategory.commonCar:
        return VehicleCategoryData(
          categoryId: category.id,
          categoryName: category.displayName,
          basePricePerKm: 1.5,
          basePricePerMinute: 0.20,
          availableDrivers: 15,
        );
      case VehicleCategory.freight:
        return VehicleCategoryData(
          categoryId: category.id,
          categoryName: category.displayName,
          basePricePerKm: 2.0,
          basePricePerMinute: 0.30,
          availableDrivers: 5,
        );
      case VehicleCategory.towTruck:
        return VehicleCategoryData(
          categoryId: category.id,
          categoryName: category.displayName,
          basePricePerKm: 3.0,
          basePricePerMinute: 0.50,
          availableDrivers: 2,
        );
    }
  }
  final String categoryId;
  final String categoryName; 
  final double basePricePerKm;
  final double basePricePerMinute;
  final double surgeMultiplier;
  final int availableDrivers;
  final bool isAvailable;
  final double? minFare;

  /// Calcula o preço estimado para uma distância e tempo
  double calculateEstimatedPrice(double distanceKm, int durationMinutes) {
    final basePrice = (basePricePerKm * distanceKm) + (basePricePerMinute * durationMinutes);
    return basePrice * surgeMultiplier;
  }

  /// Cria uma cópia com novos valores
  VehicleCategoryData copyWith({
    String? categoryId,
    String? categoryName,
    double? basePricePerKm,
    double? basePricePerMinute,
    double? surgeMultiplier,
    int? availableDrivers,
    bool? isAvailable,
    double? minFare,
  }) => VehicleCategoryData(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      basePricePerKm: basePricePerKm ?? this.basePricePerKm,
      basePricePerMinute: basePricePerMinute ?? this.basePricePerMinute,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      availableDrivers: availableDrivers ?? this.availableDrivers,
      isAvailable: isAvailable ?? this.isAvailable,
      minFare: minFare ?? this.minFare,
    );

  @override
  String toString() => 'VehicleCategoryData($categoryName, drivers: $availableDrivers)';
}