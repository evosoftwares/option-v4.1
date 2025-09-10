// Teste para verificar se o número do WhatsApp é válido
// Execute: dart teste_whatsapp.dart

import 'dart:io';

void main() async {
  print('=== TESTE DE VALIDAÇÃO DO WHATSAPP ===\n');
  
  const phoneNumber = '556599776524';
  const message = 'Olá! Preciso de ajuda com o app Option - Teste de conectividade.';
  final encodedMessage = Uri.encodeComponent(message);
  final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
  
  print('📞 Número configurado: $phoneNumber');
  print('🌐 URL gerada: $whatsappUrl');
  print('');
  
  // Análise do número
  print('=== ANÁLISE DO NÚMERO ===');
  print('📍 Código do país: ${phoneNumber.substring(0, 2)} (Brasil: 55)');
  print('📍 DDD: ${phoneNumber.substring(2, 4)} (65 = Mato Grosso)');
  print('📍 Número: ${phoneNumber.substring(4)}');
  print('');
  
  // Verificação do formato
  if (phoneNumber.length == 12) {
    print('✅ Formato correto: 12 dígitos (55 + DDD + 8/9 dígitos)');
  } else {
    print('❌ Formato incorreto: ${phoneNumber.length} dígitos (esperado: 12)');
  }
  
  if (phoneNumber.substring(4, 5) == '9') {
    print('✅ Celular: Número inicia com 9');
  } else {
    print('⚠️  Telefone fixo ou formato antigo');
  }
  
  print('');
  print('=== TESTE DE CONECTIVIDADE ===');
  
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    
    final request = await client.getUrl(Uri.parse('https://wa.me/$phoneNumber'));
    final response = await request.close();
    
    print('🌐 Status da requisição: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ URL do WhatsApp está acessível');
    } else if (response.statusCode == 302 || response.statusCode == 301) {
      print('✅ URL redireciona corretamente (normal para WhatsApp)');
    } else {
      print('⚠️  Resposta inesperada: ${response.statusCode}');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Erro ao testar conectividade: $e');
  }
  
  print('');
  print('=== RECOMENDAÇÕES ===');
  print('1. Teste manual: Abra $whatsappUrl no navegador');
  print('2. Verifique se o número existe no WhatsApp');
  print('3. Confirme se o número está correto com o proprietário');
  print('4. Considere usar um número de suporte dedicado');
}