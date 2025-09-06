import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';
import '../services/wallet_service.dart';
import '../services/driver_document_service.dart';
import '../controllers/driver_status_controller.dart';

/// Classe de debug específica para investigar o problema do botão "IR" que não muda
/// USO: Chame ButtonIrDebug.debugButtonIrProblem() quando o botão não funciona
class ButtonIrDebug {
  
  /// Investigação completa do problema do botão IR
  static Future<void> debugButtonIrProblem() async {
    print('🚨 [ButtonIrDebug] ========================================');
    print('🚨 [ButtonIrDebug] INVESTIGAÇÃO: BOTÃO IR NÃO MUDA');
    print('🚨 [ButtonIrDebug] ========================================');

    try {
      // ETAPA 1: VERIFICAR SE O USUÁRIO ESTÁ AUTENTICADO
      print('👤 [ButtonIrDebug] 1. Verificando autenticação...');
      final user = await UserService.getCurrentUser();
      if (user == null) {
        print('❌ [ButtonIrDebug] PROBLEMA CRÍTICO: Usuário não autenticado!');
        print('💡 [ButtonIrDebug] SOLUÇÃO: Faça login primeiro');
        return;
      }
      print('✅ [ButtonIrDebug] Usuário autenticado: ${user.email} (ID: ${user.id})');

      // ETAPA 2: VERIFICAR SE É UM MOTORISTA
      print('🚗 [ButtonIrDebug] 2. Verificando se é motorista...');
      final walletService = WalletService();
      final driverId = await walletService.getDriverIdForUser(user.id);
      if (driverId == null) {
        print('❌ [ButtonIrDebug] PROBLEMA CRÍTICO: Usuário não é motorista!');
        print('💡 [ButtonIrDebug] SOLUÇÃO: Registre-se como motorista primeiro');
        return;
      }
      print('✅ [ButtonIrDebug] Motorista encontrado: $driverId');

      // ETAPA 3: VERIFICAR TABELAS NO BANCO
      print('🗄️ [ButtonIrDebug] 3. Verificando tabelas necessárias...');
      await _checkRequiredTables();

      // ETAPA 4: VERIFICAR STATUS NO DRIVER_STATUS
      print('📊 [ButtonIrDebug] 4. Verificando status do motorista...');
      await _checkDriverStatus(driverId);

      // ETAPA 5: VERIFICAR HORÁRIOS DE TRABALHO
      print('⏰ [ButtonIrDebug] 5. Verificando horários de trabalho...');
      await _checkWorkingHours(driverId);

      // ETAPA 6: VERIFICAR VIEW DRIVER_EFFECTIVE_STATUS
      print('👁️ [ButtonIrDebug] 6. Verificando view de status efetivo...');
      await _checkEffectiveStatusView(driverId);

      // ETAPA 7: SIMULAR CLIQUE NO BOTÃO IR
      print('🔴 [ButtonIrDebug] 7. Simulando clique no botão IR...');
      await _simulateButtonClick(driverId);

      print('🚨 [ButtonIrDebug] ========================================');
      print('🚨 [ButtonIrDebug] INVESTIGAÇÃO CONCLUÍDA');
      print('🚨 [ButtonIrDebug] ========================================');

    } catch (e) {
      print('❌ [ButtonIrDebug] ERRO CRÍTICO na investigação: ${e.toString()}');
      print('❌ [ButtonIrDebug] Tipo: ${e.runtimeType}');
    }
  }

  /// Verifica se as tabelas necessárias existem
  static Future<void> _checkRequiredTables() async {
    final client = Supabase.instance.client;

    // Verificar driver_status
    try {
      await client.from('driver_status').select('count').limit(1);
      print('   ✅ Tabela driver_status: OK');
    } catch (e) {
      print('   ❌ Tabela driver_status: ERRO - $e');
      print('   💡 Execute sql/auto_online_schema.sql');
    }

    // Verificar working_hours
    try {
      await client.from('working_hours').select('count').limit(1);
      print('   ✅ Tabela working_hours: OK');
    } catch (e) {
      print('   ❌ Tabela working_hours: ERRO - $e');
      print('   💡 Execute sql/auto_online_schema.sql');
    }

    // Verificar view driver_effective_status
    try {
      await client.from('driver_effective_status').select('count').limit(1);
      print('   ✅ View driver_effective_status: OK');
    } catch (e) {
      print('   ❌ View driver_effective_status: ERRO - $e');
      print('   💡 Execute sql/auto_online_schema.sql');
    }
  }

  /// Verifica o status do motorista na tabela driver_status
  static Future<void> _checkDriverStatus(String driverId) async {
    final client = Supabase.instance.client;

    try {
      final status = await client
          .from('driver_status')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();

      if (status == null) {
        print('   ⚠️ Motorista não tem registro na driver_status');
        print('   💡 Criando registro inicial...');
        
        await client.from('driver_status').insert({
          'driver_id': driverId,
          'online_intent': false,
        });
        print('   ✅ Registro criado na driver_status');
      } else {
        print('   📊 Status encontrado:');
        print('      🔹 Online Intent: ${status['online_intent']}');
        print('      🔹 Updated At: ${status['updated_at']}');
      }
    } catch (e) {
      print('   ❌ Erro ao verificar driver_status: $e');
    }
  }

  /// Verifica os horários de trabalho do motorista
  static Future<void> _checkWorkingHours(String driverId) async {
    final client = Supabase.instance.client;

    try {
      final hours = await client
          .from('working_hours')
          .select()
          .eq('driver_id', driverId)
          .eq('is_active', true);

      print('   📊 Horários encontrados: ${hours.length}');
      
      if (hours.isEmpty) {
        print('   ⚠️ Motorista não tem horários definidos');
        print('   💡 Sem horários = sempre pode ficar online');
      } else {
        for (final hour in hours) {
          print('      📅 Dia ${hour['day_of_week']}: ${hour['start_time']} - ${hour['end_time']}');
        }
      }

      // Verificar se está no horário agora
      final now = DateTime.now();
      final currentDay = now.weekday % 7;
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
      
      print('   🕐 Agora: Dia $currentDay, $currentTime');
      
      final activeNow = hours.where((h) => 
        h['day_of_week'] == currentDay &&
        h['start_time'] <= currentTime &&
        h['end_time'] > currentTime
      ).toList();
      
      print('   📊 Horários ativos agora: ${activeNow.length}');
      
    } catch (e) {
      print('   ❌ Erro ao verificar horários: $e');
    }
  }

  /// Verifica a view driver_effective_status
  static Future<void> _checkEffectiveStatusView(String driverId) async {
    final client = Supabase.instance.client;

    try {
      final effectiveStatus = await client
          .from('driver_effective_status')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();

      if (effectiveStatus == null) {
        print('   ❌ PROBLEMA: Motorista não aparece na view driver_effective_status');
        print('   💡 CAUSA: Não tem registro em driver_status ou working_hours');
      } else {
        print('   📊 Status efetivo da view:');
        print('      🔹 Driver ID: ${effectiveStatus['driver_id']}');
        print('      🔹 Online Intent: ${effectiveStatus['online_intent']}');
        print('      🔹 Within Working Hours: ${effectiveStatus['is_within_working_hours']}');
        print('      🔹 Effective Online: ${effectiveStatus['effective_online']}');
        
        // ESTA É A CHAVE DO PROBLEMA!
        final withinHours = effectiveStatus['is_within_working_hours'];
        if (withinHours == false) {
          print('   🚨 PROBLEMA ENCONTRADO: is_within_working_hours = false');
          print('   💡 CAUSA: Motorista está fora do horário de trabalho');
          print('   💡 SOLUÇÃO: Crie horários de trabalho ou ajuste os existentes');
        } else {
          print('   ✅ Motorista está dentro do horário de trabalho');
        }
      }
    } catch (e) {
      print('   ❌ Erro ao verificar view: $e');
    }
  }

  /// Verifica especificamente o status da documentação
  static Future<void> _checkDocumentationStatus(String driverId) async {
    print('   📋 Verificando status da documentação...');
    
    try {
      final documentationStatus = await DriverDocumentService.getDocumentationStatus(driverId);
      
      print('   📊 Status da documentação:');
      print('      🔹 Completa: ${documentationStatus['isComplete']}');
      print('      🔹 Total obrigatório: ${documentationStatus['totalRequired']}');
      print('      🔹 Total aprovado: ${documentationStatus['totalApproved']}');
      
      final missingDocs = documentationStatus['missingDocuments'] as List;
      final pendingDocs = documentationStatus['pendingDocuments'] as List;  
      final rejectedDocs = documentationStatus['rejectedDocuments'] as List;
      final expiredDocs = documentationStatus['expiredDocuments'] as List;
      final approvedDocs = documentationStatus['approvedDocuments'] as List;
      
      if (missingDocs.isNotEmpty) {
        print('      ❌ Documentos não enviados: ${missingDocs.join(', ')}');
      }
      if (pendingDocs.isNotEmpty) {
        print('      ⏳ Documentos aguardando aprovação: ${pendingDocs.join(', ')}');
      }
      if (rejectedDocs.isNotEmpty) {
        print('      🚫 Documentos rejeitados: ${rejectedDocs.join(', ')}');
      }
      if (expiredDocs.isNotEmpty) {
        print('      ⏰ Documentos expirados: ${expiredDocs.join(', ')}');
      }
      if (approvedDocs.isNotEmpty) {
        print('      ✅ Documentos aprovados: ${approvedDocs.join(', ')}');
      }
      
      if (!documentationStatus['isComplete']) {
        print('      🚨 PROBLEMA: Documentação incompleta impedindo status online');
      } else {
        print('      ✅ Documentação completa - não é o problema');
      }
      
    } catch (e) {
      print('   ❌ Erro ao verificar documentação: $e');
    }
  }

  /// Simula o clique no botão IR para ver onde falha
  static Future<void> _simulateButtonClick(String driverId) async {
    print('   🔴 Simulando clique no botão IR...');
    
    try {
      // Verificar documentação primeiro
      await _checkDocumentationStatus(driverId);
      
      // Criar controlador temporário
      final controller = DriverStatusController();
      await controller.initialize();
      
      print('   ⚡ Chamando toggleOnlineStatus...');
      await controller.toggleOnlineStatus();
      final result = controller.isOnline;
      
      print('   📊 Resultado: $result');
      
      if (result) {
        print('   ✅ SUCESSO: Motorista conseguiu ficar online');
      } else {
        print('   ❌ FALHA: Motorista não conseguiu ficar online');
        print('   💡 CAUSA: Provavelmente fora do horário de trabalho ou documentos');
      }
      
    } catch (e) {
      print('   ❌ Erro na simulação: $e');
      print('   📋 Tipo do erro: ${e.runtimeType}');
    }
  }

  /// Debug rápido para mostrar no console quando o botão não funciona
  static Future<void> quickDebug() async {
    print('🚨 [QUICK DEBUG] Botão IR não muda - executando diagnóstico...');
    
    try {
      final user = await UserService.getCurrentUser();
      if (user == null) {
        print('❌ Usuário não autenticado');
        return;
      }
      
      final driverId = await WalletService().getDriverIdForUser(user.id);
      if (driverId == null) {
        print('❌ Usuário não é motorista');
        return;
      }
      
      final client = Supabase.instance.client;
      final effectiveStatus = await client
          .from('driver_effective_status')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();
      
      if (effectiveStatus == null) {
        print('❌ Motorista não tem status - execute debugButtonIrProblem() para mais detalhes');
        return;
      }
      
      print('📊 Status: Within Hours = ${effectiveStatus['is_within_working_hours']}');
      
      if (effectiveStatus['is_within_working_hours'] == false) {
        print('🚨 PROBLEMA: Fora do horário de trabalho!');
        print('💡 Configure horários de trabalho no menu do motorista');
      } else {
        print('✅ Dentro do horário - problema pode ser em outro lugar');
      }
      
    } catch (e) {
      print('❌ Erro: $e');
    }
  }
}