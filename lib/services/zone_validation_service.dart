import 'dart:async';
import '../exceptions/app_exceptions.dart';
import 'logging/zone_exclusion_logger.dart';

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
      return normalized.toUpperCase();
    }
    
    // Check if it's a state name variation
    if (stateVariations.containsKey(normalized)) {
      return stateVariations[normalized]!.toUpperCase();
    }
    
    // Additional validation for common invalid patterns
    if (normalized.length > 50) {
      throw const ValidationException('Nome do estado muito longo');
    }
    
    if (RegExp('[0-9]').hasMatch(normalized)) {
      throw const ValidationException('Estado não pode conter números');
    }
    
    throw ValidationException('Estado inválido: $state. Use códigos como SP, RJ, MG ou nomes completos.');
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
    
    // Additional validations
    if (normalized.length > 100) {
      throw const ValidationException('Nome do bairro muito longo (máximo 100 caracteres)');
    }
    
    if (normalized.length < 2) {
      throw const ValidationException('Nome do bairro muito curto (mínimo 2 caracteres)');
    }
    
    // Check for suspicious patterns
    if (RegExp(r'^[0-9]+$').hasMatch(normalized)) {
      throw const ValidationException('Nome do bairro não pode ser apenas números');
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
    
    // Additional validations
    if (normalized.length > 100) {
      throw const ValidationException('Nome da cidade muito longo (máximo 100 caracteres)');
    }
    
    if (normalized.length < 2) {
      throw const ValidationException('Nome da cidade muito curto (mínimo 2 caracteres)');
    }
    
    // Check for suspicious patterns
    if (RegExp(r'^[0-9]+$').hasMatch(normalized)) {
      throw const ValidationException('Nome da cidade não pode ser apenas números');
    }
    
    return normalized;
  }
  
  /// Validates that the location combination is valid
  /// If data comes from Google Places API, it's considered valid
  static Future<bool> validateLocationExists({
    required String neighborhood,
    required String city,
    required String state,
    bool fromGooglePlaces = false,
  }) async {
    try {
      ZoneExclusionLogger.logValidationStart(
        driverId: 'unknown',
        field: 'location_combination',
        context: {
          'validation_type': 'location_exists',
          'location': '$neighborhood, $city - $state',
          'from_google_places': fromGooglePlaces,
        },
      );

      // If data comes from Google Places API, it's already validated
      if (fromGooglePlaces) {
        ZoneExclusionLogger.logValidationSuccess(
          driverId: 'unknown',
          field: 'location_combination',
          context: {
            'validation_type': 'location_exists',
            'is_valid': true,
            'source': 'google_places_api',
            'location': '$neighborhood, $city - $state',
          },
        );
        return true;
      }

      // Basic validation for manual input
      try {
        final normalizedNeighborhood = validateAndNormalizeNeighborhood(neighborhood);
        final normalizedCity = validateAndNormalizeCity(city);
        final normalizedState = validateAndNormalizeState(state);
        
        final isValid = normalizedNeighborhood.isNotEmpty && 
                        normalizedCity.isNotEmpty && 
                        validBrazilianStates.contains(normalizedState.toLowerCase());

        ZoneExclusionLogger.logValidationSuccess(
          driverId: 'unknown',
          field: 'location_combination',
          context: {
            'validation_type': 'location_exists',
            'is_valid': isValid,
            'source': 'manual_validation',
            'original': '$neighborhood, $city - $state',
            'normalized': '$normalizedNeighborhood, $normalizedCity - $normalizedState',
          },
        );
        
        return isValid;
      } catch (e) {
        // If normalization fails, but we have basic data, accept it
        if (neighborhood.trim().isNotEmpty && 
            city.trim().isNotEmpty && 
            state.trim().length >= 2) {
          ZoneExclusionLogger.logValidationSuccess(
            driverId: 'unknown',
            field: 'location_combination',
            context: {
              'validation_type': 'location_exists',
              'is_valid': true,
              'source': 'fallback_validation',
              'location': '$neighborhood, $city - $state',
              'note': 'Accepted despite normalization error: ${e.toString()}',
            },
          );
          return true;
        }
        throw e;
      }
    } catch (e) {
      ZoneExclusionLogger.logValidationError(
        driverId: 'unknown',
        field: 'location_combination',
        error: 'Erro ao validar localização: ${e.toString()}',
        context: {
          'neighborhood': neighborhood,
          'city': city,
          'state': state,
          'error_type': e.runtimeType.toString(),
        },
      );
      return false;
    }
  }
  
  /// Creates a normalized zone identifier for comparison
  static String createZoneIdentifier({
    required String neighborhood,
    required String city,
    required String state,
  }) {
    final identifier = '${normalizeText(neighborhood)}|${normalizeText(city)}|${normalizeText(state)}';
    
    ZoneExclusionLogger.logValidationSuccess(
      driverId: 'unknown',
      field: 'zone_identifier',
      context: {
        'validation_type': 'zone_identifier_creation',
        'original': '$neighborhood, $city - $state',
        'identifier': identifier,
      },
    );
    
    return identifier;
  }
  
  /// Validates complete zone data before database operations
  static Future<Map<String, String>> validateAndNormalizeZoneData({
    required String neighborhood,
    required String city,
    required String state,
    bool fromGooglePlaces = false,
  }) async {
    // If from Google Places, use original data without strict normalization
    if (fromGooglePlaces) {
      final isValidLocation = await validateLocationExists(
        neighborhood: neighborhood,
        city: city,
        state: state,
        fromGooglePlaces: true,
      );
      
      if (!isValidLocation) {
        throw ValidationException(
          'Erro inesperado: Dados do Google Places rejeitados',
        );
      }
      
      return {
        'neighborhood_name': neighborhood,
        'city': city,
        'state': state,
      };
    }
    
    // For manual input, validate and normalize each field
    final normalizedNeighborhood = validateAndNormalizeNeighborhood(neighborhood);
    final normalizedCity = validateAndNormalizeCity(city);
    final normalizedState = validateAndNormalizeState(state);
    
    // Check if location exists
    final isValidLocation = await validateLocationExists(
      neighborhood: normalizedNeighborhood,
      city: normalizedCity,
      state: normalizedState,
      fromGooglePlaces: false,
    );
    
    if (!isValidLocation) {
      throw ValidationException(
        'Localização não encontrada: $normalizedNeighborhood, $normalizedCity - $normalizedState',
      );
    }
    
    return {
      'neighborhood_name': normalizedNeighborhood,
      'city': normalizedCity,
      'state': normalizedState,
    };
  }
  
  /// Checks if a driver has reached the maximum number of zones
  static bool hasReachedZoneLimit(int currentZoneCount) => currentZoneCount >= maxZonesPerDriver;
  
  /// Gets the remaining zone slots for a driver
  static int getRemainingZoneSlots(int currentZoneCount) => maxZonesPerDriver - currentZoneCount;
}

