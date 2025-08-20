class PhoneValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira seu número de telefone';
    }
    
    // Remove todos os caracteres não numéricos
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Validação para números brasileiros
    if (cleaned.length < 10 || cleaned.length > 11) {
      return 'Número de telefone inválido';
    }
    
    // Validação do DDD
    if (cleaned.length == 11) {
      // Celular com 9 dígitos
      final ddd = cleaned.substring(0, 2);
      final number = cleaned.substring(2);
      
      if (int.tryParse(ddd) == null || int.parse(ddd) < 11 || int.parse(ddd) > 99) {
        return 'DDD inválido';
      }
      
      if (!number.startsWith('9')) {
        return 'Número de celular deve começar com 9';
      }
      
      if (number.length != 9) {
        return 'Número de celular deve ter 9 dígitos';
      }
    } else if (cleaned.length == 10) {
      // Telefone fixo
      final ddd = cleaned.substring(0, 2);
      final number = cleaned.substring(2);
      
      if (int.tryParse(ddd) == null || int.parse(ddd) < 11 || int.parse(ddd) > 99) {
        return 'DDD inválido';
      }
      
      if (number.length != 8) {
        return 'Número de telefone deve ter 8 dígitos';
      }
    }
    
    return null;
  }

  static String format(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.length == 11) {
      // Celular: (11) 9 1234-5678
      return '(${cleaned.substring(0, 2)}) ${cleaned.substring(2, 3)} ${cleaned.substring(3, 7)}-${cleaned.substring(7)}';
    } else if (cleaned.length == 10) {
      // Fixo: (11) 1234-5678
      return '(${cleaned.substring(0, 2)}) ${cleaned.substring(2, 6)}-${cleaned.substring(6)}';
    }
    
    return value;
  }

  static String unformat(String value) {
    return value.replaceAll(RegExp(r'[^\d]'), '');
  }
}