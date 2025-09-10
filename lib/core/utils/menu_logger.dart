import 'package:flutter/foundation.dart';

/// Utility class for logging menu navigation and user interactions
class MenuLogger {
  static const String _tag = '[MENU_LOGGER]';

  /// Log menu item tap/click
  static void logMenuItemTap(String menuType, String itemName, {Map<String, dynamic>? additionalData}) {
    if (kDebugMode) {
      final dataStr = additionalData != null ? ' | Data: $additionalData' : '';
      debugPrint('🖱️ $_tag [$menuType] Item tapped: "$itemName"$dataStr');
    }
  }

  /// Log menu section view
  static void logMenuSectionView(String menuType, String sectionName) {
    if (kDebugMode) {
      debugPrint('📂 $_tag [$menuType] Section viewed: "$sectionName"');
    }
  }

  /// Log menu load/start
  static void logMenuLoad(String menuType) {
    if (kDebugMode) {
      debugPrint('🚀 $_tag [$menuType] Menu loaded');
    }
  }

  /// Log menu close/exit
  static void logMenuClose(String menuType) {
    if (kDebugMode) {
      debugPrint('🔚 $_tag [$menuType] Menu closed');
    }
  }

  /// Log user profile view in menu
  static void logUserProfileView(String menuType, String userName, String userEmail) {
    if (kDebugMode) {
      debugPrint('👤 $_tag [$menuType] User profile viewed: $userName ($userEmail)');
    }
  }

  /// Log wallet balance display
  static void logWalletBalanceDisplay(String menuType, double balance) {
    if (kDebugMode) {
      debugPrint('💰 $_tag [$menuType] Wallet balance displayed: R\$ ${balance.toStringAsFixed(2)}');
    }
  }

  /// Log coming soon feature tap
  static void logComingSoonTap(String menuType, String featureName) {
    if (kDebugMode) {
      debugPrint('🔜 $_tag [$menuType] Coming soon feature tapped: "$featureName"');
    }
  }

  /// Log logout attempt
  static void logLogoutAttempt(String menuType) {
    if (kDebugMode) {
      debugPrint('🚪 $_tag [$menuType] Logout attempt initiated');
    }
  }

  /// Log logout confirmation
  static void logLogoutConfirmation(String menuType, bool confirmed) {
    if (kDebugMode) {
      final action = confirmed ? 'confirmed' : 'cancelled';
      debugPrint('✅ $_tag [$menuType] Logout $action');
    }
  }

  /// Log logout success
  static void logLogoutSuccess(String menuType) {
    if (kDebugMode) {
      debugPrint('🎉 $_tag [$menuType] Logout successful');
    }
  }

  /// Log logout error
  static void logLogoutError(String menuType, Object error) {
    if (kDebugMode) {
      debugPrint('❌ $_tag [$menuType] Logout error: $error');
    }
  }

  /// Log help/support access
  static void logHelpAccess(String menuType, String supportType) {
    if (kDebugMode) {
      debugPrint('🆘 $_tag [$menuType] Help/Support accessed: $supportType');
    }
  }

  /// Log profile edit navigation
  static void logProfileEditNavigation(String menuType) {
    if (kDebugMode) {
      debugPrint('📝 $_tag [$menuType] Navigating to profile edit');
    }
  }

  /// Log profile update success
  static void logProfileUpdateSuccess(String menuType) {
    if (kDebugMode) {
      debugPrint('✅ $_tag [$menuType] Profile updated successfully');
    }
  }

  /// Log navigation to specific screen
  static void logScreenNavigation(String menuType, String screenName, {Map<String, dynamic>? navigationData}) {
    if (kDebugMode) {
      final dataStr = navigationData != null ? ' | Data: $navigationData' : '';
      debugPrint('➡️ $_tag [$menuType] Navigating to screen: "$screenName"$dataStr');
    }
  }

  /// Log external app launch
  static void logExternalAppLaunch(String menuType, String appName, String action) {
    if (kDebugMode) {
      debugPrint('📱 $_tag [$menuType] Launching external app: $appName | Action: $action');
    }
  }

  /// Log navigation error
  static void logNavigationError(String menuType, String screenName, Object error) {
    if (kDebugMode) {
      debugPrint('❌ $_tag [$menuType] Navigation error to "$screenName": $error');
    }
  }

  /// Log custom menu action
  static void logCustomAction(String menuType, String actionName, {Map<String, dynamic>? actionData}) {
    if (kDebugMode) {
      final dataStr = actionData != null ? ' | Data: $actionData' : '';
      debugPrint('🔧 $_tag [$menuType] Custom action: "$actionName"$dataStr');
    }
  }
}