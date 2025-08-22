import 'dart:convert';
import 'package:http/http.dart' as http;
import '../exceptions/app_exceptions.dart';

/// Serviço para validação geográfica de dados
/// Verifica se bairros, cidades e estados existem realmente
class GeographicValidationService {
  static const String _baseUrl = 'https://servicodados.ibge.gov.br/api/v1';
  static const Duration _timeout = Duration(seconds: 10);
  
  // Cache para evitar consultas repetidas
  static final Map<String, bool> _validationCache = {};
  static final Map<String, List<String>> _cityCache = {};
  
  /// Valida se uma cidade existe no estado especificado
  static Future<bool> validateCity(String city, String state) async {
    try {
      final normalizedCity = _normalizeString(city);
      final normalizedState = _normalizeString(state);
      final cacheKey = '${normalizedState}_${normalizedCity}';
      
      // Verifica cache primeiro
      if (_validationCache.containsKey(cacheKey)) {
        return _validationCache[cacheKey]!;
      }
      
      // Busca cidades do estado
      final cities = await _getCitiesFromState(normalizedState);
      final isValid = cities.any((c) => _normalizeString(c) == normalizedCity);
      
      // Armazena no cache
      _validationCache[cacheKey] = isValid;
      
      return isValid;
    } catch (e) {
      // Em caso de erro na API, considera válido para não bloquear o usuário
      return true;
    }
  }
  
  /// Valida se um estado existe
  static Future<bool> validateState(String state) async {
    try {
      final normalizedState = _normalizeString(state);
      final cacheKey = 'state_$normalizedState';
      
      // Verifica cache primeiro
      if (_validationCache.containsKey(cacheKey)) {
        return _validationCache[cacheKey]!;
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/localidades/estados'),
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> states = json.decode(response.body);
        final isValid = states.any((s) => 
          _normalizeString(s['nome']) == normalizedState ||
          _normalizeString(s['sigla']) == normalizedState
        );
        
        // Armazena no cache
        _validationCache[cacheKey] = isValid;
        
        return isValid;
      }
      
      return true; // Em caso de erro, considera válido
    } catch (e) {
      return true; // Em caso de erro, considera válido
    }
  }
  
  /// Busca sugestões de cidades para um estado
  static Future<List<String>> getCitySuggestions(String state, {String? query}) async {
    try {
      final normalizedState = _normalizeString(state);
      final cities = await _getCitiesFromState(normalizedState);
      
      if (query == null || query.isEmpty) {
        return cities.take(20).toList();
      }
      
      final normalizedQuery = _normalizeString(query);
      return cities
          .where((city) => _normalizeString(city).contains(normalizedQuery))
          .take(20)
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Busca sugestões de estados
  static Future<List<String>> getStateSuggestions({String? query}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/localidades/estados'),
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> states = json.decode(response.body);
        List<String> stateNames = states.map((s) => s['nome'] as String).toList();
        
        if (query == null || query.isEmpty) {
          return stateNames;
        }
        
        final normalizedQuery = _normalizeString(query);
        return stateNames
            .where((state) => _normalizeString(state).contains(normalizedQuery))
            .toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  /// Valida um endereço completo
  static Future<ValidationResult> validateAddress({
    required String neighborhood,
    required String city,
    required String state,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Validações básicas
    if (neighborhood.trim().length < 2) {
      errors.add('Nome do bairro deve ter pelo menos 2 caracteres');
    }
    
    if (city.trim().length < 2) {
      errors.add('Nome da cidade deve ter pelo menos 2 caracteres');
    }
    
    if (state.trim().length < 2) {
      errors.add('Nome do estado deve ter pelo menos 2 caracteres');
    }
    
    // Validação de caracteres
    if (!_isValidLocationName(neighborhood)) {
      errors.add('Nome do bairro contém caracteres inválidos');
    }
    
    if (!_isValidLocationName(city)) {
      errors.add('Nome da cidade contém caracteres inválidos');
    }
    
    if (!_isValidLocationName(state)) {
      errors.add('Nome do estado contém caracteres inválidos');
    }
    
    // Se há erros básicos, retorna sem validar geograficamente
    if (errors.isNotEmpty) {
      return ValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
      );
    }
    
    // Validação geográfica
    try {
      final isValidState = await validateState(state);
      if (!isValidState) {
        warnings.add('Estado "$state" não foi encontrado na base de dados do IBGE');
      }
      
      final isValidCity = await validateCity(city, state);
      if (!isValidCity) {
        warnings.add('Cidade "$city" não foi encontrada no estado "$state"');
      }
      
      // Bairros não são validados via API pois não há base confiável
      // Apenas fazemos validação básica de formato
      
    } catch (e) {
      warnings.add('Não foi possível validar os dados geograficamente. Verifique sua conexão.');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Busca cidades de um estado (com cache)
  static Future<List<String>> _getCitiesFromState(String state) async {
    final normalizedState = _normalizeString(state);
    
    // Verifica cache primeiro
    if (_cityCache.containsKey(normalizedState)) {
      return _cityCache[normalizedState]!;
    }
    
    // Primeiro, busca o ID do estado
    final statesResponse = await http.get(
      Uri.parse('$_baseUrl/localidades/estados'),
      headers: {'Accept': 'application/json'},
    ).timeout(_timeout);
    
    if (statesResponse.statusCode != 200) {
      throw const DatabaseException('Erro ao buscar estados');
    }
    
    final List<dynamic> states = json.decode(statesResponse.body);
    final stateData = states.firstWhere(
      (s) => _normalizeString(s['nome']) == normalizedState ||
             _normalizeString(s['sigla']) == normalizedState,
      orElse: () => null,
    );
    
    if (stateData == null) {
      return [];
    }
    
    // Busca cidades do estado
    final citiesResponse = await http.get(
      Uri.parse('$_baseUrl/localidades/estados/${stateData['id']}/municipios'),
      headers: {'Accept': 'application/json'},
    ).timeout(_timeout);
    
    if (citiesResponse.statusCode != 200) {
      throw const DatabaseException('Erro ao buscar cidades');
    }
    
    final List<dynamic> cities = json.decode(citiesResponse.body);
    final cityNames = cities.map((c) => c['nome'] as String).toList();
    
    // Armazena no cache
    _cityCache[normalizedState] = cityNames;
    
    return cityNames;
  }
  
  /// Normaliza string para comparação
  static String _normalizeString(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
  
  /// Verifica se o nome contém apenas caracteres válidos
  static bool _isValidLocationName(String name) {
    return RegExp(r'^[a-zA-ZÀ-ÿ\s\-\.]+$').hasMatch(name);
  }
  
  /// Limpa o cache (útil para testes)
  static void clearCache() {
    _validationCache.clear();
    _cityCache.clear();
  }
}

/// Resultado da validação geográfica
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  
  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
  
  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  
  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
  }
}