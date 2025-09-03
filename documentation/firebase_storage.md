# Firebase Storage Documentation

This document provides an overview of the Firebase Storage configuration used in the project and guidelines for developers on how to interact with it.

## Architecture

The project uses a **hybrid approach**:
- **Database, Authentication, Realtime**: Supabase
- **File Storage**: Firebase Storage

## Storage Buckets/Folders

### 1. driver-documents
- **Path Pattern**: `drivers/{driver_id}/documents/{filename}`
- **Purpose**: Store driver document uploads (CNH, CRLV)
- **File Types**: JPG, PNG, PDF
- **Size Limit**: 50MB per file
- **Compression**: Images are automatically compressed to 85% quality and resized to max 1920x1920px

### 2. user-photos  
- **Path Pattern**: `users/{user_id}/profile/{filename}`
- **Purpose**: Store user profile photos
- **File Types**: JPG, PNG, WEBP
- **Size Limit**: 50MB per file
- **Compression**: Images are automatically compressed to 85% quality and resized to max 1920x1920px

## Service Implementation

The Firebase Storage integration is handled by `FirebaseFileUploadService` located at:
`lib/services/firebase_file_upload_service.dart`

### Key Features

1. **Automatic Compression**: Images are automatically compressed and resized
2. **Type Validation**: MIME type validation for security
3. **Size Limits**: Configurable file size limits
4. **Error Handling**: Comprehensive error mapping and user-friendly messages
5. **Metadata**: Automatic timestamp metadata for uploads

### Configuration

```dart
// File size limits
static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB
static const int maxDocumentSizeBytes = 50 * 1024 * 1024; // 50MB

// Allowed file types
static const List<String> allowedMimeTypes = [
  'image/jpeg', 'image/jpg', 'image/png', 'image/webp'
];

static const List<String> allowedDocumentMimeTypes = [
  'image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf'
];

// Image processing
static const int maxImageWidth = 1920;
static const int maxImageHeight = 1920;
static const int compressionQuality = 85;
```

## Usage Examples

### Upload Driver Document

```dart
import '../services/firebase_file_upload_service.dart';

// Upload CNH or CRLV document
Future<String?> uploadDriverDocument(File file, String driverId, String docType) async {
  try {
    final fileName = '${docType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'drivers/$driverId/documents/$fileName';
    
    final downloadUrl = await FirebaseFileUploadService.uploadDriverDocument(
      file: file,
      folder: 'driver-documents',
      path: path,
      compress: true, // Compress images, but not PDFs
    );
    
    return downloadUrl;
  } catch (e) {
    print('Upload failed: $e');
    return null;
  }
}
```

### Upload User Profile Photo

```dart
// Upload profile photo
Future<String?> uploadProfilePhoto(File file, String userId) async {
  try {
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'users/$userId/profile/$fileName';
    
    final downloadUrl = await FirebaseFileUploadService.uploadImage(
      file: file,
      folder: 'user-photos',
      path: path,
      compress: true,
    );
    
    return downloadUrl;
  } catch (e) {
    print('Upload failed: $e');
    return null;
  }
}
```

### Delete File

```dart
// Delete a file
Future<bool> deleteFile(String folder, String path) async {
  return await FirebaseFileUploadService.deleteFile(
    folder: folder,
    path: path,
  );
}
```

### Get File Metadata

```dart
// Get file metadata
Future<Map<String, dynamic>?> getMetadata(String folder, String path) async {
  return await FirebaseFileUploadService.getFileMetadata(
    folder: folder,
    path: path,
  );
}
```

## Error Handling

The service provides comprehensive error mapping with user-friendly messages:

- **File too large**: "Arquivo excede o limite permitido"
- **Invalid format**: "Formato inválido. Utilize JPG, PNG ou PDF"
- **Authentication**: "Sessão expirada. Faça login novamente"
- **Network issues**: "Erro de conexão. Verifique sua internet"
- **Firebase errors**: "Erro no Firebase Storage. Tente novamente"

## Security

### Authentication
- All uploads require valid Supabase authentication
- Session validation and automatic refresh
- User ID verification before upload

### File Validation
- MIME type validation
- File size limits
- Extension validation
- Malicious file detection

### Path Security
- Structured path patterns prevent unauthorized access
- User/driver ID validation in paths
- No direct public access to storage root

## Best Practices

1. **File Naming**: Use timestamps and unique identifiers
2. **Compression**: Enable compression for images to save bandwidth
3. **Error Handling**: Always handle upload failures gracefully
4. **Progress Tracking**: Show upload progress for better UX
5. **Cleanup**: Delete old files when updating profiles/documents
6. **Validation**: Validate files on client-side before upload

## Monitoring

Monitor Firebase Storage usage through:
- Firebase Console Storage tab
- Usage analytics and metrics
- Error logging and tracking
- Cost monitoring for storage and bandwidth

## Migration Notes

If migrating from Supabase Storage to Firebase Storage:
1. Update all storage references in code
2. Migrate existing files to Firebase
3. Update security rules
4. Test all upload/download functionality
5. Update documentation and deployment scripts