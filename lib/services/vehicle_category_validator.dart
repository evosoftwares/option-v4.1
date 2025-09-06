import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../exceptions/validation_exception.dart' as validation;
import 'platform_settings_service.dart';

class VehicleCategoryValidator {
  VehicleCategoryValidator(this._supabase);
  final SupabaseClient _supabase;

  late final PlatformSettingsService _platformSettingsService;

  /// Inicializa o validador
  Future<void> initialize() async {
    _platformSettingsService = PlatformSettingsService(_supabase);
  }

  /// Valida se uma categoria de veículo existe na tabela platform_settings
  Future<void> validateVehicleCategoryExists(String category) async {
    if (category.isEmpty) {
      throw const validation.ValidationException('Categoria de veículo não pode estar vazia');
    }

    try {
      final settings = await _platformSettingsService.getSettingsByCategory(category);
      
      if (settings == null) {
        throw validation.ValidationException('Categoria de veículo "$category" não existe nas configurações da plataforma');
      }
    } on DatabaseException catch (e) {
      throw validation.ValidationException('Erro ao validar categoria de veículo: ${e.message}');
    } catch (e) {
      throw validation.ValidationException('Erro inesperado ao validar categoria de veículo');
    }
  }

  /// Valida múltiplas categorias de veículo
  Future<void> validateVehicleCategoriesExist(List<String> categories) async {
    for (final category in categories) {
      await validateVehicleCategoryExists(category);
    }
  }

  /// Obtém todas as categorias de veículo válidas da plataforma
  Future<List<String>> getValidVehicleCategories() async {
    try {
      final allSettings = await _platformSettingsService.getAllSettings();
      return allSettings.map((settings) => settings.category).toList();
    } on DatabaseException catch (e) {
      throw validation.ValidationException('Erro ao buscar categorias de veículo: ${e.message}');
    } catch (e) {
      throw validation.ValidationException('Erro inesperado ao buscar categorias de veículo');
    }
  }

  /// Verifica se uma categoria é válida (método síncrono usando cache)
  bool isVehicleCategoryValid(String category) {
    // Este método pode ser implementado se necessário, mas requer
    // acesso ao cache interno do PlatformSettingsService
    // Por enquanto, use validateVehicleCategoryExists para validação completa
    return category.isNotEmpty; // Apenas validação básica
  }
}