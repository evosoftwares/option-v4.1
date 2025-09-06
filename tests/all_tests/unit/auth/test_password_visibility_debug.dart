import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:option/screens/auth/register_screen.dart';

void main() {
  testWidgets('Debug password visibility icons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(),
      ),
    );

    await tester.pumpAndSettle();

    print('=== INITIAL STATE ===');
    print('visibility_outlined icons: ${find.byIcon(Icons.visibility_outlined).evaluate().length}');
    print('visibility_off_outlined icons: ${find.byIcon(Icons.visibility_off_outlined).evaluate().length}');
    print('visibility icons: ${find.byIcon(Icons.visibility).evaluate().length}');
    print('visibility_off icons: ${find.byIcon(Icons.visibility_off).evaluate().length}');
    
    // List all icon widgets
    final allIcons = find.byType(Icon);
    print('Total icons found: ${allIcons.evaluate().length}');
    
    for (var i = 0; i < allIcons.evaluate().length; i++) {
      final icon = tester.widget<Icon>(allIcons.at(i));
      print('Icon $i: ${icon.icon} (${icon.icon?.codePoint.toRadixString(16)})');
      
      // Check common visibility icons
      if (icon.icon == Icons.visibility) print('  -> This is Icons.visibility');
      if (icon.icon == Icons.visibility_off) print('  -> This is Icons.visibility_off');
      if (icon.icon == Icons.visibility_outlined) print('  -> This is Icons.visibility_outlined');
      if (icon.icon == Icons.visibility_off_outlined) print('  -> This is Icons.visibility_off_outlined');
    }

    // Try to find any clickable visibility icons
    final visibilityIcons = find.byIcon(Icons.visibility);
    final visibilityOffIcons = find.byIcon(Icons.visibility_off);
    
    if (visibilityIcons.evaluate().isNotEmpty) {
      print('\n=== CLICKING VISIBILITY ICON ===');
      await tester.tap(visibilityIcons.first);
      await tester.pumpAndSettle();
      
      print('After click:');
      print('visibility icons: ${find.byIcon(Icons.visibility).evaluate().length}');
      print('visibility_off icons: ${find.byIcon(Icons.visibility_off).evaluate().length}');
    } else if (visibilityOffIcons.evaluate().isNotEmpty) {
      print('\n=== CLICKING VISIBILITY_OFF ICON ===');
      await tester.tap(visibilityOffIcons.first);
      await tester.pumpAndSettle();
      
      print('After click:');
      print('visibility icons: ${find.byIcon(Icons.visibility).evaluate().length}');
      print('visibility_off icons: ${find.byIcon(Icons.visibility_off).evaluate().length}');
    } else {
      print('\nNo visibility icons found to click');
    }
  });
}