import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static const String _phoneNumber = '556592577217';
  
  static Future<void> openSupport({
    required BuildContext context, 
    bool isDriver = false,
  }) async {
    final message = isDriver 
        ? 'Olá! Preciso de ajuda com o app Option - Sou motorista.'
        : 'Olá! Preciso de ajuda com o app Option.';
    
    await _openWhatsApp(context: context, message: message);
  }
  
  static Future<void> _openWhatsApp({
    required BuildContext context,
    required String message,
  }) async {
    try {
      print('🔍 [WhatsApp] Tentando abrir WhatsApp...');
      print('📞 Número: $_phoneNumber');
      print('💬 Mensagem: $message');
      
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$_phoneNumber?text=$encodedMessage';
      
      print('🌐 URL gerada: $whatsappUrl');
      
      final uri = Uri.parse(whatsappUrl);
      
      // Verificar se pode abrir URL
      final canLaunch = await canLaunchUrl(uri);
      print('🔍 [WhatsApp] canLaunchUrl resultado: $canLaunch');
      
      if (canLaunch) {
        print('✅ [WhatsApp] Abrindo WhatsApp...');
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
        print('📱 [WhatsApp] launchUrl resultado: $launched');
        
        if (launched) {
          print('✅ [WhatsApp] WhatsApp aberto com sucesso!');
        } else {
          print('❌ [WhatsApp] Falha ao abrir WhatsApp mesmo com canLaunch = true');
          _showError(context, 'Não foi possível abrir o WhatsApp. Tente novamente.');
        }
      } else {
        print('❌ [WhatsApp] canLaunchUrl retornou false');
        _showError(context, 'WhatsApp não está instalado ou não pode ser aberto.');
      }
    } catch (e, stackTrace) {
      print('❌ [WhatsApp] Erro ao tentar abrir WhatsApp:');
      print('   Erro: $e');
      print('   Stack trace: $stackTrace');
      _showError(context, 'Erro ao abrir WhatsApp: $e');
    }
  }
  
  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Tentar Novamente',
          textColor: Colors.white,
          onPressed: () => openSupport(context: context),
        ),
      ),
    );
  }
  
  // Método para testar conectividade
  static Future<bool> testWhatsAppConnectivity() async {
    try {
      final uri = Uri.parse('https://wa.me/$_phoneNumber');
      return await canLaunchUrl(uri);
    } catch (e) {
      print('❌ [WhatsApp] Erro no teste de conectividade: $e');
      return false;
    }
  }
}