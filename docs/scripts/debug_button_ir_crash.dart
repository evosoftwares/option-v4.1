import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../lib/services/driver_service.dart';
import '../../lib/services/driver_document_service.dart';
import '../../lib/services/driver_status_service.dart';
import '../../lib/controllers/driver_status_controller.dart';
import '../../lib/exceptions/app_exceptions.dart';

/// Script de debug para reproduzir e identificar o problema do travamento
/// do botão "IR" na tela principal do motorista
class ButtonIrCrashDebugger {
  static const String debugTag = '🔍 [BUTTON-IR-DEBUG]';
  
  /// Simula o clique no botão "IR" com debug detalhado
  static Future<void> debugButtonIrCrash(String driverId) async {
    print('$debugTag Iniciando debug do travamento do botão IR');
    print('$debugTag Driver ID: $driverId');
    print('$debugTag Timestamp: ${DateTime.now()}');
    print('$debugTag ========================================');
    
    try {
      // Passo 1: Verificar autenticação
      await _checkAuthentication();
      
      // Passo 2: Verificar dados do motorista
      await _checkDriverData(driverId);
      
      // Passo 3: Verificar status do motorista
      await _checkDriverStatus(driverId);
      
      // Passo 4: Verificar documentação (PONTO CRÍTICO)
      await _checkDocumentationWithTimeout(driverId);
      
      // Passo 5: Verificar horários de trabalho
      await _checkWorkingHours(driverId);
      
      // Passo 6: Simular tentativa de ficar online
      await _simulateGoOnlineAttempt(driverId);
      
      print('$debugTag ✅ Debug concluído sem travamento detectado');
      
    } catch (e, stackTrace) {
      print('$debugTag ❌ TRAVAMENTO DETECTADO!');
      print('$debugTag Erro: $e');
      print('$debugTag Tipo: ${e.runtimeType}');
      print('$debugTag Stack trace:');
      print(stackTrace);
      
      // Análise específica do erro
      await _analyzeError(e, stackTrace);
    }
  }
  
  /// Verifica autenticação do usuário
  static Future<void> _checkAuthentication() async {
    print('$debugTag 1️⃣ Verificando autenticação...');
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }
    
    print('$debugTag   ✅ Usuário autenticado: ${user.id}');
    print('$debugTag   📧 Email: ${user.email}');
  }
  
  /// Verifica dados básicos do motorista
  static Future<void> _checkDriverData(String driverId) async {
    print('$debugTag 2️⃣ Verificando dados do motorista...');
    
    try {
      final driverService = DriverService(Supabase.instance.client);
      final driver = await driverService.getDriver(driverId);
      
      if (driver != null) {
        print('$debugTag   ✅ Motorista encontrado: ${driver.id}');
        print('$debugTag   🚗 Veículo: ${driver.brand} ${driver.model}');
        print('$debugTag   🎨 Cor: ${driver.color}');
        print('$debugTag   🔢 Placa: ${driver.plate}');
        print('$debugTag   📋 Categoria: ${driver.category}');
        print('$debugTag   ✅ Status aprovação: ${driver.approvalStatus}');
        print('$debugTag   🌐 Online: ${driver.isOnline}');
      } else {
        throw Exception('Motorista não encontrado');
      }
      
    } catch (e) {
      print('$debugTag   ❌ Erro ao buscar dados do motorista: $e');
      rethrow;
    }
  }
  
  /// Verifica status do motorista na tabela driver_status
  static Future<void> _checkDriverStatus(String driverId) async {
    print('$debugTag 3️⃣ Verificando status do motorista...');
    
    try {
      final statusService = DriverStatusService(Supabase.instance.client);
      final status = await statusService.getDriverStatus(driverId);
      
      if (status != null) {
        print('$debugTag   ✅ Status encontrado');
        print('$debugTag   🔹 Online Intent: ${status.onlineIntent}');
        print('$debugTag   🔹 Updated At: ${status.updatedAt}');
      } else {
        print('$debugTag   ⚠️ Status não encontrado, criando...');
        await statusService.createOrUpdateDriverStatus(
          driverId: driverId,
          onlineIntent: false,
        );
        print('$debugTag   ✅ Status criado');
      }
      
    } catch (e) {
      print('$debugTag   ❌ Erro ao verificar status: $e');
      rethrow;
    }
  }
  
  /// Verifica documentação com timeout para detectar travamentos
  static Future<void> _checkDocumentationWithTimeout(String driverId) async {
    print('$debugTag 4️⃣ Verificando documentação (com timeout)...');
    
    try {
      // Timeout de 10 segundos para detectar travamentos
      final documentationStatus = await Future.any([
        DriverDocumentService.getDocumentationStatus(driverId),
        Future.delayed(
          const Duration(seconds: 10),
          () => throw TimeoutException('Timeout na verificação de documentação', const Duration(seconds: 10)),
        ),
      ]);
      
      print('$debugTag   ✅ Documentação verificada em tempo hábil');
      print('$debugTag   📊 Status completo: ${documentationStatus['isComplete']}');
      print('$debugTag   📋 Total obrigatório: ${documentationStatus['totalRequired']}');
      print('$debugTag   ✅ Total aprovado: ${documentationStatus['totalApproved']}');
      
      final missingDocs = documentationStatus['missingDocuments'] as List;
      final pendingDocs = documentationStatus['pendingDocuments'] as List;
      final rejectedDocs = documentationStatus['rejectedDocuments'] as List;
      final expiredDocs = documentationStatus['expiredDocuments'] as List;
      
      if (missingDocs.isNotEmpty) {
        print('$debugTag   ❌ Documentos não enviados: ${missingDocs.join(', ')}');
      }
      if (pendingDocs.isNotEmpty) {
        print('$debugTag   ⏳ Documentos aguardando: ${pendingDocs.join(', ')}');
      }
      if (rejectedDocs.isNotEmpty) {
        print('$debugTag   🚫 Documentos rejeitados: ${rejectedDocs.join(', ')}');
      }
      if (expiredDocs.isNotEmpty) {
        print('$debugTag   ⏰ Documentos expirados: ${expiredDocs.join(', ')}');
      }
      
    } on TimeoutException catch (e) {
      print('$debugTag   ⏰ TIMEOUT DETECTADO na verificação de documentação!');
      print('$debugTag   🔍 Isso pode indicar um problema de performance ou deadlock');
      print('$debugTag   📊 Timeout após: ${e.duration}');
      rethrow;
    } catch (e) {
      print('$debugTag   ❌ Erro na verificação de documentação: $e');
      rethrow;
    }
  }
  
  /// Verifica horários de trabalho
  static Future<void> _checkWorkingHours(String driverId) async {
    print('$debugTag 5️⃣ Verificando horários de trabalho...');
    
    try {
      final driverService = DriverService(Supabase.instance.client);
      final canGoOnline = await driverService.canDriverGoOnline(driverId);
      
      print('$debugTag   ✅ Verificação de horário concluída');
      print('$debugTag   🕐 Pode ficar online agora: $canGoOnline');
      
    } catch (e) {
      print('$debugTag   ❌ Erro ao verificar horários: $e');
      rethrow;
    }
  }
  
  /// Simula tentativa de ficar online
  static Future<void> _simulateGoOnlineAttempt(String driverId) async {
    print('$debugTag 6️⃣ Simulando tentativa de ficar online...');
    
    try {
      final controller = DriverStatusController();
      await controller.initialize();
      
      print('$debugTag   🔄 Controller inicializado');
      print('$debugTag   📊 Status atual: ${controller.status.isOnline ? "Online" : "Offline"}');
      
      // Simular tentativa de ficar online
      if (!controller.status.isOnline) {
        print('$debugTag   🔄 Tentando ficar online...');
        await controller.toggleOnlineStatus();
        final success = controller.isOnline;
        print('$debugTag   📊 Resultado: ${success ? "Sucesso" : "Falhou"}');
      } else {
        print('$debugTag   ℹ️ Motorista já está online');
      }
      
    } catch (e) {
      print('$debugTag   ❌ Erro na simulação: $e');
      rethrow;
    }
  }
  
  /// Analisa o erro específico que causou o travamento
  static Future<void> _analyzeError(dynamic error, StackTrace stackTrace) async {
    print('$debugTag 🔍 ANÁLISE DO ERRO:');
    print('$debugTag ========================================');
    
    if (error is TimeoutException) {
      print('$debugTag 🕐 TIPO: Timeout');
      print('$debugTag 📊 CAUSA PROVÁVEL: Consulta lenta ao banco de dados');
      print('$debugTag 💡 SOLUÇÃO: Otimizar queries ou adicionar índices');
      
    } else if (error is DocumentationRequiredException) {
      print('$debugTag 📋 TIPO: Documentação incompleta');
      print('$debugTag 📊 CAUSA: ${error.message}');
      print('$debugTag 💡 SOLUÇÃO: Completar documentação obrigatória');
      
    } else if (error.toString().contains('PostgrestException')) {
      print('$debugTag 🗄️ TIPO: Erro de banco de dados');
      print('$debugTag 📊 CAUSA PROVÁVEL: Problema de conectividade ou query');
      print('$debugTag 💡 SOLUÇÃO: Verificar conexão e estrutura do banco');
      
    } else if (error.toString().contains('DocumentException')) {
      print('$debugTag 📄 TIPO: Erro de documento');
      print('$debugTag 📊 CAUSA PROVÁVEL: Problema ao acessar documentos');
      print('$debugTag 💡 SOLUÇÃO: Verificar tabela driver_documents');
      
    } else {
      print('$debugTag ❓ TIPO: Erro desconhecido');
      print('$debugTag 📊 DETALHES: $error');
      print('$debugTag 💡 SOLUÇÃO: Investigação adicional necessária');
    }
    
    // Verificar se o stack trace indica onde o travamento ocorreu
    final stackString = stackTrace.toString();
    if (stackString.contains('getDocumentationStatus')) {
      print('$debugTag 🎯 LOCAL: Verificação de documentação');
    } else if (stackString.contains('updateDriver')) {
      print('$debugTag 🎯 LOCAL: Atualização de dados do motorista');
    } else if (stackString.contains('tryGoOnlineWithValidation')) {
      print('$debugTag 🎯 LOCAL: Validação para ficar online');
    }
    
    print('$debugTag ========================================');
  }
  
  /// Executa diagnóstico completo do sistema
  static Future<void> runFullDiagnostic(String driverId) async {
    print('$debugTag 🏥 INICIANDO DIAGNÓSTICO COMPLETO');
    print('$debugTag ========================================');
    
    // Verificar conectividade com Supabase
    await _checkSupabaseConnectivity();
    
    // Verificar estrutura das tabelas
    await _checkDatabaseStructure();
    
    // Executar debug principal
    await debugButtonIrCrash(driverId);
    
    print('$debugTag 🏥 DIAGNÓSTICO COMPLETO FINALIZADO');
  }
  
  /// Verifica conectividade com Supabase
  static Future<void> _checkSupabaseConnectivity() async {
    print('$debugTag 🌐 Verificando conectividade com Supabase...');
    
    try {
      final response = await Supabase.instance.client
          .from('drivers')
          .select('count')
          .limit(1);
      
      print('$debugTag   ✅ Conectividade OK');
    } catch (e) {
      print('$debugTag   ❌ Problema de conectividade: $e');
      rethrow;
    }
  }
  
  /// Verifica estrutura básica das tabelas
  static Future<void> _checkDatabaseStructure() async {
    print('$debugTag 🗄️ Verificando estrutura do banco...');
    
    final tables = ['drivers', 'driver_status', 'driver_documents', 'driver_working_hours'];
    
    for (final table in tables) {
      try {
        await Supabase.instance.client
            .from(table)
            .select('*')
            .limit(1);
        print('$debugTag   ✅ Tabela $table: OK');
      } catch (e) {
        print('$debugTag   ❌ Tabela $table: Erro - $e');
      }
    }
  }
}

/// Função principal para executar o debug
void main() async {
  // Inicializar Supabase (substitua pelas suas credenciais)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  // ID do motorista que está enfrentando o problema
  const driverId = 'DRIVER_ID_HERE';
  
  // Executar diagnóstico
  await ButtonIrCrashDebugger.runFullDiagnostic(driverId);
}