import 'package:flutter_test/flutter_test.dart';
import 'package:option/utils/menu_logger.dart';

void main() {
  group('MenuLogger', () {
    setUp(() {
      // Capture print output
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('should log menu load', () {
      // This test verifies that the logger doesn't throw exceptions
      // In release mode, these logs won't actually print, but they shouldn't crash
      expect(() {
        MenuLogger.logMenuLoad('DRIVER');
      }, returnsNormally);
    });

    test('should log menu item tap', () {
      expect(() {
        MenuLogger.logMenuItemTap('DRIVER', 'Perfil');
        MenuLogger.logMenuItemTap('USER', 'Carteira', additionalData: {'balance': 100.50});
      }, returnsNormally);
    });

    test('should log menu section view', () {
      expect(() {
        MenuLogger.logMenuSectionView('DRIVER', 'Trabalho');
        MenuLogger.logMenuSectionView('USER', 'Viagens');
      }, returnsNormally);
    });

    test('should log user profile view', () {
      expect(() {
        MenuLogger.logUserProfileView('DRIVER', 'John Doe', 'john@example.com');
        MenuLogger.logUserProfileView('USER', 'Jane Smith', 'jane@example.com');
      }, returnsNormally);
    });

    test('should log wallet balance display', () {
      expect(() {
        MenuLogger.logWalletBalanceDisplay('DRIVER', 150.75);
        MenuLogger.logWalletBalanceDisplay('USER', 0.0);
      }, returnsNormally);
    });

    test('should log coming soon tap', () {
      expect(() {
        MenuLogger.logComingSoonTap('DRIVER', 'Relatórios');
        MenuLogger.logComingSoonTap('USER', 'Promoções');
      }, returnsNormally);
    });

    test('should log logout actions', () {
      expect(() {
        MenuLogger.logLogoutAttempt('DRIVER');
        MenuLogger.logLogoutConfirmation('DRIVER', true);
        MenuLogger.logLogoutConfirmation('USER', false);
        MenuLogger.logLogoutSuccess('DRIVER');
        MenuLogger.logLogoutError('USER', Exception('Test error'));
      }, returnsNormally);
    });

    test('should log help access', () {
      expect(() {
        MenuLogger.logHelpAccess('DRIVER', 'WhatsApp Support');
        MenuLogger.logHelpAccess('USER', 'Email Support');
      }, returnsNormally);
    });

    test('should log profile navigation', () {
      expect(() {
        MenuLogger.logProfileEditNavigation('DRIVER');
        MenuLogger.logProfileUpdateSuccess('USER');
      }, returnsNormally);
    });

    test('should log screen navigation', () {
      expect(() {
        MenuLogger.logScreenNavigation('DRIVER', 'Veículo');
        MenuLogger.logScreenNavigation('USER', 'Histórico de viagens', 
            navigationData: {'filter': 'last_30_days'});
      }, returnsNormally);
    });

    test('should log external app launch', () {
      expect(() {
        MenuLogger.logExternalAppLaunch('DRIVER', 'WhatsApp', 'Open support chat');
        MenuLogger.logExternalAppLaunch('USER', 'Maps', 'Open directions');
      }, returnsNormally);
    });

    test('should log navigation errors', () {
      expect(() {
        MenuLogger.logNavigationError('DRIVER', 'Veículo', 'Screen not found');
        MenuLogger.logNavigationError('USER', 'Carteira', Exception('Network error'));
      }, returnsNormally);
    });

    test('should log custom actions', () {
      expect(() {
        MenuLogger.logCustomAction('DRIVER', 'Toggle Online Status');
        MenuLogger.logCustomAction('USER', 'Apply Promo Code', 
            actionData: {'code': 'SAVE10', 'discount': 10.0});
      }, returnsNormally);
    });
  });
}