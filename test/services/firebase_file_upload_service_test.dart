import 'package:flutter_test/flutter_test.dart';
import 'package:option/services/firebase_file_upload_service.dart';

void main() {
  group('FirebaseFileUploadService', () {
    test('should have correct configuration constants', () {
      // Test configuration constants
      expect(FirebaseFileUploadService.maxFileSizeBytes, equals(50 * 1024 * 1024)); // 50MB
      expect(FirebaseFileUploadService.maxDocumentSizeBytes, equals(50 * 1024 * 1024)); // 50MB
      expect(FirebaseFileUploadService.maxImageWidth, equals(1920));
      expect(FirebaseFileUploadService.maxImageHeight, equals(1920));
      expect(FirebaseFileUploadService.compressionQuality, equals(85));
    });

    test('should have correct allowed MIME types', () {
      // Test allowed MIME types for images
      expect(FirebaseFileUploadService.allowedMimeTypes, contains('image/jpeg'));
      expect(FirebaseFileUploadService.allowedMimeTypes, contains('image/jpg'));
      expect(FirebaseFileUploadService.allowedMimeTypes, contains('image/png'));
      expect(FirebaseFileUploadService.allowedMimeTypes, contains('image/webp'));
      
      // Test allowed MIME types for documents
      expect(FirebaseFileUploadService.allowedDocumentMimeTypes, contains('image/jpeg'));
      expect(FirebaseFileUploadService.allowedDocumentMimeTypes, contains('image/jpg'));
      expect(FirebaseFileUploadService.allowedDocumentMimeTypes, contains('image/png'));
      expect(FirebaseFileUploadService.allowedDocumentMimeTypes, contains('image/webp'));
      expect(FirebaseFileUploadService.allowedDocumentMimeTypes, contains('application/pdf'));
    });

    test('should have FirebaseFileUploadException class', () {
      // Test that the exception class exists and works
      const exception = FirebaseFileUploadException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.toString(), contains('Test error'));
    });

    test('should validate service is properly structured', () {
      // Test that the service class exists and has expected static methods
      expect(FirebaseFileUploadService.uploadImage, isA<Function>());
      expect(FirebaseFileUploadService.uploadDriverDocument, isA<Function>());
      expect(FirebaseFileUploadService.deleteFile, isA<Function>());
    });
  });
}