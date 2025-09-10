import 'package:flutter/services.dart';

/// Formatador para placas de veículo brasileiras
/// Suporta formato antigo (ABC1234) e Mercosul (ABC1D23)
class PlateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    
    if (text.length > 7) {
      return oldValue;
    }
    
    String formatted = '';
    
    for (int i = 0; i < text.length; i++) {
      if (i == 3) {
        formatted += '-';
      }
      formatted += text[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Utilitários para validação de placa
class PlateValidator {
  /// Valida se a placa está no formato brasileiro correto
  static bool isValidBrazilianPlate(String plate) {
    final cleanPlate = plate.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
    
    if (cleanPlate.length != 7) {
      return false;
    }
    
    // Formato brasileiro: ABC1234 ou ABC1D23 (Mercosul)
    final plateRegex = RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$');
    return plateRegex.hasMatch(cleanPlate);
  }
  
  /// Remove formatação da placa (hífens, espaços)
  static String cleanPlate(String plate) {
    return plate.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
  }
  
  /// Formata a placa para exibição (ABC-1234)
  static String formatPlate(String plate) {
    final clean = cleanPlate(plate);
    if (clean.length >= 4) {
      return '${clean.substring(0, 3)}-${clean.substring(3)}';
    }
    return clean;
  }
  
  /// Retorna mensagem de erro amigável para o usuário
  static String getErrorMessage(String plate) {
    final clean = cleanPlate(plate);
    
    if (clean.isEmpty) {
      return 'Placa é obrigatória';
    }
    
    if (clean.length < 7) {
      return 'Placa deve ter 7 caracteres (ex: ABC-1234)';
    }
    
    if (clean.length > 7) {
      return 'Placa não pode ter mais de 7 caracteres';
    }
    
    if (!isValidBrazilianPlate(plate)) {
      return 'Formato inválido. Use ABC-1234 ou ABC-1D23';
    }
    
    return 'Placa inválida';
  }
}