# Wallet UI Components

This directory contains enhanced UI components for the wallet system with improved visual feedback.

## Components

### WalletOperationFeedback
Provides visual feedback for wallet operations with different types:
- Success
- Error
- Warning
- Info

### WalletProgressIndicator
Shows a progress indicator for ongoing wallet operations.

### TransactionNotification
Displays subtle notifications for recent transactions at the top of the screen.

### TransactionConfirmation
Shows an animated confirmation when a transaction is completed.

### EnhancedTransactionList
An enhanced transaction list with better visual design and feedback.

### WalletDashboard
A complete wallet dashboard with balance display and recent transactions.

## Features

### Visual Feedback
- Color-coded feedback based on operation type
- Animated transitions
- Clear status indicators
- Loading skeletons for better perceived performance

### Responsive Design
- Adapts to different screen sizes
- Touch-friendly controls
- Accessible color schemes

### Animations
- Smooth transitions between states
- Loading animations
- Confirmation animations

## Usage

### WalletOperationFeedback
```dart
WalletOperationFeedback(
  type: WalletOperationType.success,
  title: 'Success',
  message: 'Operation completed successfully',
  onRetry: () => retryOperation(),
  onClose: () => hideFeedback(),
)
```

### WalletProgressIndicator
```dart
WalletProgressIndicator(
  message: 'Processing payment...',
)
```

### EnhancedTransactionList
```dart
EnhancedTransactionList(
  transactions: transactionList,
  onTransactionTap: (transaction) => showTransactionDetails(transaction),
)
```

### WalletDashboard
```dart
WalletDashboard(
  wallet: userWallet,
  recentTransactions: recentTransactions,
  onAddCredit: () => showAddCreditDialog(),
  onWithdraw: () => showWithdrawDialog(),
  isLoading: isLoadingData,
)
```

## Testing

Run the UI tests with:
```bash
flutter test test/widgets/wallet_ui_test.dart
```

## Design Principles

- Follows Material Design 3 guidelines
- Uses the app's color scheme
- Provides clear visual hierarchy
- Ensures accessibility
- Optimized for performance