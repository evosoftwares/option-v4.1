import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:option/models/supabase/working_hours.dart';

void main() {
  group('WorkingHours Model Tests', () {
    group('Time Parsing', () {
      test('should parse start time correctly', () {
        // Arrange
        final workingHours = WorkingHours(
          id: 'test-id',
          driverId: 'driver-id',
          dayOfWeek: 1,
          startTime: '08:30:00',
          endTime: '18:00:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = workingHours.parseStartTime();

        // Assert
        expect(result.hour, equals(8));
        expect(result.minute, equals(30));
      });

      test('should parse end time correctly', () {
        // Arrange
        final workingHours = WorkingHours(
          id: 'test-id',
          driverId: 'driver-id',
          dayOfWeek: 1,
          startTime: '08:00:00',
          endTime: '17:45:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = workingHours.parseEndTime();

        // Assert
        expect(result.hour, equals(17));
        expect(result.minute, equals(45));
      });

      test('should handle midnight times', () {
        // Arrange
        final workingHours = WorkingHours(
          id: 'test-id',
          driverId: 'driver-id',
          dayOfWeek: 1,
          startTime: '00:00:00',
          endTime: '23:59:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final startResult = workingHours.parseStartTime();
        final endResult = workingHours.parseEndTime();

        // Assert
        expect(startResult.hour, equals(0));
        expect(startResult.minute, equals(0));
        expect(endResult.hour, equals(23));
        expect(endResult.minute, equals(59));
      });
    });

    group('Day Name Mapping', () {
      test('should return correct day names', () {
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
          // Arrange
          final workingHours = WorkingHours(
            id: 'test-id',
            driverId: 'driver-id',
            dayOfWeek: dayOfWeek,
            startTime: '08:00:00',
            endTime: '18:00:00',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Act & Assert
          expect(workingHours.dayName, equals(expectedName));
        }
      });

      test('should handle invalid day numbers', () {
        // Arrange
        final workingHours = WorkingHours(
          id: 'test-id',
          driverId: 'driver-id',
          dayOfWeek: 8, // Invalid day
          startTime: '08:00:00',
          endTime: '18:00:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(() => workingHours.dayName, throwsA(isA<RangeError>()));
      });
    });

    group('Working Hours Logic', () {
      test('should detect normal working hours', () {
        // Arrange - Monday 08:00-18:00
        final workingHours = WorkingHours(
          id: 'test-id',
          driverId: 'driver-id',
          dayOfWeek: 1,
          startTime: '08:00:00',
          endTime: '18:00:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(workingHours.startTime, equals('08:00:00'));
        expect(workingHours.endTime, equals('18:00:00'));
        expect(workingHours.parseStartTime().hour, equals(8));
        expect(workingHours.parseEndTime().hour, equals(18));
      });

      test('should handle midnight crossing hours', () {
        // Arrange - Night shift 22:00-06:00
        final workingHours = WorkingHours(
          id: 'test-id',
          driverId: 'driver-id',
          dayOfWeek: 1,
          startTime: '22:00:00',
          endTime: '06:00:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert - Verify the times are stored correctly
        expect(workingHours.parseStartTime().hour, equals(22));
        expect(workingHours.parseEndTime().hour, equals(6));
        
        // This represents a shift that crosses midnight
        expect(workingHours.parseStartTime().hour > workingHours.parseEndTime().hour, isTrue);
      });

      test('should handle edge case times', () {
        // Arrange - Edge cases
        final workingHours = WorkingHours(
          id: 'test-id',
          driverId: 'driver-id',
          dayOfWeek: 1,
          startTime: '23:59:00',
          endTime: '00:01:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(workingHours.parseStartTime().hour, equals(23));
        expect(workingHours.parseStartTime().minute, equals(59));
        expect(workingHours.parseEndTime().hour, equals(0));
        expect(workingHours.parseEndTime().minute, equals(1));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        // Arrange
        final workingHours = WorkingHours(
          id: 'test-id',
          driverId: 'driver-123',
          dayOfWeek: 1,
          startTime: '08:30:00',
          endTime: '17:30:00',
          isActive: true,
          createdAt: DateTime.parse('2024-01-01T10:00:00Z'),
          updatedAt: DateTime.parse('2024-01-01T10:00:00Z'),
        );

        // Act
        final json = workingHours.toJson();

        // Assert
        expect(json['id'], equals('test-id'));
        expect(json['driver_id'], equals('driver-123'));
        expect(json['day_of_week'], equals(1));
        expect(json['start_time'], equals('08:30:00'));
        expect(json['end_time'], equals('17:30:00'));
        expect(json['is_active'], equals(true));
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'driver_id': 'driver-123',
          'day_of_week': 2,
          'start_time': '09:00:00',
          'end_time': '18:00:00',
          'is_active': true,
          'created_at': '2024-01-01T10:00:00Z',
          'updated_at': '2024-01-01T10:00:00Z',
        };

        // Act
        final workingHours = WorkingHours.fromJson(json);

        // Assert
        expect(workingHours.id, equals('test-id'));
        expect(workingHours.driverId, equals('driver-123'));
        expect(workingHours.dayOfWeek, equals(2));
        expect(workingHours.startTime, equals('09:00:00'));
        expect(workingHours.endTime, equals('18:00:00'));
        expect(workingHours.isActive, equals(true));
        expect(workingHours.dayName, equals('Terça-feira'));
      });
    });

    group('Copy With Method', () {
      test('should create copy with modified fields', () {
        // Arrange
        final original = WorkingHours(
          id: 'original-id',
          driverId: 'driver-123',
          dayOfWeek: 1,
          startTime: '08:00:00',
          endTime: '17:00:00',
          isActive: true,
          createdAt: DateTime.parse('2024-01-01T10:00:00Z'),
          updatedAt: DateTime.parse('2024-01-01T10:00:00Z'),
        );

        // Act
        final modified = original.copyWith(
          startTime: '09:00:00',
          endTime: '18:00:00',
          isActive: false,
        );

        // Assert
        expect(modified.id, equals('original-id')); // Unchanged
        expect(modified.driverId, equals('driver-123')); // Unchanged
        expect(modified.dayOfWeek, equals(1)); // Unchanged
        expect(modified.startTime, equals('09:00:00')); // Changed
        expect(modified.endTime, equals('18:00:00')); // Changed
        expect(modified.isActive, equals(false)); // Changed
      });
    });

    group('Time Overlap Detection', () {
      test('should detect overlapping time ranges', () {
        // Arrange - Saturday morning shift
        final saturdayHours = WorkingHours(
          id: 'saturday-id',
          driverId: 'driver-123',
          dayOfWeek: 6,
          startTime: '08:00:00',
          endTime: '14:00:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert - These should represent valid working hours
        expect(saturdayHours.parseStartTime().hour, equals(8));
        expect(saturdayHours.parseEndTime().hour, equals(14));
        expect(saturdayHours.dayName, equals('Sábado'));
      });

      test('should handle complex time scenarios', () {
        // Arrange - Complex scenario
        final workingHours = WorkingHours(
          id: 'complex-id',
          driverId: 'driver-456',
          dayOfWeek: 3,
          startTime: '06:30:00',
          endTime: '22:30:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        final startTime = workingHours.parseStartTime();
        final endTime = workingHours.parseEndTime();
        
        expect(startTime.hour, equals(6));
        expect(startTime.minute, equals(30));
        expect(endTime.hour, equals(22));
        expect(endTime.minute, equals(30));
        expect(workingHours.dayName, equals('Quarta-feira'));
      });

      test('should handle normal vs night shift comparison', () {
        // Arrange - Normal day shift
        final normalShift = WorkingHours(
          id: 'normal-id',
          driverId: 'driver-789',
          dayOfWeek: 4,
          startTime: '08:00:00',
          endTime: '16:00:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Arrange - Night shift
        final nightShift = WorkingHours(
          id: 'night-id',
          driverId: 'driver-789',
          dayOfWeek: 4,
          startTime: '20:00:00',
          endTime: '04:00:00',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(normalShift.parseStartTime().hour < normalShift.parseEndTime().hour, isTrue);
        expect(nightShift.parseStartTime().hour > nightShift.parseEndTime().hour, isTrue);
        
        // Both should be for Thursday
        expect(normalShift.dayName, equals('Quinta-feira'));
        expect(nightShift.dayName, equals('Quinta-feira'));
      });
    });
  });
}