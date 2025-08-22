/// Utilitários para normalização de dados
/// Garante consistência na formatação de strings de localização
class DataNormalizationUtils {
  
  /// Normaliza nomes de localização (bairros, cidades, estados)
  /// Remove acentos, padroniza capitalização e espaçamento
  static String normalizeLocationName(String input) {
    if (input.trim().isEmpty) return '';
    
    return input
        .trim()
        // Remove espaços extras
        .replaceAll(RegExp(r'\s+'), ' ')
        // Remove pontuação desnecessária
        .replaceAll(RegExp(r'[.,;:!?]'), '')
        // Converte para lowercase para processamento
        .toLowerCase()
        // Remove acentos
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[ý]'), 'y')
        // Capitaliza cada palavra
        .split(' ')
        .map((word) => _capitalizeWord(word))
        .join(' ');
  }
  
  /// Normaliza especificamente nomes de bairros
  /// Aplica regras específicas para bairros brasileiros
  static String normalizeNeighborhoodName(String input) {
    String normalized = normalizeLocationName(input);
    
    // Regras específicas para bairros
    normalized = normalized
        // Padroniza abreviações comuns
        .replaceAll(RegExp(r'\bJd\b'), 'Jardim')
        .replaceAll(RegExp(r'\bVl\b'), 'Vila')
        .replaceAll(RegExp(r'\bCj\b'), 'Conjunto')
        .replaceAll(RegExp(r'\bRes\b'), 'Residencial')
        .replaceAll(RegExp(r'\bCh\b'), 'Chácara')
        .replaceAll(RegExp(r'\bChacara\b'), 'Chácara')
        .replaceAll(RegExp(r'\bSt\b'), 'Setor')
        .replaceAll(RegExp(r'\bSetor\s+([A-Z])'), 'Setor \1')
        .replaceAll(RegExp(r'\bQd\b'), 'Quadra')
        .replaceAll(RegExp(r'\bQt\b'), 'Quadra')
        .replaceAll(RegExp(r'\bLt\b'), 'Lote')
        .replaceAll(RegExp(r'\bCentro\s+([A-Z])'), 'Centro \1')
        // Remove números de lote/quadra no final se existirem
        .replaceAll(RegExp(r'\s+\d+\s*$'), '')
        .trim();
    
    return normalized;
  }
  
  /// Normaliza nomes de cidades
  /// Aplica regras específicas para cidades brasileiras
  static String normalizeCityName(String input) {
    String normalized = normalizeLocationName(input);
    
    // Regras específicas para cidades
    normalized = normalized
        // Padroniza abreviações de santos
        .replaceAll(RegExp(r'\bSto\b'), 'Santo')
        .replaceAll(RegExp(r'\bSta\b'), 'Santa')
        .replaceAll(RegExp(r'\bS\.\s*([A-Z])'), 'São \1')
        .replaceAll(RegExp(r'\bSao\b'), 'São')
        // Padroniza outras abreviações
        .replaceAll(RegExp(r'\bN\.\s*Sra\.'), 'Nossa Senhora')
        .replaceAll(RegExp(r'\bNossa\s+Sra\.'), 'Nossa Senhora')
        .replaceAll(RegExp(r'\bEsp\.\s*Santo'), 'Espírito Santo')
        .replaceAll(RegExp(r'\bRio\s+([A-Z])'), 'Rio \1')
        .trim();
    
    return normalized;
  }
  
  /// Normaliza nomes de estados
  /// Converte abreviações para nomes completos quando possível
  static String normalizeStateName(String input) {
    String normalized = normalizeLocationName(input);
    
    // Mapa de abreviações para nomes completos
    const stateAbbreviations = {
      'ac': 'Acre',
      'al': 'Alagoas',
      'ap': 'Amapá',
      'am': 'Amazonas',
      'ba': 'Bahia',
      'ce': 'Ceará',
      'df': 'Distrito Federal',
      'es': 'Espírito Santo',
      'go': 'Goiás',
      'ma': 'Maranhão',
      'mt': 'Mato Grosso',
      'ms': 'Mato Grosso do Sul',
      'mg': 'Minas Gerais',
      'pa': 'Pará',
      'pb': 'Paraíba',
      'pr': 'Paraná',
      'pe': 'Pernambuco',
      'pi': 'Piauí',
      'rj': 'Rio de Janeiro',
      'rn': 'Rio Grande do Norte',
      'rs': 'Rio Grande do Sul',
      'ro': 'Rondônia',
      'rr': 'Roraima',
      'sc': 'Santa Catarina',
      'sp': 'São Paulo',
      'se': 'Sergipe',
      'to': 'Tocantins',
    };
    
    // Verifica se é uma abreviação conhecida
    final lowerInput = input.toLowerCase().trim();
    if (stateAbbreviations.containsKey(lowerInput)) {
      return stateAbbreviations[lowerInput]!;
    }
    
    return normalized;
  }
  
  /// Normaliza texto genérico removendo caracteres especiais
  static String normalizeText(String input) {
    if (input.trim().isEmpty) return '';
    
    return input
        .trim()
        .replaceAll(RegExp(r'[^a-zA-ZÀ-ÿ0-9\s\-\.]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        // Remove pontuação desnecessária
        .replaceAll(RegExp(r'[.,;:!?]'), '')
        // Converte para lowercase para processamento
        .toLowerCase()
        // Remove acentos
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[ý]'), 'y')
        // Capitaliza cada palavra
        .split(' ')
        .map((word) => _capitalizeWord(word))
        .join(' ')
        .trim();
  }
  
  /// Normaliza razão/motivo da exclusão
  static String normalizeReason(String input) {
    if (input.trim().isEmpty) return '';
    
    return input
        .trim()
        // Remove caracteres especiais perigosos
        .replaceAll(RegExp('[<>"\'/\\]'), '')
        // Limita o tamanho
        .substring(0, input.length > 200 ? 200 : input.length)
        .trim();
  }
  
  /// Valida se uma string contém apenas caracteres válidos para localização
  static bool isValidLocationString(String input) {
    if (input.trim().isEmpty) return false;
    if (input.trim().length < 2) return false;
    if (input.length > 100) return false;
    
    // Permite apenas letras, espaços, hífens e pontos
    return RegExp(r'^[a-zA-ZÀ-ÿ\s\-\.]+$').hasMatch(input.trim());
  }
  
  /// Valida se uma string é um motivo válido
  static bool isValidReason(String input) {
    if (input.trim().isEmpty) return true; // Motivo é opcional
    if (input.length > 200) return false;
    
    // Não permite caracteres perigosos
    return !RegExp('[<>"\'/\\\\]').hasMatch(input);
  }
  
  /// Capitaliza uma palavra seguindo regras brasileiras
  static String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    
    // Palavras que devem permanecer em minúsculo (preposições, artigos)
    const lowercaseWords = {
      'da', 'de', 'do', 'das', 'dos', 'e', 'em', 'na', 'no', 'nas', 'nos',
      'a', 'o', 'as', 'os', 'para', 'por', 'com', 'sem', 'sob', 'sobre'
    };
    
    if (lowercaseWords.contains(word.toLowerCase())) {
      return word.toLowerCase();
    }
    
    // Capitaliza a primeira letra
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }
  
  /// Normaliza um endereço completo
  static Map<String, String> normalizeAddress({
    required String neighborhood,
    required String city,
    required String state,
    String? reason,
  }) {
    return {
      'neighborhood_name': normalizeNeighborhoodName(neighborhood),
      'city': normalizeCityName(city),
      'state': normalizeStateName(state),
      'reason': reason != null ? normalizeReason(reason) : '',
    };
  }
  
  /// Valida um endereço completo
  static ValidationResult validateAddress({
    required String neighborhood,
    required String city,
    required String state,
    String? reason,
  }) {
    final errors = <String>[];
    
    if (!isValidLocationString(neighborhood)) {
      errors.add('Nome do bairro inválido');
    }
    
    if (!isValidLocationString(city)) {
      errors.add('Nome da cidade inválido');
    }
    
    if (!isValidLocationString(state)) {
      errors.add('Nome do estado inválido');
    }
    
    if (reason != null && !isValidReason(reason)) {
      errors.add('Motivo contém caracteres inválidos');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

/// Resultado da validação de dados
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  const ValidationResult({
    required this.isValid,
    required this.errors,
  });
  
  bool get hasErrors => errors.isNotEmpty;
  
  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, errors: $errors)';
  }
}