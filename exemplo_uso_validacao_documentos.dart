/// EXEMPLO DE USO DA VALIDAÇÃO DE DOCUMENTOS PARA STATUS ONLINE
/// Este arquivo demonstra como usar a nova funcionalidade de validação
/// de documentos aprovados antes do motorista poder ficar online.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/controllers/driver_status_controller.dart';
import 'lib/services/driver_service.dart';

class DriverHomeScreenExample extends StatefulWidget {
  @override
  _DriverHomeScreenExampleState createState() =>
      _DriverHomeScreenExampleState();
}

class _DriverHomeScreenExampleState extends State<DriverHomeScreenExample> {
  late DriverStatusController _statusController;

  @override
  void initState() {
    super.initState();
    _statusController = context.read<DriverStatusController>();

    // Configurar callback para erros de elegibilidade
    _statusController.onEligibilityError = _handleEligibilityError;
  }

  /// Trata erros quando o motorista não pode ficar online
  void _handleEligibilityError(Map<String, dynamic> eligibilityStatus) {
    final reason = eligibilityStatus['reason'] as String;
    final message = eligibilityStatus['message'] as String;
    final actionRequired = eligibilityStatus['actionRequired'] as String?;

    // Mostrar dialog específico baseado no motivo
    if (reason == 'Documentos não aprovados') {
      _showDocumentsNotApprovedDialog(
          message, actionRequired, eligibilityStatus);
    } else if (reason == 'Motorista não aprovado') {
      _showDriverNotApprovedDialog(message, actionRequired);
    } else if (reason == 'Fora do horário de trabalho') {
      _showOutsideWorkingHoursDialog(message, actionRequired);
    } else {
      _showGenericErrorDialog(message, actionRequired);
    }
  }

  /// Dialog para documentos não aprovados
  void _showDocumentsNotApprovedDialog(String message, String? actionRequired,
      Map<String, dynamic> eligibilityStatus) {
    final documentsStatus =
        eligibilityStatus['documentsStatus'] as Map<String, dynamic>?;
    final pendingDocs =
        documentsStatus?['pendingDocuments'] as List<String>? ?? [];
    final rejectedDocs =
        documentsStatus?['rejectedDocuments'] as List<String>? ?? [];
    final missingDocs =
        documentsStatus?['missingDocuments'] as List<String>? ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Documentos Pendentes'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            if (missingDocs.isNotEmpty) ...[
              const Text('📄 Documentos não enviados:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...missingDocs.map((doc) => Text('• $doc')),
              const SizedBox(height: 8),
            ],
            if (pendingDocs.isNotEmpty) ...[
              const Text('⏳ Documentos em análise:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...pendingDocs.map((doc) => Text('• $doc')),
              const SizedBox(height: 8),
            ],
            if (rejectedDocs.isNotEmpty) ...[
              const Text('❌ Documentos rejeitados:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
              ...rejectedDocs.map((doc) =>
                  Text('• $doc', style: const TextStyle(color: Colors.red))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navegar para tela de documentos
              Navigator.pushNamed(context, '/driver-documents');
            },
            child: const Text('Ir para Documentos'),
          ),
        ],
      ),
    );
  }

  /// Dialog para motorista não aprovado
  void _showDriverNotApprovedDialog(String message, String? actionRequired) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Perfil Não Aprovado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (actionRequired != null) ...[
              const SizedBox(height: 12),
              Text(
                actionRequired,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Abrir chat de suporte ou link para contato
              _openSupportChat();
            },
            child: const Text('Contatar Suporte'),
          ),
        ],
      ),
    );
  }

  /// Dialog para fora do horário de trabalho
  void _showOutsideWorkingHoursDialog(String message, String? actionRequired) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.blue),
            SizedBox(width: 8),
            Text('Fora do Horário'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (actionRequired != null) ...[
              const SizedBox(height: 12),
              Text(actionRequired),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navegar para configuração de horários
              Navigator.pushNamed(context, '/working-hours');
            },
            child: const Text('Configurar Horários'),
          ),
        ],
      ),
    );
  }

  /// Dialog genérico para outros erros
  void _showGenericErrorDialog(String message, String? actionRequired) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Não é Possível Ficar Online'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (actionRequired != null) ...[
              const SizedBox(height: 12),
              Text(
                actionRequired,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openSupportChat() {
    // Implementar abertura do chat de suporte
    print('Abrindo chat de suporte...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Home')),
      body: Consumer<DriverStatusController>(
        builder: (context, controller, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Status: ${controller.status.status}'),
                const SizedBox(height: 20),

                // Switch para ficar online/offline
                Switch(
                  value: controller.isOnline,
                  onChanged: (value) {
                    // A validação será feita automaticamente pelo controller
                    controller.toggleOnlineStatus();
                  },
                ),

                const SizedBox(height: 20),

                // Botão para verificar elegibilidade manualmente
                ElevatedButton(
                  onPressed: () => _checkEligibilityManually(),
                  child: const Text('Verificar Elegibilidade'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Verificação manual de elegibilidade (para debug ou informação)
  Future<void> _checkEligibilityManually() async {
    final driverService = DriverService(Supabase.instance.client);

    // Obter driver ID do usuário atual
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    final driverId = user.id;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Verificando elegibilidade...'),
          ],
        ),
      ),
    );

    try {
      final eligibilityStatus =
          await driverService.getOnlineEligibilityStatus(driverId);
      Navigator.of(context).pop(); // Fechar loading

      final canGoOnline = eligibilityStatus['canGoOnline'] as bool;
      final message = eligibilityStatus['message'] as String;
      final actionRequired = eligibilityStatus['actionRequired'] as String?;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                canGoOnline ? Icons.check_circle : Icons.error,
                color: canGoOnline ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(canGoOnline ? 'Elegível' : 'Não Elegível'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              if (actionRequired != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Ação necessária: $actionRequired',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Fechar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao verificar elegibilidade: $e')),
      );
    }
  }
}

/// RESUMO DA IMPLEMENTAÇÃO:
///
/// 1. VALIDAÇÃO AUTOMÁTICA:
///    - DriverStatusService.canDriverGoOnlineNow() agora verifica:
///      ✅ approval_status == 'approved'
///      ✅ Todos documentos obrigatórios (CNH_FRONT, CNH_BACK, CRLV) aprovados
///      ✅ Está dentro dos horários de trabalho
///
/// 2. FEEDBACK DETALHADO:
///    - DriverService.getOnlineEligibilityStatus() retorna informações detalhadas
///    - Mensagens específicas para cada tipo de problema
///    - Sugestões de ação para o usuário
///
/// 3. INTEGRAÇÃO COM UI:
///    - DriverStatusController tem callback onEligibilityError
///    - Dialogs específicos para cada tipo de erro
///    - Navegação direta para telas de solução (documentos, horários, suporte)
///
/// 4. DOCUMENTOS OBRIGATÓRIOS:
///    - CNH_FRONT (frente da CNH)
///    - CNH_BACK (verso da CNH)
///    - CRLV (documento do veículo)
///
/// 5. ESTADOS POSSÍVEIS:
///    - "Motorista não aprovado" → Aguardar aprovação ou contatar suporte
///    - "Documentos não aprovados" → Enviar/reenviar documentos
///    - "Fora do horário de trabalho" → Configurar horários
///    - "Aprovado" → Pode ficar online
///
/// COMO USAR:
/// 1. Configure o callback no initState() da sua tela
/// 2. O DriverStatusController automaticamente valida antes de ficar online
/// 3. Se não elegível, o callback é chamado com os detalhes do problema
/// 4. Mostre dialogs/mensagens específicas baseadas no tipo de erro
/// 5. Direcione o usuário para a ação correta (documentos, suporte, etc.)
