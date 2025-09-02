/// Utilitário para validação de chaves PIX
/// Suporta validação de CPF, CNPJ, email, telefone e chave aleatória
class PixValidator {
  /// Valida se uma chave PIX é válida
  static bool isValidPixKey(String pixKey) {
    if (pixKey.isEmpty) return false;
    
    final cleanKey = pixKey.trim();
    
    return _isValidCpf(cleanKey) ||
           _isValidCnpj(cleanKey) ||
           _isValidEmail(cleanKey) ||
           _isValidPhone(cleanKey) ||
           _isValidRandomKey(cleanKey);
  }
  
  /// Retorna o tipo da chave PIX
  static PixKeyType getPixKeyType(String pixKey) {
    if (pixKey.isEmpty) return PixKeyType.invalid;
    
    final cleanKey = pixKey.trim();
    
    if (_isValidCpf(cleanKey)) return PixKeyType.cpf;
    if (_isValidCnpj(cleanKey)) return PixKeyType.cnpj;
    if (_isValidEmail(cleanKey)) return PixKeyType.email;
    if (_isValidPhone(cleanKey)) return PixKeyType.phone;
    if (_isValidRandomKey(cleanKey)) return PixKeyType.randomKey;
    
    return PixKeyType.invalid;
  }
  
  /// Valida CPF (apenas formato, não verifica dígitos verificadores)
  static bool _isValidCpf(String cpf) {
    final cleanCpf = cpf.replaceAll(RegExp('[^0-9]'), '');
    return RegExp(r'^\d{11}$').hasMatch(cleanCpf) && _isValidCpfDigits(cleanCpf);
  }
  
  /// Valida CNPJ (apenas formato, não verifica dígitos verificadores)
  static bool _isValidCnpj(String cnpj) {
    final cleanCnpj = cnpj.replaceAll(RegExp('[^0-9]'), '');
    return RegExp(r'^\d{14}$').hasMatch(cleanCnpj) && _isValidCnpjDigits(cleanCnpj);
  }
  
  /// Valida email
  static bool _isValidEmail(String email) => RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  
  /// Valida telefone (formato brasileiro)
  static bool _isValidPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp('[^0-9]'), '');
    // Aceita formatos: +5511999999999, 5511999999999, 11999999999
    return RegExp(r'^(\+55)?[1-9]{2}9?[0-9]{8}$').hasMatch(cleanPhone);
  }
  
  /// Valida chave aleatória (UUID v4)
  static bool _isValidRandomKey(String key) => RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', 
                 caseSensitive: false).hasMatch(key);
  
  /// Validação básica de dígitos verificadores do CPF
  static bool _isValidCpfDigits(String cpf) {
    if (cpf.length != 11) return false;
    
    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;
    
    // Calcula primeiro dígito verificador
    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    var firstDigit = 11 - (sum % 11);
    if (firstDigit >= 10) firstDigit = 0;
    
    if (int.parse(cpf[9]) != firstDigit) return false;
    
    // Calcula segundo dígito verificador
    sum = 0;
    for (var i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    var secondDigit = 11 - (sum % 11);
    if (secondDigit >= 10) secondDigit = 0;
    
    return int.parse(cpf[10]) == secondDigit;
  }
  
  /// Validação básica de dígitos verificadores do CNPJ
  static bool _isValidCnpjDigits(String cnpj) {
    if (cnpj.length != 14) return false;
    
    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) return false;
    
    // Calcula primeiro dígito verificador
    var weights1 = <int>[5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(cnpj[i]) * weights1[i];
    }
    var firstDigit = sum % 11;
    firstDigit = firstDigit < 2 ? 0 : 11 - firstDigit;
    
    if (int.parse(cnpj[12]) != firstDigit) return false;
    
    // Calcula segundo dígito verificador
    var weights2 = <int>[6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    sum = 0;
    for (var i = 0; i < 13; i++) {
      sum += int.parse(cnpj[i]) * weights2[i];
    }
    var secondDigit = sum % 11;
    secondDigit = secondDigit < 2 ? 0 : 11 - secondDigit;
    
    return int.parse(cnpj[13]) == secondDigit;
  }
  
  /// Formata a chave PIX para exibição
  static String formatPixKey(String pixKey) {
    final type = getPixKeyType(pixKey);
    
    switch (type) {
      case PixKeyType.cpf:
        final clean = pixKey.replaceAll(RegExp('[^0-9]'), '');
        return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9, 11)}';
      case PixKeyType.cnpj:
        final clean = pixKey.replaceAll(RegExp('[^0-9]'), '');
        return '${clean.substring(0, 2)}.${clean.substring(2, 5)}.${clean.substring(5, 8)}/${clean.substring(8, 12)}-${clean.substring(12, 14)}';
      case PixKeyType.phone:
        final clean = pixKey.replaceAll(RegExp('[^0-9]'), '');
        if (clean.length == 11) {
          return '(${clean.substring(0, 2)}) ${clean.substring(2, 7)}-${clean.substring(7)}';
        } else if (clean.length == 13 && clean.startsWith('55')) {
          return '+55 (${clean.substring(2, 4)}) ${clean.substring(4, 9)}-${clean.substring(9)}';
        }
        return pixKey;
      case PixKeyType.email:
      case PixKeyType.randomKey:
      case PixKeyType.invalid:
        return pixKey;
    }
  }
  
  /// Retorna uma mensagem de erro específica para o tipo de chave
  static String getValidationErrorMessage(String pixKey) {
    if (pixKey.isEmpty) {
      return 'Por favor, informe sua chave PIX';
    }
    
    final cleanKey = pixKey.trim();
    
    // Tenta identificar o tipo baseado no formato
    if (RegExp(r'^[0-9.-]+$').hasMatch(cleanKey)) {
      return 'CPF/CNPJ inválido. Verifique os dígitos informados';
    }
    
    if (cleanKey.contains('@')) {
      return 'Email inválido. Verifique o formato do email';
    }
    
    if (RegExp(r'^[+0-9()-\s]+$').hasMatch(cleanKey)) {
      return 'Telefone inválido. Use o formato (11) 99999-9999';
    }
    
    if (RegExp(r'^[0-9a-f-]+$', caseSensitive: false).hasMatch(cleanKey)) {
      return 'Chave aleatória inválida. Verifique o formato UUID';
    }
    
    return 'Chave PIX inválida. Verifique o formato da chave';
  }
}

/// Enum para tipos de chave PIX
enum PixKeyType {
  cpf('CPF'),
  cnpj('CNPJ'),
  email('Email'),
  phone('Telefone'),
  randomKey('Chave Aleatória'),
  invalid('Inválida');
  
  const PixKeyType(this.displayName);
  final String displayName;
}