import 'dart:developer' as dev;
import 'package:url_launcher/url_launcher.dart';

import '../utils/supabase_helper.dart';

class PhoneService {
  
  factory PhoneService() => _instance;
  
  PhoneService._internal();
  static final PhoneService _instance = PhoneService._internal();

  Future<String?> getUserPhone(String userId) async {
    try {
      final client = SupabaseHelper.client;
      if (client == null) {
        throw Exception('Cliente Supabase não disponível');
      }

      final response = await client
          .from('app_users')
          .select('phone')
          .eq('id', userId)
          .single();

      final phone = response['phone'] as String?;
      
      if (phone == null || phone.isEmpty || phone == 'pending') {
        return null;
      }

      dev.log('📞 Telefone obtido para usuário $userId: $phone', name: 'PhoneService');
      return phone;
    } catch (e) {
      dev.log('❌ Erro ao obter telefone: $e', name: 'PhoneService');
      return null;
    }
  }

  Future<bool> makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      dev.log('❌ Número de telefone vazio', name: 'PhoneService');
      return false;
    }

    try {
      // Limpar e formatar o número de telefone
      final cleanNumber = _cleanPhoneNumber(phoneNumber);
      
      if (!_isValidBrazilianPhone(cleanNumber)) {
        dev.log('❌ Número de telefone inválido: $cleanNumber', name: 'PhoneService');
        return false;
      }

      final uri = Uri(scheme: 'tel', path: cleanNumber);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        dev.log('✅ Chamada iniciada para: $cleanNumber', name: 'PhoneService');
        return true;
      } else {
        dev.log('❌ Não foi possível iniciar a chamada', name: 'PhoneService');
        return false;
      }
    } catch (e) {
      dev.log('❌ Erro ao fazer chamada: $e', name: 'PhoneService');
      return false;
    }
  }

  String _cleanPhoneNumber(String phone) {
    // Remove todos os caracteres não numéricos
    var cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Se começar com 55 (código do Brasil), remove
    if (cleaned.startsWith('55') && cleaned.length >= 12) {
      cleaned = cleaned.substring(2);
    }
    
    // Se não tem DDD, assume código padrão (11 - São Paulo)
    if (cleaned.length == 9) {
      cleaned = '11$cleaned';
    }
    
    // Adiciona o código do país
    if (cleaned.length == 11) {
      cleaned = '+55$cleaned';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+55$cleaned';
    }
    
    return cleaned;
  }

  bool _isValidBrazilianPhone(String phone) {
    // Remove o código do país para validação
    final localNumber = phone.replaceFirst('+55', '');
    
    // Deve ter 11 dígitos (DDD + número)
    if (localNumber.length != 11) return false;
    
    // DDD deve estar entre 11 e 99
    final ddd = int.tryParse(localNumber.substring(0, 2)) ?? 0;
    if (ddd < 11 || ddd > 99) return false;
    
    // O primeiro dígito do número deve ser 9 (celular) ou 2-5 (fixo)
    final firstDigit = int.tryParse(localNumber.substring(2, 3)) ?? 0;
    if (firstDigit != 9 && (firstDigit < 2 || firstDigit > 5)) return false;
    
    return true;
  }

  Future<bool> canMakePhoneCalls() async {
    try {
      final uri = Uri(scheme: 'tel');
      return await canLaunchUrl(uri);
    } catch (e) {
      dev.log('❌ Erro ao verificar capacidade de chamada: $e', name: 'PhoneService');
      return false;
    }
  }

  String formatPhoneForDisplay(String phone) {
    final cleaned = _cleanPhoneNumber(phone);
    final localNumber = cleaned.replaceFirst('+55', '');
    
    if (localNumber.length == 11) {
      // Formato: (11) 99999-9999
      return '(${localNumber.substring(0, 2)}) ${localNumber.substring(2, 7)}-${localNumber.substring(7)}';
    }
    
    return phone; // Retorna original se não conseguir formatar
  }
}