# Menu Logging System

This directory contains the comprehensive logging system for menu navigation and user interactions in the Option app.

## Overview

The menu logging system provides detailed tracking of user interactions with both driver and passenger menus. All logs are only active in debug mode to prevent sensitive data from being logged in production.

## Features

### 1. MenuLogger Utility Class

The `MenuLogger` class provides structured logging for all menu-related activities:

- **Menu Load/Close Events**: Track when menus are opened and closed
- **Item Taps**: Log when users tap on menu items
- **Section Views**: Track when menu sections are viewed
- **User Profile Actions**: Log profile-related activities
- **Wallet Interactions**: Track wallet balance displays
- **Logout Flow**: Complete logging of the logout process
- **Help/Support Access**: Track when users access help features
- **Navigation Events**: Log all screen navigations
- **External App Launches**: Track when external apps are opened
- **Error Tracking**: Log navigation and operation errors
- **Custom Actions**: Support for logging custom menu actions

### 2. Detailed Logging Categories

#### Menu Lifecycle
- Menu load events
- Menu close events
- Section view tracking

#### User Interactions
- Menu item taps
- Profile view events
- Wallet balance displays
- Coming soon feature taps

#### Navigation
- Screen navigation events
- Profile edit navigation
- External app launches (WhatsApp, Maps, etc.)

#### Authentication
- Logout attempts
- Logout confirmations
- Logout success/failure

#### Support
- Help feature access
- Support channel usage

#### Errors
- Navigation errors
- Operation failures
- Exception logging

## Implementation

### Driver Menu Logging
Located in: `lib/screens/menu/driver_menu_screen.dart`

All driver menu interactions are logged using the `MenuLogger` utility:

```dart
// Log menu load
MenuLogger.logMenuLoad('DRIVER');

// Log screen navigation
MenuLogger.logScreenNavigation('DRIVER', 'Perfil');

// Log logout attempt
MenuLogger.logLogoutAttempt('DRIVER');
```

### User Menu Logging
Located in: `lib/screens/menu/user_menu_screen.dart`

All user menu interactions are logged using the `MenuLogger` utility:

```dart
// Log coming soon feature tap
MenuLogger.logComingSoonTap('USER', 'Promoções');

// Log help access
MenuLogger.logHelpAccess('USER', 'WhatsApp Support');
```

## Log Format

All logs follow a consistent format for easy parsing and analysis:

```
[EMOJI] [MENU_LOGGER] [MENU_TYPE] Message | Additional Data
```

### Log Examples

```
🚀 [MENU_LOGGER] [DRIVER] Menu loaded
🖱️ [MENU_LOGGER] [USER] Item tapped: "Carteira"
📂 [MENU_LOGGER] [DRIVER] Section viewed: "Trabalho"
👤 [MENU_LOGGER] [USER] User profile viewed: John Doe (john@example.com)
💰 [MENU_LOGGER] [DRIVER] Wallet balance displayed: R$ 150.75
🔜 [MENU_LOGGER] [USER] Coming soon feature tapped: "Relatórios"
🚪 [MENU_LOGGER] [DRIVER] Logout attempt initiated
✅ [MENU_LOGGER] [USER] Logout confirmed
🎉 [MENU_LOGGER] [DRIVER] Logout successful
❌ [MENU_LOGGER] [USER] Logout error: NetworkException
🆘 [MENU_LOGGER] [DRIVER] Help/Support accessed: WhatsApp Support
📝 [MENU_LOGGER] [USER] Navigating to profile edit
✅ [MENU_LOGGER] [DRIVER] Profile updated successfully
➡️ [MENU_LOGGER] [USER] Navigating to screen: "Histórico de viagens"
📱 [MENU_LOGGER] [DRIVER] Launching external app: WhatsApp | Action: Open support chat
❌ [MENU_LOGGER] [USER] Navigation error to "Carteira": Screen not found
🔧 [MENU_LOGGER] [DRIVER] Custom action: "Toggle Online Status"
```

## Emoji Legend

- 🚀 - Menu Load
- 🖱️ - Item Tap
- 📂 - Section View
- 👤 - User Profile
- 💰 - Wallet
- 🔜 - Coming Soon
- 🚪 - Logout Start
- ✅ - Confirmation/Success
- 🎉 - Completion
- ❌ - Error
- 🆘 - Help/Support
- 📝 - Profile Edit
- ➡️ - Navigation
- 📱 - External App
- 🔧 - Custom Action

## Testing

Unit tests are available in: `tests/all_tests/unit/utils/menu_logger_test.dart`

The tests verify that:
- All logging methods execute without throwing exceptions
- Different menu types (DRIVER/USER) are properly handled
- Additional data parameters are correctly processed
- Error logging handles various exception types

## Best Practices

1. **Use Consistent Menu Types**: Always use 'DRIVER' or 'USER' consistently
2. **Include Relevant Data**: Add additionalData/navigatioData when relevant for debugging
3. **Log at Key Points**: Log at the beginning and end of important user flows
4. **Error Logging**: Always log errors with sufficient context for debugging
5. **Privacy Considerations**: Avoid logging sensitive user data (handled automatically by debug mode)

## Debug Mode Only

All logging is automatically disabled in release mode to:
- Prevent sensitive data leakage
- Improve app performance
- Reduce battery consumption
- Minimize data usage

To enable logging in release builds for testing:
```dart
// In your test setup
MenuLogger.enableDebugMode(); // Not implemented yet, but could be added
```

## Future Enhancements

1. **Analytics Integration**: Connect logs to analytics services
2. **Remote Logging**: Send logs to remote monitoring services in debug mode
3. **Log Filtering**: Add ability to filter logs by type or severity
4. **Performance Metrics**: Add timing information for navigation events
5. **User Journey Tracking**: Track complete user journeys through the app