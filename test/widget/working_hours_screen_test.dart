import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:option/models/supabase/working_hours.dart';

void main() {
  group('WorkingHours Widget Integration Tests', () {
    group('Time Display Formatting', () {
      testWidgets('should format time correctly for display', (tester) async {
        // Test time formatting in a simple widget context
        final workingHours = WorkingHours(
          id: 'test-id',
          driverId: 'driver-id',
          dayOfWeek: 1,
          startTime: '08:30:00',
          endTime: '17:45:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final startTime = workingHours.parseStartTime();
        final endTime = workingHours.parseEndTime();

        // Create a simple widget to test time display
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Start: ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}'),
                  Text('End: ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}'),
                  Text('Day: ${workingHours.dayName}'),
                ],
              ),
            ),
          ),
        );

        // Verify the time is displayed correctly
        expect(find.text('Start: 8:30'), findsOneWidget);
        expect(find.text('End: 17:45'), findsOneWidget);
        expect(find.text('Day: Segunda-feira'), findsOneWidget);
      });

      testWidgets('should handle midnight crossing display', (tester) async {
        final nightShift = WorkingHours(
          id: 'test-id',
          driverId: 'driver-id',
          dayOfWeek: 1,
          startTime: '22:00:00',
          endTime: '06:00:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final startTime = nightShift.parseStartTime();
        final endTime = nightShift.parseEndTime();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Night Start: ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}'),
                  Text('Night End: ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}'),
                  Text('Crosses Midnight: ${startTime.hour > endTime.hour}'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Night Start: 22:00'), findsOneWidget);
        expect(find.text('Night End: 6:00'), findsOneWidget);
        expect(find.text('Crosses Midnight: true'), findsOneWidget);
      });
    });

    group('Day Name Display', () {
      testWidgets('should display correct day names', (tester) async {
         final testCases = [
           (0, 'Domingo'),
           (1, 'Segunda-feira'),
           (2, 'Terça-feira'),
           (3, 'Quarta-feira'),
           (4, 'Quinta-feira'),
           (5, 'Sexta-feira'),
           (6, 'Sábado'),
         ];

        for (final (dayOfWeek, expectedName) in testCases) {
          final workingHours = WorkingHours(
            id: 'test-id',
            driverId: 'driver-id',
            dayOfWeek: dayOfWeek,
            startTime: '09:00:00',
            endTime: '17:00:00',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Text('Day: ${workingHours.dayName}'),
              ),
            ),
          );

          expect(find.text('Day: $expectedName'), findsOneWidget);
        }
      });
    });

    group('Time Range Validation Display', () {
      testWidgets('should display valid time ranges', (tester) async {
        final validHours = WorkingHours(
          id: 'valid-id',
          driverId: 'driver-123',
          dayOfWeek: 1,
          startTime: '08:00:00',
          endTime: '17:00:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final startTime = validHours.parseStartTime();
        final endTime = validHours.parseEndTime();
        final isValidRange = startTime.hour < endTime.hour;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Start: ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}'),
                  Text('End: ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}'),
                  Text('Valid Range: $isValidRange'),
                  Text('Duration: ${endTime.hour - startTime.hour} hours'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Start: 8:00'), findsOneWidget);
        expect(find.text('End: 17:00'), findsOneWidget);
        expect(find.text('Valid Range: true'), findsOneWidget);
        expect(find.text('Duration: 9 hours'), findsOneWidget);
      });

      testWidgets('should handle edge case times in display', (tester) async {
        final edgeCaseHours = WorkingHours(
          id: 'edge-id',
          driverId: 'driver-456',
          dayOfWeek: 6,
          startTime: '23:30:00',
          endTime: '01:30:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final startTime = edgeCaseHours.parseStartTime();
        final endTime = edgeCaseHours.parseEndTime();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Late Start: ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}'),
                  Text('Early End: ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}'),
                  Text('Day: ${edgeCaseHours.dayName}'),
                  Text('Overnight Shift: ${startTime.hour > endTime.hour}'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Late Start: 23:30'), findsOneWidget);
        expect(find.text('Early End: 1:30'), findsOneWidget);
        expect(find.text('Day: Sábado'), findsOneWidget);
        expect(find.text('Overnight Shift: true'), findsOneWidget);
      });
    });

    group('Multiple Working Hours Display', () {
      testWidgets('should display multiple working hours for same day', (tester) async {
        final morningShift = WorkingHours(
          id: 'morning-id',
          driverId: 'driver-789',
          dayOfWeek: 1,
          startTime: '06:00:00',
          endTime: '14:00:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final eveningShift = WorkingHours(
          id: 'evening-id',
          driverId: 'driver-789',
          dayOfWeek: 1,
          startTime: '18:00:00',
          endTime: '22:00:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Morning: ${morningShift.parseStartTime().hour}:00 - ${morningShift.parseEndTime().hour}:00'),
                  Text('Evening: ${eveningShift.parseStartTime().hour}:00 - ${eveningShift.parseEndTime().hour}:00'),
                  Text('Same Day: ${morningShift.dayOfWeek == eveningShift.dayOfWeek}'),
                  Text('Both Active: ${morningShift.isActive && eveningShift.isActive}'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Morning: 6:00 - 14:00'), findsOneWidget);
        expect(find.text('Evening: 18:00 - 22:00'), findsOneWidget);
        expect(find.text('Same Day: true'), findsOneWidget);
        expect(find.text('Both Active: true'), findsOneWidget);
      });

      testWidgets('should handle inactive working hours', (tester) async {
        final inactiveHours = WorkingHours(
          id: 'inactive-id',
          driverId: 'driver-inactive',
          dayOfWeek: 3,
          startTime: '10:00:00',
          endTime: '16:00:00',
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Status: ${inactiveHours.isActive ? "Active" : "Inactive"}'),
                  Text('Day: ${inactiveHours.dayName}'),
                  Text('Time: ${inactiveHours.parseStartTime().hour}:00 - ${inactiveHours.parseEndTime().hour}:00'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Status: Inactive'), findsOneWidget);
        expect(find.text('Day: Quarta-feira'), findsOneWidget);
        expect(find.text('Time: 10:00 - 16:00'), findsOneWidget);
      });
    });
  });
}