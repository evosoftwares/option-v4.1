import 'dart:async';

import '../exceptions/app_exceptions.dart';

/// Service responsible for validating and normalizing excluded zone data
/// Addresses critical security issues identified in the zones analysis
class ZoneValidationService {
  /// Private constructor to prevent instantiation
  ZoneValidationService._();

  /// Maximum number of excluded zones allowed per driver
  static const int maxZonesPerDriver = 50;
  
  /// Valid Brazilian state codes (normalized to lowercase)
  static const Set<String> validBrazilianStates = {
    'ac', 'al', 'ap', 'am', 'ba', 'ce', 'df', 'es', 'go',
    'ma', 'mt', 'ms', 'mg', 'pa', 'pb', 'pr', 'pe', 'pi',
    'rj', 'rn', 'rs', 'ro', 'rr', 'sc', 'sp', 'se', 'to',
  };
  
  /// Map of common state name variations to official codes
  static const Map<String, String> stateVariations = {
    'acre': 'ac',
    'alagoas': 'al',
    'amapa': 'ap',
    'amazonas': 'am',
    'bahia': 'ba',
    'ceara': 'ce',
    'distrito federal': 'df',
    'espirito santo': 'es',
    'goias': 'go',
    'maranhao': 'ma',
    'mato grosso': 'mt',
    'mato grosso do sul': 'ms',
    'minas gerais': 'mg',
    'para': 'pa',
    'paraiba': 'pb',
    'parana': 'pr',
    'pernambuco': 'pe',
    'piaui': 'pi',
    'rio de janeiro': 'rj',
    'rio grande do norte': 'rn',
    'rio grande do sul': 'rs',
    'rondonia': 'ro',
    'roraima': 'rr',
    'santa catarina': 'sc',
    'sao paulo': 'sp',
    'sergipe': 'se',
    'tocantins': 'to',
  };
  
  /// Normalizes text for consistent comparison and storage
  /// Fixes case sensitivity and accent variations issues
  static String normalizeText(String text) {
    if (text.isEmpty) return text;
    
    // Convert to lowercase and trim
    var normalized = text.toLowerCase().trim();
    
    // Replace multiple spaces with single space
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove accents and special characters
    const accentMap = {
      'ã': 'a', 'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a',
      'õ': 'o', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'ç': 'c', 'ñ': 'n',
    };
    
    for (final entry in accentMap.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    
    return normalized;
  }
  
  /// Validates and normalizes a Brazilian state code or name
  /// Returns the official state code if valid, throws exception if invalid
  static String validateAndNormalizeState(String state) {
    if (state.isEmpty) {
      throw const ValidationException('Estado não pode estar vazio');
    }
    
    final normalized = normalizeText(state);
    
    // Check if it's already a valid state code
    if (validBrazilianStates.contains(normalized)) {
      return normalized;
    }
    
    // Check if it's a state name variation
    if (stateVariations.containsKey(normalized)) {
      return stateVariations[normalized]!;
    }
    
    throw ValidationException('Estado inválido: $state');
  }
  
  /// Validates that a neighborhood name is not empty after normalization
  static String validateAndNormalizeNeighborhood(String neighborhood) {
    if (neighborhood.isEmpty) {
      throw const ValidationException('Nome do bairro não pode estar vazio');
    }
    
    final normalized = normalizeText(neighborhood);
    
    if (normalized.isEmpty) {
      throw const ValidationException('Nome do bairro não pode estar vazio após normalização');
    }
    
    return normalized;
  }
  
  /// Validates that a city name is not empty after normalization
  static String validateAndNormalizeCity(String city) {
    if (city.isEmpty) {
      throw const ValidationException('Nome da cidade não pode estar vazio');
    }
    
    final normalized = normalizeText(city);
    
    if (normalized.isEmpty) {
      throw const ValidationException('Nome da cidade não pode estar vazio após normalização');
    }
    
    return normalized;
  }
  
  /// Validates that the location combination is valid
  /// This can be extended to integrate with external APIs for validation
  static Future<bool> validateLocationExists({
    required String neighborhood,
    required String city,
    required String state,
  }) async {
    try {
      // Normalize all inputs
      final normalizedNeighborhood = validateAndNormalizeNeighborhood(neighborhood);
      final normalizedCity = validateAndNormalizeCity(city);
      final normalizedState = validateAndNormalizeState(state);
      
      // Basic validation - ensure they're not empty and state is valid
      // TODO: Integrate with external geocoding API (Google Maps, ViaCEP, etc.)
      // for now, we return true if basic validation passes
      
      return normalizedNeighborhood.isNotEmpty && 
             normalizedCity.isNotEmpty && 
             validBrazilianStates.contains(normalizedState);
    } catch (e) {
      return false;
    }
  }
  
  /// Creates a normalized zone identifier for comparison
  static String createZoneIdentifier({
    required String neighborhood,
    required String city,
    required String state,
  }) {
    return '${normalizeText(neighborhood)}|${normalizeText(city)}|${normalizeText(state)}';
  }
  
  /// Validates complete zone data before database operations
  static Future<Map<String, String>> validateAndNormalizeZoneData({
    required String neighborhood,
    required String city,
    required String state,
  }) async {
    // Validate and normalize each field
    final normalizedNeighborhood = validateAndNormalizeNeighborhood(neighborhood);
    final normalizedCity = validateAndNormalizeCity(city);
    final normalizedState = validateAndNormalizeState(state);
    
    // Check if location exists (basic validation for now)
    final isValidLocation = await validateLocationExists(
      neighborhood: normalizedNeighborhood,
      city: normalizedCity,
      state: normalizedState,
    );
    
    if (!isValidLocation) {
      throw ValidationException(
        'Localização não encontrada: $normalizedNeighborhood, $normalizedCity - $normalizedState'
      );
    }
    
    return {
      'neighborhood_name': normalizedNeighborhood,
      'city': normalizedCity,
      'state': normalizedState,
    };
  }
  
  /// Checks if a driver has reached the maximum number of zones
  static bool hasReachedZoneLimit(int currentZoneCount) {
    return currentZoneCount >= maxZonesPerDriver;
  }
  
  /// Gets the remaining zone slots for a driver
  static int getRemainingZoneSlots(int currentZoneCount) {
    return maxZonesPerDriver - currentZoneCount;
  }
}

