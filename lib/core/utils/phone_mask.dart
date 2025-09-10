import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    var formatted = '';
    var selectionIndex = newValue.selection.end;
    
    if (text.length <= 2) {
      formatted = text;
      selectionIndex = text.length;
    } else if (text.length <= 6) {
      // (11) 1
      formatted = '(${text.substring(0, 2)}) ${text.substring(2)}';
      selectionIndex = formatted.length;
    } else if (text.length <= 10) {
      // (11) 1234-5
      formatted = '(${text.substring(0, 2)}) ${text.substring(2, 6)}-${text.substring(6)}';
      selectionIndex = formatted.length;
    } else {
      // (11) 9 1234-5678
      if (text.length == 11) {
        formatted = '(${text.substring(0, 2)}) ${text.substring(2, 3)} ${text.substring(3, 7)}-${text.substring(7)}';
      } else {
        formatted = '(${text.substring(0, 2)}) ${text.substring(2, 6)}-${text.substring(6, 10)}';
      }
      selectionIndex = formatted.length;
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}