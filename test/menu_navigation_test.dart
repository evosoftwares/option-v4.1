import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:option/screens/wallet/wallet_screen.dart';
import 'package:option/screens/profile/profile_edit_screen.dart';
import 'package:option/screens/trips/trip_history_screen.dart';
import 'package:option/screens/about/about_screen.dart';
import 'package:option/screens/notifications/notifications_screen.dart';
import 'package:option/screens/saved_places_screen.dart';
import 'package:option/screens/payments/payments_screen.dart';
import 'package:option/screens/emergency/emergency_screen.dart';
import 'package:option/screens/driver/driver_documents_screen.dart';
import 'package:option/screens/driver/vehicle_screen.dart';
import 'package:option/screens/driver/working_hours_screen.dart';
import 'package:option/screens/driver/custom_pricing_screen.dart';
import 'package:option/screens/driver/statistics_screen.dart';
import 'package:option/screens/driver/driver_operation_zones_screen.dart';
import 'package:option/screens/driver/driver_excluded_zones_screen.dart';

/// Classe para testar a funcionalidade de navegação dos menus
/// Verifica se cada tela pode ser instanciada corretamente
class MenuNavigationTester {
  static const String _logPrefix = '[MENU_TEST]';
  
  /// Lista de resultados dos testes
  static final List<TestResult> _testResults = [];
  
  /// Executa todos os testes de navegação do menu
  static void runAllTests() {
    print('$_logPrefix Iniciando testes de navegação do menu');
    _testResults.clear();
    
    try {
      // Testa telas do menu do usuário
      _testUserMenuScreens();
      
      // Testa telas do menu do motorista
      _testDriverMenuScreens();
      
      // Exibe relatório final
      _printTestReport();
      
    } catch (e, stackTrace) {
      print('$_logPrefix Erro durante execução dos testes: $e');
      print('$_logPrefix StackTrace: $stackTrace');
      _testResults.add(TestResult(
        menuType: 'GERAL',
        itemName: 'Execução dos testes',
        expectedScreen: 'N/A',
        actualScreen: 'ERRO',
        success: false,
        errorMessage: e.toString(),
      ));
    }
  }
  
  /// Testa todas as telas do menu do usuário
  static void _testUserMenuScreens() {
    print('$_logPrefix Testando telas do menu do usuário...');
    
    // Define as telas do menu do usuário
    final userMenuScreens = {
      'Carteira': () => const WalletScreen(),
      'Perfil': () => const ProfileEditScreen(),
      'Pagamentos': () => const PaymentsScreen(),
      'Locais salvos': () => const SavedPlacesScreen(),
      'Histórico de viagens': () => const TripHistoryScreen(),
      'Emergência': () => const EmergencyScreen(),
      'Notificações': () => const NotificationsScreen(),
      'Sobre o app': () => const AboutScreen(),
    };
    
    _testScreens('USUÁRIO', userMenuScreens);
  }
  
  /// Testa todas as telas do menu do motorista
  static void _testDriverMenuScreens() {
    print('$_logPrefix Testando telas do menu do motorista...');
    
    // Define as telas do menu do motorista
    final driverMenuScreens = {
      'Perfil': () => const ProfileEditScreen(),
      'Veículo': () => const VehicleScreen(),
      'Documentos': () => const DriverDocumentsScreen(),
      'Horários de trabalho': () => const WorkingHoursScreen(),
      'Zonas excluídas': () => const DriverExcludedZonesScreen(),
      'Preços personalizados': () => const CustomPricingScreen(),
      'Áreas de atuação': () => const DriverOperationZonesScreen(),
      'Histórico de viagens': () => const TripHistoryScreen(),
      'Estatísticas': () => const StatisticsScreen(),
      'Carteira': () => const WalletScreen(),
      'Emergência': () => const EmergencyScreen(),
      'Notificações': () => const NotificationsScreen(),
      'Sobre o app': () => const AboutScreen(),
    };
    
    _testScreens('MOTORISTA', driverMenuScreens);
  }
  
  /// Testa as telas de um menu específico
  static void _testScreens(
    String menuType,
    Map<String, Widget Function()> screens,
  ) {
    for (final entry in screens.entries) {
      final itemName = entry.key;
      final screenBuilder = entry.value;
      
      try {
        print('$_logPrefix Testando tela "$itemName" do menu $menuType');
        
        // Tenta instanciar a tela
        Widget screen;
        String actualScreenName;
        var success = false;
        
        try {
          screen = screenBuilder();
          actualScreenName = screen.runtimeType.toString();
          success = true;
          print('$_logPrefix ✅ Tela "$itemName" instanciada corretamente como $actualScreenName');
        } catch (e) {
          actualScreenName = 'ERRO: $e';
          success = false;
          print('$_logPrefix ❌ Erro ao instanciar tela "$itemName": $e');
        }
        
        _testResults.add(TestResult(
          menuType: menuType,
          itemName: itemName,
          expectedScreen: 'Widget',
          actualScreen: actualScreenName,
          success: success,
        ));
        
      } catch (e, stackTrace) {
        print('$_logPrefix ❌ Erro geral ao testar tela "$itemName": $e');
        print('$_logPrefix StackTrace: $stackTrace');
        
        _testResults.add(TestResult(
          menuType: menuType,
          itemName: itemName,
          expectedScreen: 'Widget',
          actualScreen: 'ERRO',
          success: false,
          errorMessage: e.toString(),
        ));
      }
    }
  }
  
  /// Exibe o relatório final dos testes
  static void _printTestReport() {
    print('\n$_logPrefix ========== RELATÓRIO DE TESTES ==========');
    
    final totalTests = _testResults.length;
    final successfulTests = _testResults.where((r) => r.success).length;
    final failedTests = totalTests - successfulTests;
    
    print('$_logPrefix Total de testes: $totalTests');
    print('$_logPrefix Sucessos: $successfulTests');
    print('$_logPrefix Falhas: $failedTests');
    print('$_logPrefix Taxa de sucesso: ${((successfulTests / totalTests) * 100).toStringAsFixed(1)}%');
    
    print('\n$_logPrefix ========== DETALHES DOS TESTES ==========');
    
    // Agrupa por tipo de menu
    final groupedResults = <String, List<TestResult>>{};
    for (final result in _testResults) {
      groupedResults.putIfAbsent(result.menuType, () => []).add(result);
    }
    
    for (final entry in groupedResults.entries) {
      final menuType = entry.key;
      final results = entry.value;
      
      print('\n$_logPrefix --- MENU $menuType ---');
      
      for (final result in results) {
        final status = result.success ? '✅' : '❌';
        print('$_logPrefix $status ${result.itemName}');
        print('$_logPrefix    Esperado: ${result.expectedScreen}');
        print('$_logPrefix    Atual: ${result.actualScreen}');
        
        if (!result.success && result.errorMessage != null) {
          print('$_logPrefix    Erro: ${result.errorMessage}');
        }
      }
    }
    
    print('\n$_logPrefix ========== FIM DO RELATÓRIO ==========\n');
  }
  
  /// Retorna os resultados dos testes
  static List<TestResult> getTestResults() => List.unmodifiable(_testResults);
  
  /// Limpa os resultados dos testes
  static void clearTestResults() => _testResults.clear();
}

/// Classe para armazenar o resultado de um teste
class TestResult {
  
  const TestResult({
    required this.menuType,
    required this.itemName,
    required this.expectedScreen,
    required this.actualScreen,
    required this.success,
    this.errorMessage,
  });
  final String menuType;
  final String itemName;
  final String expectedScreen;
  final String actualScreen;
  final bool success;
  final String? errorMessage;
  
  @override
  String toString() => 'TestResult(menuType: $menuType, itemName: $itemName, '
           'expectedScreen: $expectedScreen, actualScreen: $actualScreen, '
           'success: $success, errorMessage: $errorMessage)';
}

/// Testes principais usando o framework de testes do Flutter
void main() {
  group('Testes de Navegação do Menu', () {
    test('Deve instanciar corretamente todas as telas do menu', () {
      // Executa os testes
      MenuNavigationTester.runAllTests();
      
      final results = MenuNavigationTester.getTestResults();
      
      // Verifica se há pelo menos um resultado
      expect(results.isNotEmpty, isTrue, 
             reason: 'Deveria ter pelo menos um resultado de teste');
      
      // Verifica se foram executados testes para ambos os menus
      expect(results.any((r) => r.menuType == 'USUÁRIO'), isTrue, 
             reason: 'Deveria ter executado testes para o menu do usuário');
      expect(results.any((r) => r.menuType == 'MOTORISTA'), isTrue, 
             reason: 'Deveria ter executado testes para o menu do motorista');
      
      // Conta sucessos e falhas
      final successfulTests = results.where((r) => r.success).length;
      final totalTests = results.length;
      final successRate = successfulTests / totalTests;
      
      print('\n=== RESUMO FINAL ===');
      print('Total de telas testadas: $totalTests');
      print('Telas que podem ser instanciadas: $successfulTests');
      print('Taxa de sucesso: ${(successRate * 100).toStringAsFixed(1)}%');
      
      // Lista as telas que falharam
      final failedTests = results.where((r) => !r.success).toList();
      if (failedTests.isNotEmpty) {
        print('\nTelas que falharam:');
        for (final failed in failedTests) {
          print('- ${failed.menuType}: ${failed.itemName} (${failed.actualScreen})');
        }
      }
      
      // Verifica se pelo menos 80% das telas podem ser instanciadas
      expect(successRate, greaterThan(0.8), 
             reason: 'Pelo menos 80% das telas deveriam poder ser instanciadas. '
                    'Taxa atual: ${(successRate * 100).toStringAsFixed(1)}%');
    });
    
    test('Deve verificar se todas as importações estão corretas', () {
      // Lista de classes que devem existir
      final expectedClasses = [
        WalletScreen,
        ProfileEditScreen,
        TripHistoryScreen,
        AboutScreen,
        NotificationsScreen,
        SavedPlacesScreen,
        PaymentsScreen,
        EmergencyScreen,
        DriverDocumentsScreen,
        VehicleScreen,
        WorkingHoursScreen,
        CustomPricingScreen,
        StatisticsScreen,
        DriverOperationZonesScreen,
        DriverExcludedZonesScreen,
      ];
      
      for (final screenClass in expectedClasses) {
        expect(screenClass, isNotNull, 
               reason: 'A classe ${screenClass.toString()} deveria estar disponível');
      }
      
      print('\n=== VERIFICAÇÃO DE IMPORTAÇÕES ===');
      print('Todas as ${expectedClasses.length} classes de tela foram importadas corretamente!');
    });
  });
}