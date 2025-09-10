import 'package:flutter/services.dart';

/// Utilitário para formatação de valores monetários
class MoneyFormatter {
  /// Formata um valor double para string monetária (ex: R\$ 1.234,56)
  static String formatCurrency(double value) => 'R\$ ${formatNumber(value)}';

  /// Formata um valor double para string numérica (ex: 1.234,56)
  static String formatNumber(double value) {
    // Converte para string com 2 casas decimais
    final valueStr = value.toStringAsFixed(2);
    
    // Separa parte inteira e decimal
    final parts = valueStr.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    // Adiciona separadores de milhares
    var formattedInteger = '';
    for (var i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += '.';
      }
      formattedInteger += integerPart[i];
    }
    
    return '$formattedInteger,$decimalPart';
  }

  /// Converte string formatada para double
  /// Aceita formatos como: "1.234,56", "1234,56", "1234.56"
  static double? parseToDouble(String value) {
    if (value.isEmpty) return null;
    
    // Remove espaços e símbolos de moeda
    var cleanValue = value
        .replaceAll(r'R$', '')
        .replaceAll(' ', '')
        .trim();
    
    // Se contém vírgula, assume formato brasileiro
    if (cleanValue.contains(',')) {
      // Remove pontos (separadores de milhares) e substitui vírgula por ponto
      cleanValue = cleanValue.replaceAll('.', '').replaceAll(',', '.');
    }
    
    return double.tryParse(cleanValue);
  }

  /// Valida se o valor está dentro dos limites permitidos
  static bool isValidAmount(double? amount, {double min = 0.01, double max = 50000.0}) {
    if (amount == null) return false;
    return amount >= min && amount <= max;
  }

  /// Retorna mensagem de erro para valores inválidos
  static String getAmountErrorMessage(double? amount, {double min = 0.01, double max = 50000.0}) {
    if (amount == null) {
      return 'Por favor, insira um valor válido';
    }
    if (amount < min) {
      return 'Valor mínimo: ${formatCurrency(min)}';
    }
    if (amount > max) {
      return 'Valor máximo: ${formatCurrency(max)}';
    }
    return 'Valor inválido';
  }
}

/// TextInputFormatter para campos de valor monetário
class MoneyInputFormatter extends TextInputFormatter {
  
  MoneyInputFormatter({
    this.maxDigits = 10,
    this.allowNegative = false,
  });
  final int maxDigits;
  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove tudo que não é dígito
    var digitsOnly = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    
    // Limita o número de dígitos
    if (digitsOnly.length > maxDigits) {
      digitsOnly = digitsOnly.substring(0, maxDigits);
    }
    
    // Se vazio, retorna vazio
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    // Converte para centavos e formata
    final value = double.parse(digitsOnly) / 100;
    final formatted = MoneyFormatter.formatNumber(value);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// TextInputFormatter mais simples para valores decimais
class DecimalInputFormatter extends TextInputFormatter {
  
  DecimalInputFormatter({
    this.decimalPlaces = 2,
    this.allowNegative = false,
  });
  final int decimalPlaces;
  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Permite apenas dígitos, vírgula e ponto
    var filtered = newValue.text.replaceAll(RegExp('[^0-9,.]'), '');
    
    // Substitui vírgula por ponto para padronização interna
    filtered = filtered.replaceAll(',', '.');
    
    // Permite apenas um ponto decimal
    var parts = filtered.split('.');
    if (parts.length > 2) {
      filtered = '${parts[0]}.${parts.sublist(1).join()}';
    }
    
    // Limita casas decimais
    parts = filtered.split('.');
    if (parts.length == 2 && parts[1].length > decimalPlaces) {
      parts[1] = parts[1].substring(0, decimalPlaces);
      filtered = parts.join('.');
    }
    
    // Substitui ponto por vírgula para exibição (padrão brasileiro)
    final display = filtered.replaceAll('.', ',');
    
    return TextEditingValue(
      text: display,
      selection: TextSelection.collapsed(offset: display.length),
    );
  }
}